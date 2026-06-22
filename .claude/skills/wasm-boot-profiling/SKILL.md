---
name: wasm-boot-profiling
description: How to measure where time goes during Rubree's WASM Rails boot sequence
  (Service Worker → ruby.wasm), and what we already learned from one full measurement
  pass — gem require + Rails.application.initialize! + WASM compile dominate (~99%),
  while the ActiveRecord DB adapter (sqlite3_wasm vs nulldb) is negligible (~1.5%).
  Use when investigating "WASM load is slow", "the page freezes on iOS/mobile while
  loading", or when considering swapping the DB adapter to speed up boot — measure
  first, this skill shows how and what was already found.
---

# WASM Boot Profiling

## TL;DR — already-confirmed bottleneck (read this before re-investigating)

```
require application.rb (Bundler.require, all gems)         : 2647 ms  (~30%)
Rails.application.initialize! (eager_load etc.)             : 3045 ms  (~35%) ← largest
vm.initialize (Ruby VM boot + bundle/setup)                 : 1580 ms  (~18%)
WebAssembly.compileStreaming (app.wasm, ~90MB)               : 1417 ms  (~16%)
WebAssembly.instantiate                                     :   65 ms  (~1%)
──────────────────────────────────────────────────────────────────────
initRailsVM total                                           : 8811 ms

initDB + ActiveRecord::Tasks::DatabaseTasks.prepare_all      :  135 ms  (~1.5%)
```

**gem require + Rails initialization + WASM compilation account for ~99% of boot
time. The ActiveRecord DB adapter is ~1.5% and not worth optimizing.** If you're
about to swap `sqlite3_wasm` for `nulldb` (or anything else DB-related) to speed up
boot, read [Why the DB-adapter hypothesis was wrong](#why-the-db-adapter-hypothesis-was-wrong)
first — we already tried that line of reasoning and measured it away.

## When to use this skill

Reach for this skill when:
- A user reports the app freezing or showing unstyled content on iOS/mobile while
  the WASM runtime boots (see `docs/development.md`'s boot sequence diagram for the
  overall flow this skill profiles)
- "WASM load is slow" comes up and you want real numbers instead of guesses
- You're about to change something DB-adapter-related (`config/database.yml`,
  `pwa/rails.sw.js`'s `database: { adapter: ... }` option) on the assumption it will
  speed up boot — measure first, the obvious-looking hypothesis was already wrong once

## Why the DB-adapter hypothesis was wrong

Rubree has no ActiveRecord models (no `db/schema.rb`, `app/models/application_record.rb`
is the only file referencing `ActiveRecord::Base` and it's abstract — all domain logic
is `ActiveModel`-based POROs, see the `architecture-philosophy` skill). It seemed
reasonable that swapping the WASM `sqlite3_wasm` adapter for `nulldb` (which
`wasmify-rails`'s `lib/wasmify/rails/railtie.rb` registers and which `config/database.yml`'s
`wasm` environment already defaults to) would meaningfully speed up boot, since no
tables exist to query.

Measuring it showed `initDB` (SQLite WASM module load) + `ActiveRecord::Tasks::
DatabaseTasks.prepare_all` together cost ~135ms out of an ~8.8s boot — about 1.5%.
The real cost is Rails/Ruby's own startup (gem loading, `eager_load`, WASM
compilation), which is completely independent of which DB adapter is configured.
**Don't repeat this optimization without re-measuring first** — the gem manifest or
`eager_load` setting may have changed since this was last measured.

## How to reproduce the measurement

### 1. Instrument the Service Worker side (`pwa/rails.sw.js`)

```js
const initDB = async (progress) => {
  if (db) return db;
  console.time("[perf] initDB");
  // ...existing body...
  console.timeEnd("[perf] initDB");
  return db;
};

const initVM = async (progress, opts = {}) => {
  // ...
  console.time("[perf] initRailsVM");
  vm = await initRailsVM("./app.wasm", { database: { adapter: "sqlite3_wasm" }, ... });
  console.timeEnd("[perf] initRailsVM");

  console.time("[perf] prepare_all");
  vm.eval("ActiveRecord::Tasks::DatabaseTasks.prepare_all");
  console.timeEnd("[perf] prepare_all");
};
```

### 2. Instrument the Ruby/VM side (`pwa/node_modules/wasmify-rails/src/vm.js`)

