# verify-wasm

Build the WASM artefacts and verify the app works end-to-end in a headless browser via
Playwright MCP. Use after any change that could affect the WASM runtime (gem updates,
Rails version bumps, config changes, new features).

## Usage

```
/verify-wasm
```

## Steps

### 1. Build WASM artefacts

```bash
bin/rails wasmify:build   # ~1 min with cache, ~15 min cold
bin/rails wasmify:pack
```

**Clean build** (use when explicitly asked, or when cache may be stale):

```bash
rm -rf tmp/wasmify/ pwa/public/app.wasm
bin/rails wasmify:build
bin/rails wasmify:pack
```

If either command fails, check `docs/wasm-build-notes.md` for known issues before investigating.

### 2. Start the PWA dev server

```bash
(cd pwa && npm run dev) &
PWA_PID=$!
```

Wait ~3 seconds for Vite to finish starting. The server runs on **http://localhost:5173** and
sets the required COOP/COEP headers automatically.

### 3. Verify via Playwright MCP

Use the Playwright MCP tool to perform the following in order:

**Boot:**
1. Navigate to `http://localhost:5173`
2. Wait for the "Start" button to appear
3. Click "Start"
4. Click "Agree" on the Terms of Service modal
5. Wait for the boot progress bar to disappear (up to 30 s)
6. Confirm the main editor is visible

**Golden path:**
7. Enter the regex pattern `(hello|world)` in the pattern field
8. Enter the test string `hello world foo` in the test string field
9. Confirm that `hello` and `world` are highlighted as matches
10. Confirm the railroad diagram SVG renders (no error message)
11. Enter `$1!` in the substitution field — confirm the substitution result shows `hello! world! foo`
12. Confirm the Ruby code snippet area shows non-empty content
13. Click the permalink button — confirm a URL is copied / the URL bar updates

**Cleanup:**
14. Kill the dev server: `kill $PWA_PID`

### 4. Report results

Summarize which steps passed and which (if any) failed. If any step failed:
- Note the exact step, what was expected, and what was observed
- Check the browser console (via Playwright MCP) for errors
- If it's a WASM runtime error, check `docs/wasm-build-notes.md`

**Visual reference** — `docs/screenshots/guide/` contains annotated screenshots organised by
feature (boot, match, diagram, substitution, etc.). Use them to confirm the UI looks right,
especially after layout or copy changes. Run `/screenshot-guide` to regenerate them.

## Notes

- The Playwright MCP must be connected (`enableAllProjectMcpServers: true` in `settings.json`).
  If it isn't available, run `claude --mcp-trust-all` to start the session.
- localStorage is fresh each headless session — the ToS modal always appears (step 3–4 above).
- The PWA dev server serves from `/` locally; the GitHub Pages deployment serves from `/rubree/`.
  This is controlled by `GITHUB_ACTIONS` env var in `pwa/vite.config.js` and is expected.
- This command does **not** run `bin/rspec` — that tests the Rails dev server, not the WASM build.
  Both are needed for full verification.
