import {
  initRailsVM,
  Progress,
  registerSQLiteWasmInterface,
  RackHandler,
} from "wasmify-rails";

import { setupSQLiteDatabase } from "./database.js";

let db = null;

const initDB = async (progress) => {
  if (db) return db;

  progress?.updateStep("Initializing SQLite database...");
  db = await setupSQLiteDatabase();
  progress?.updateStep("SQLite database created.");

  return db;
};

let vm = null;

const initVM = async (progress, opts = {}) => {
  if (vm) return vm;

  if (!db) {
    await initDB(progress);
  }

  registerSQLiteWasmInterface(self, db);

  let redirectConsole = true;

  vm = await initRailsVM("./app.wasm", {
    database: { adapter: "sqlite3_wasm" },
    progressCallback: (step) => {
      progress?.updateStep(step);
    },
    outputCallback: (output) => {
      if (!redirectConsole) return;
      progress?.notify(output);
    },
    ...opts,
  });

  // Ensure schema is loaded
  progress?.updateStep("Preparing database...");
  vm.eval("ActiveRecord::Tasks::DatabaseTasks.prepare_all");

  redirectConsole = false;

  return vm;
};

const resetVM = () => {
  vm = null;
};

const installApp = async () => {
  const progress = new Progress();

  await progress.attach(self);

  // Initialize DB and VM for the app. Progress steps are handled internally
  // by the Progress instance and currently not broadcast as numeric values.
  await initDB(progress);
  await initVM(progress);
};

// Cache name for wasm artifacts. Bump the suffix to force refreshes when you change
// the wasm build in CI/CD.
const WASM_CACHE = "rubree-wasm-v1";

// Cache for HTML pages (navigation responses)
const HTML_CACHE = "rubree-html-v1";

async function staleWhileRevalidateHTML(request) {
  try {
    const cache = await caches.open(HTML_CACHE);
    const cached = await cache.match(request);

    const networkFetch = fetch(request).then(async (resp) => {
      try {
        const ct = resp.headers.get('content-type') || '';
        if (resp && resp.ok && ct.includes('text/html')) {
          await cache.put(request, resp.clone());
        }
      } catch (e) {
        console.warn('[rails-web] Failed to cache HTML response:', e);
      }
      return resp;
    }).catch((e) => {
      console.warn('[rails-web] html network fetch failed:', e);
      return null;
    });

    if (cached) {
      // Return cached immediately and update in background
      return cached;
    }

    const netResp = await networkFetch;
    if (netResp) return netResp;
    return new Response('Service Unavailable', { status: 503 });
  } catch (e) {
    console.warn('[rails-web] staleWhileRevalidateHTML error:', e);
    return fetch(request).catch(() => new Response('Service Unavailable', { status: 503 }));
  }
}

async function staleWhileRevalidateWasm(request) {
  try {
    const cache = await caches.open(WASM_CACHE);
    const cached = await cache.match(request);

    // Kick off a network refresh in background (don't await when cached)
    const networkFetch = fetch(request).then((resp) => {
      // Only cache successful responses
      if (resp && resp.ok) {
        cache.put(request, resp.clone()).catch((e) => {
          console.warn("[rails-web] Failed to update wasm cache:", e);
        });
      }
      return resp;
    }).catch((e) => {
      console.warn("[rails-web] wasm network fetch failed:", e);
      return null;
    });

    if (cached) {
      // Return cached immediately and let networkFetch update the cache.
      return cached;
    }

    // If no cached version, wait for network and cache result.
    const netResp = await networkFetch;
    if (netResp) return netResp;
    // If network failed and no cache, fall back to a 503-like response
    return new Response("Service Unavailable", { status: 503 });
  } catch (e) {
    console.warn("[rails-web] staleWhileRevalidateWasm error:", e);
    return fetch(request).catch(() => new Response("Service Unavailable", { status: 503 }));
  }
}

// No get-progress handler: clients currently use the seconds-based overlay.

self.addEventListener("activate", (event) => {
  console.log("[rails-web] Activate Service Worker");
});

self.addEventListener("install", (event) => {
  console.log("[rails-web] Install Service Worker");
  // Do not initialize the heavy VM during install. Leave initialization
  // to be triggered by an explicit client action ('start-rails') so the
  // install/activate flow remains fast and non-blocking.
  event.waitUntil((async () => {
    await self.skipWaiting();
  })());
});

const rackHandler = new RackHandler(initVM, { assumeSSL: true });

self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);

  if (url.origin !== location.origin) {
    event.respondWith(fetch(event.request));
    return;
  }

  const bootResources = ["./boot", "./boot.js", "./boot.html", "./rails.sw.js"];

  if (
    bootResources.find((r) => url.pathname.endsWith(r))
  ) {
    console.log(
      "[rails-web] Fetching boot files from network:",
      event.request.url,
    );
    event.respondWith(fetch(event.request));
    return;
  }

  const viteResources = ["node_modules", "@vite"];

  if (viteResources.find((r) => event.request.url.includes(r))) {
    console.log(
      "[rails-web] Fetching Vite files from network:",
      event.request.url,
    );
    event.respondWith(fetch(event.request));
    return;
  }

  // Special-case: handle WASM files with a cache-first / stale-while-revalidate strategy.
  // This makes subsequent starts fast while refreshing the binary in background.
  if (url.pathname.endsWith('.wasm') || event.request.destination === 'wasm' || url.pathname.endsWith('/app.wasm')) {
    console.log('[rails-web] WASM request - using stale-while-revalidate:', event.request.url);
    event.respondWith(staleWhileRevalidateWasm(event.request));
    return;
  }

  // Measure time taken by the RackHandler (this reflects the in-WASM Rails render time)
  event.respondWith((async () => {
    const start = Date.now();
    try {
      const resp = await rackHandler.handle(event.request);
      const dur = Date.now() - start;
      if (dur > 200) {
        console.log(`[rails-web] rackHandler handled ${event.request.url} in ${dur}ms`);
      }
      return resp;
    } catch (e) {
      const dur = Date.now() - start;
      console.error(`[rails-web] rackHandler failed for ${event.request.url} after ${dur}ms`, e);
      throw e;
    }
  })());
});

self.addEventListener("message", async (event) => {
  console.log("[rails-web] Received worker message:", event.data);

  const replyToClient = async (msg) => {
    try {
      // If the sender provided a MessagePort (event.ports[0]), use it for reply.
      if (event.ports && event.ports[0]) {
        try {
          event.ports[0].postMessage(msg);
          return;
        } catch (e) {
          // fall through to other mechanisms
        }
      }

      if (event.source && typeof event.source.postMessage === 'function') {
        event.source.postMessage(msg);
        return;
      }

      const all = await self.clients.matchAll({ includeUncontrolled: true });
      all.forEach((c) => c.postMessage(msg));
    } catch (e) {
      console.warn('[rails-web] replyToClient failed', e);
    }
  };

  if (event.data.type === "reload-rails") {
    const progress = new Progress();
    await progress.attach(self);

    progress.updateStep("Reloading Rails application...");

    resetVM();
    await initVM(progress, { debug: event.data.debug });
    return;
  }

  if (event.data.type === 'start-rails') {
    // Client requested an explicit start; initialize DB/VM now and reply with status.
    try {
      const progress = new Progress();
      await progress.attach(self);
      progress.updateStep('Starting Rails application...');

      // installApp will initDB and initVM
      await installApp();

      await replyToClient({ type: 'rails-started' });
    } catch (e) {
      console.error('[rails-web] start-rails failed', e);
      await replyToClient({ type: 'rails-start-failed', error: String(e) });
    }
    return;
  }
});
