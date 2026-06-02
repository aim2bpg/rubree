# CLAUDE.md

This file defines conventions for contributors and AI assistants (Claude Code) working on this repository.

---

## Technical Foundation

| Item | Detail |
|---|---|
| Runtime | Ruby 4.x (see `.ruby-version`) |
| Framework | Ruby on Rails 8.x |
| WASM | ruby_wasm + wasmify-rails (PWA target) |
| Frontend | Vite + Stimulus + Turbo |
| CI/CD | GitHub Actions |
| Dev Environment | DevContainer (`.devcontainer/devcontainer.json`) |

---

## Language Rules

| Target | Language |
|---|---|
| Source code, comments | English |
| Commit messages | English |
| PR titles & descriptions | English |
| CLAUDE.md, `.claude/` files | English |

---

## Commit Message Conventions

| Format | Use case |
|---|---|
| `⬆️ Ruby X.Y.Z` | Ruby patch version bump |
| `⬆️ Node.js X.Y.Z` | Node.js version bump |
| `⬆️ bundle update` | Bulk gem updates |
| `⬆️ yarn upgrade` | Bulk JS package updates |
| `chore: <description>` | Config, CI, tooling (non-functional) |
| `fix: <description>` | Bug fixes |
| `feat: <description>` | New features |
| `docs: <description>` | Documentation only |
| `Chore(deps): Bump X from A to B` | Dependabot single-dependency bumps (capital C) |

---

## Branch Strategy

**Direct push to `main`** is acceptable for:
- Single-file config or docs changes with low risk

**Create a branch + PR** for:
- Code changes, version upgrades, CI/workflow changes, or anything that touches WASM build

Branch naming:
```
chore/bump-ruby-4.0.5
fix/some-bug-description
feat/some-new-feature
```

---

## WASM Build — Ruby Version Upgrade

Use `/bump-ruby-wasm <version>` for guided steps.

**Files to update:**

1. `.ruby-version`
2. `.wasi-vfs-version` — update if wasi-vfs has a new release
3. `.rust-version` — update if wasi-vfs `rust-toolchain.toml` changed
4. `lib/tasks/wasmify_patches.rake` — tarball URL + comment version
5. `docs/wasm-build-notes.md` — version reference in Issue 3 Fix line

**Verify before pushing:**
```bash
bin/rails wasmify:build   # must succeed without errors
bin/rails wasmify:pack    # must succeed without errors
cd pwa && npm run dev     # open browser and confirm the app works
```

**Cache keys** in `.github/workflows/deploy.yml` auto-invalidate on `.ruby-version` changes.

---

## Custom Commands

| Command | Description |
|---|---|
| `/bump-ruby-wasm <version>` | Step-by-step guide for Ruby patch version upgrade + WASM verification |
