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

3. **Update `.wasi-vfs-version` (only if needed)**
   Check https://github.com/kateinoigakukun/wasi-vfs/releases for a newer release; update if so.

4. **Update `.rust-version` (only if needed)**
   If `.wasi-vfs-version` changed, check whether wasi-vfs's `rust-toolchain.toml` now requires a
   different Rust version, and update `.rust-version` to match.

5. **Update `lib/tasks/wasmify_patches.rake`**
   - Line comment `# 1. Source URL override — use latest Ruby patch versions (X.Y.Z)` → update version
   - `sources["4.0"][:src][:url]` → update tarball URL to `https://cache.ruby-lang.org/pub/ruby/4.0/ruby-<new-version>.tar.gz`

6. **Update `docs/wasm-build-notes.md`**
   In Issue 3's Fix description, update the Ruby version reference to `<new-version>`.

7. **Run and verify the local WASM build**
   ```
   bin/rails wasmify:build   # must succeed without errors
   bin/rails wasmify:pack    # must succeed without errors
   cd pwa && npm run dev     # open the local URL and confirm the app works in the browser
   ```

8. **Commit**
   ```
   git add .ruby-version .wasi-vfs-version .rust-version lib/tasks/wasmify_patches.rake docs/wasm-build-notes.md
   git commit -m "⬆️ Ruby <new-version>"
   ```
   (Only `git add` the dotfiles you actually changed.)

9. **Push and open PR**
   ```
   git push -u origin chore/bump-ruby-<new-version>
   ```
   Then open a PR against `main`.

## Notes

- **CI/Deploy cache keys** in `.github/workflows/deploy.yml` are keyed on a hash of **both**
  `.ruby-version` and `Gemfile.lock` — a Ruby version bump always invalidates the cache, so the
  next Deploy run will do a full WASM rebuild. No manual cache action is needed.
- For **Rails framework** version bumps (a separate concern from the Ruby runtime version), use
  `/bump-rails` instead.
