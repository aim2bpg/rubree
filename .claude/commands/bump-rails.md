# bump-rails

Guided steps for upgrading the Rails version used by Rubree.

Based on the general Rails upgrade approach described by Junichi Ito
(https://qiita.com/jnchito/items/0ee47108972a0e302caf), adapted for this app's
WASM build (`wasmify-rails`) and static-site deployment.

## Usage

```
/bump-rails <new-version>
```

Example: `/bump-rails 8.1.4`

## Steps

1. **Read the official upgrade guide** for the target version (Rails Guides, plus
   the upgrade-related sections of the release notes/CHANGELOG). Note anything
   that could affect this app — Hotwire, asset pipeline, or WASM-relevant changes.

2. **Confirm the baseline is green** before changing anything:
   ```bash
   RUBYOPT=-W:deprecated bin/rspec
   ```
   Fix failing tests or deprecation warnings first — otherwise it's hard to tell
   which issues are pre-existing and which were introduced by the upgrade.

3. **Create a branch**
   ```bash
   git checkout -b chore/bump-rails-<new-version>
   ```

4. **Update the Rails version pin** in `Gemfile`
   (`gem "rails", "~> <new-version>", group: [:default, :wasm]`), then run
   `bundle update rails`.
   - Go one minor/patch step at a time — don't skip versions when jumping
     more than a patch release.

5. **Compare against [railsdiff.org](https://railsdiff.org)** for the old → new
   version range, and apply any relevant config/initializer changes by hand.
   (Running `rails app:update` is riskier here than in a typical app, since the
   Gemfile has a WASM-specific `group: [:default, :wasm]` setup that a generator
   doesn't know about — prefer the manual diff review.)

6. **Re-run linters and the full test suite**
   ```bash
   bin/rubocop
   bin/erb_lint --lint-all
   RUBYOPT=-W:deprecated bin/rspec
   ```

7. **Rebuild and verify the WASM bundle.** A Rails upgrade can break the WASM
   build even when the test suite is green:
   ```bash
   bin/rails wasmify:build   # must succeed without errors
   bin/rails wasmify:pack    # must succeed without errors
   cd pwa && npm run dev     # open in Chrome and confirm the app works
   ```
   If the build breaks, check `docs/wasm-build-notes.md` for a known issue first;
   if it's new, add an entry there describing the symptom, cause, and fix.

8. **Commit**
   ```bash
   git add Gemfile Gemfile.lock <any other changed files>
   git commit -m "⬆️ Rails <new-version>"
   ```

9. **Push and open a PR** against `main`. In the description, link the release
   notes and call out anything reviewers should look at closely — deprecations,
   config/initializer changes, and WASM build impact.

10. **After merging**, watch the Deploy workflow and the live GitHub Pages site
    for a few days. WASM-related regressions sometimes only surface in the
    deployed static build, not in local dev or CI.

## Notes

- Rails is pinned with `~>` in the Gemfile
  (`gem "rails", "~> 8.1.3", group: [:default, :wasm]`) — keep that pattern
  unless there's a specific reason to change it.
- Any Rails version bump touches the WASM build path (`group: [:default, :wasm]`),
  so it always needs a branch + PR per the Branch Strategy in `CLAUDE.md`.
- For **Ruby** version bumps (a separate concern from the Rails framework
  version), use `/bump-ruby-wasm` instead.