This is the npm package's source, not Rubree's own code — see
[Cleanup](#cleanup--this-instrumentation-must-not-ship) for how to revert it.

```js
// inside initRailsVM():
console.time("[perf] WebAssembly.compileStreaming");
module = await WebAssembly.compileStreaming(fetch(url));
console.timeEnd("[perf] WebAssembly.compileStreaming");

console.time("[perf] WebAssembly.instantiate");
const instance = await WebAssembly.instantiate(module, imports);
console.timeEnd("[perf] WebAssembly.instantiate");

console.time("[perf] vm.initialize");
vm.initialize([...]);
console.timeEnd("[perf] vm.initialize");
```

The `bootCode` template literal is a Ruby source string evaluated inside the WASM
VM — instrument it with `Process.clock_gettime`, not `console.time`:

```js
const bootCode = `
  ...
  _t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  require "/rails/config/application.rb"
  _t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  puts "[perf] require application.rb: #{((_t1 - _t0) * 1000).round(1)} ms"

  Rails.application.initialize!
  _t2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  puts "[perf] Rails.application.initialize!: #{((_t2 - _t1) * 1000).round(1)} ms"
  ...
`;
```

`puts` inside the VM is redirected to the Service Worker's `console.log` via the
`outputCallback` wiring already in `initVM`, so these show up alongside the JS-side
`console.time` output.

### 3. Force Vite to pick up the instrumented node_modules code

Vite pre-bundles dependencies into `node_modules/.vite/deps/` at first run and keeps
serving that snapshot even after you edit the source file directly. Editing
`pwa/node_modules/wasmify-rails/src/vm.js` alone does **not** take effect — restart
with a forced re-optimization:

```bash
cd pwa && npm run dev -- --force   # or: yarn dev --force
```

(`rm -rf node_modules/.vite` also works but may be blocked by sandboxing; `--force`
is the supported path.)

### 4. Collect Service Worker console logs via Playwright MCP

The Service Worker runs in its own execution context — the page's main console
(`page.on('console')` / `browser_console_messages`) does **not** see its
`console.log`/`puts` output. Use `browser_run_code_unsafe` with a `serviceworker`
listener instead:

```js
async (page) => {
  const logs = [];
  page.context().on('serviceworker', (sw) => {
    sw.on('console', (msg) => logs.push(msg.text()));
  });

  await page.goto('http://localhost:5173/');
  await page.locator('#launch-button').click();
  await page.getByRole('button', { name: 'Agree and Start / 同意して開始' }).click();
  await page.waitForTimeout(25000);   // boot has a 30s timeout in boot.js

  return JSON.stringify(logs.filter((l) => l.includes('[perf]')), null, 2);
}
```

### 5. Reset to "first load" state before each measurement run

A previous run leaves the Service Worker activated and Cache Storage populated,
which makes the next run measure a warm boot instead of a cold one. Clear both
before navigating:

```js
await page.evaluate(async () => {
  const regs = await navigator.serviceWorker.getRegistrations();
  for (const r of regs) await r.unregister();
  const keys = await caches.keys();
  for (const k of keys) await caches.delete(k);
});
```

## Measurement results (most recent full run)

See [TL;DR](#tldr--already-confirmed-bottleneck-read-this-before-re-investigating)
above. Numbers varied by a few seconds between runs in this dev-container
environment (CPU contention from running two Vite instances at once was one cause)
— treat the relative proportions as more reliable than the absolute milliseconds.
Re-measure on the actual target device (e.g. an iPhone) before drawing conclusions
about real-world boot time; this was measured against desktop Chromium via
Playwright with a pre-built local `app.wasm`.

## Cleanup — this instrumentation must not ship

The `console.time`/`Process.clock_gettime` calls above are diagnostic only — never
merge them. To revert:

```bash
# pwa/rails.sw.js is tracked by git — just restore it
git checkout -- pwa/rails.sw.js

# pwa/node_modules/wasmify-rails is gitignored (npm dependency) — reinstall it
cd pwa
rm -rf node_modules/wasmify-rails
yarn install --check-files
cd ..
```

Also stop any `vite --force` dev server process you started for this profiling
session — it's holding a pre-bundle cache of the now-reverted code and serves no
further purpose.

## Common patterns — what to do and what to avoid

```js
// ✅ measure the full boot sequence end-to-end before optimizing a specific subsystem
console.time("[perf] initRailsVM"); /* ... */ console.timeEnd("[perf] initRailsVM");

// ❌ optimize the DB adapter based on intuition alone — already measured and
//    disproven once; the ~1.5% it accounts for isn't worth the risk of a
//    behavior change
```
