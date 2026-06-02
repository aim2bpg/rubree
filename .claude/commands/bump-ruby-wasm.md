# bump-ruby-wasm

Bump the Ruby patch version used for the WASM build.

## Usage

```
/bump-ruby-wasm <new-version>
```

Example: `/bump-ruby-wasm 4.0.6`

## Steps

1. **Create a branch**
   ```
   git checkout -b chore/bump-ruby-<new-version>
   ```

2. **Update `.ruby-version`**
   Replace the current version with `<new-version>`.

3. **Update `lib/tasks/wasmify_patches.rake`**
   - Line comment `# 1. Source URL override — use latest Ruby patch versions (X.Y.Z)` → update version
   - `sources["4.0"][:src][:url]` → update tarball URL to `https://cache.ruby-lang.org/pub/ruby/4.0/ruby-<new-version>.tar.gz`

4. **Update `docs/wasm-build-notes.md`**
   In Issue 3's Fix description, update the Ruby version reference to `<new-version>`.

5. **Run local WASM build**
   ```
   bin/rails wasmify:build
   ```
   Confirm the build completes without errors.

6. **Run dev server and verify in browser**
   ```
   cd pwa && npm run dev
   ```
   Open the local URL and confirm the app works.

7. **Commit**
   ```
   git add .ruby-version lib/tasks/wasmify_patches.rake docs/wasm-build-notes.md
   git commit -m "⬆️ Ruby <new-version>"
   ```

8. **Push and open PR**
   ```
   git push -u origin chore/bump-ruby-<new-version>
   ```
   Then open a PR against `main`.
