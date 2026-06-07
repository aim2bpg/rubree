---
name: ci-cd-pipeline
description: How Rubree's local setup (.devcontainer/setup.sh), CI (ci.yml), and Deploy (deploy.yml) connect — dotfile-driven tool versions, WASM build caching, Dependabot grouping/auto-merge, Lefthook hook scope, and the Chrome/Edge-only browser support constraint. Use when changing CI/CD workflows, the devcontainer, dependency automation, or anything that touches the WASM build or deploy pipeline.
---

# CI/CD Pipeline

The "how this project runs" knowledge already lives in a few well-maintained files. Rather than
duplicating it (and risking drift), here is a map of where to look and how the pieces connect.

## 1. Local environment setup — `.devcontainer/setup.sh`

Installs Ruby (rbenv), Node.js (nvm), Rust + wasi-vfs, Playwright browsers, Chrome, and
Gitleaks. Every tool version comes from a dotfile (`.ruby-version`, `.node-version`,
`.rust-version`, `.wasi-vfs-version`) — bump the dotfile and setup.sh picks it up automatically.
Claude Code itself is opt-in via a `.install-claude-code` marker file (gitignored).

## 2. CI — `.github/workflows/ci.yml`

Runs on PR / push to `main`, skipped for doc-only changes (`paths-ignore: ['**/*.md']`). Jobs:

- **Lint**: Rubocop, ERB Lint (Ruby), Biome (frontend)
- **Security**: Gitleaks (secret scan), Brakeman (SAST)
- **Test**: full RSpec suite with coverage reporting via octocov (see the `testing-guidelines`
  skill for the thresholds it enforces)

All jobs read the same `.ruby-version` / `.node-version` dotfiles as `setup.sh`, so local and CI
environments stay in sync.

## 3. Deploy — `.github/workflows/deploy.yml`

Triggered after CI succeeds on `main`. Builds `ruby.wasm` (`wasmify:build` / `wasmify:pack`),
builds the PWA frontend, and publishes the static site to GitHub Pages.

The WASM build is cached, keyed on a hash of **both** `.ruby-version` **and** `Gemfile.lock` —
see the inline comment in `deploy.yml` for why both are required (also explained in
`docs/wasm-build-notes.md`): the cached `rubies/*.tar.gz` filename embeds an MD5 hash of
native-extension gem versions, so a `Gemfile.lock` change can invalidate the cache even when
`.ruby-version` doesn't change.

**Takeaway**: when bumping a tool version (Ruby, Node, Rust, wasi-vfs), update the relevant
dotfile — setup.sh, ci.yml, and deploy.yml all key off it, so one edit propagates everywhere.
`/bump-ruby-wasm` and `/bump-rails` already encode the right file list for those upgrades.

## Common patterns — what to do and what to avoid

```yaml
# ✅ bump a tool version by editing the dotfile — setup.sh, ci.yml, and deploy.yml all read it
$ echo "4.0.6" > .ruby-version   # one edit propagates everywhere

# ❌ hardcode the version inside ci.yml — setup.sh and deploy.yml won't see the change,
#    and local/CI environments fall out of sync
- uses: ruby/setup-ruby@v1
  with:
    ruby-version: "4.0.6"   # now diverged from .ruby-version
```

```yaml
# ✅ WASM cache key hashes both .ruby-version AND Gemfile.lock (deploy.yml)
key: ruby-wasm-${{ hashFiles('.ruby-version', 'Gemfile.lock') }}

# ❌ hash only .ruby-version — a Gemfile.lock change (new native-extension gem) won't
#    bust the cache, and the stale rubies/*.tar.gz will be used silently
key: ruby-wasm-${{ hashFiles('.ruby-version') }}
```

```yaml
# ✅ docs-only commit — ci.yml path filter skips the full run, saving ~5 min
#    (only works if the commit contains no code changes alongside the .md edits)

# ❌ mix a code change into a docs commit — the path filter won't match,
#    CI runs anyway, and the intent of the commit is unclear
```

## Automation notes

- **Dependency updates**: Dependabot runs daily (`.github/dependabot.yml`) and groups related
  packages (e.g. `rails`, `rubocop`, `tailwindcss`) into single PRs to cut down on noise.
  Non-major-version bumps auto-merge with squash via `.github/workflows/auto-merge.yml`.
- **CI path filters**: `ci.yml` skips runs when only `**/*.md` files change — a docs-only commit
  shouldn't also touch code, or it will trigger a full CI run unnecessarily.
- **Git hooks (Lefthook)**: `pre-commit` runs the linters (Rubocop, ERB Lint, Biome), Gitleaks,
  Brakeman, and the RSpec suite; `pre-push` runs system specs against Firefox, WebKit, and
  Selenium/Chrome. A failing hook usually means CI would fail too — fix the underlying issue
  rather than skipping hooks.
- **Browser support**: Rubree only supports Chrome and Edge. Ruby Wasm is incompatible with
  Safari's WebAssembly asyncify and with Firefox's stricter Service Worker module evaluation (see
  README → Browser Compatibility for the exact errors). Don't expect WASM-related changes to
  work in Safari or Firefox.
- **Content Security Policy is intentionally disabled**: `config/initializers/content_security_policy.rb`
  is fully commented out. A standard CSP would break the app: WebAssembly execution requires
  `wasm-unsafe-eval`, and Importmap requires inline scripts. Configuring a working CSP for this
  WASM + PWA setup is a known open problem — do not uncomment and apply the Rails default without
  first resolving those constraints.
- **`sitemap.xml` lastmod is git-driven**: `script/prepare_static_files.sh` (run during Deploy)
  checks whether the current HEAD commit touches any of `pwa/`, `app/`, `public/`, or
  `config/locales/`. If it does not (e.g. a Dependabot-only bump), the existing
  `public/sitemap.xml` is reused unchanged so `lastmod` is not bumped by unrelated commits. If
  content changed, `lastmod` is set to the date of the most recent git commit that touched those
  paths — not today's date. This means the sitemap accurately reflects when the site content last
  changed, not when the last deploy ran.
