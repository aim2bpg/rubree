# CLAUDE.md

This file defines conventions for contributors and AI assistants (Claude Code) working on this repository.

---

## Project Background

Rubree is a browser-based regular expression editor for Ruby developers — a modern, open-source
successor to [Rubular](https://rubular.com). The name is short for "Ruby-based regular expression
editor" (first syllables of each word), deliberately echoing Rubular.

**Why it exists.** Rubular was a long-loved tool, but it had grown hard to keep using:
- It ran on an old Ruby version (2.5.9), which made it slow
- It was closed source, so nobody could fix or extend it
- Every match required a round-trip to a server, adding latency
- It had no way to visualize regex structure or preview substitutions

**Design philosophy: "fully in the browser".** Rubree runs Ruby and Rails entirely client-side via
WebAssembly (`ruby_wasm` + `wasmify-rails`). This removes the server dependency, gives instant
feedback, and lets the whole app be hosted as a static site (GitHub Pages). Features that grew out
of this philosophy:
- Railroad diagrams that visualize regex structure (`regexp_parser` + `railroad_diagrams`) —
  the Ruby gem, not a JavaScript library; JS-based alternatives like regexper were evaluated and
  rejected because all diagram logic must compile to WASM and run client-side
- Ruby code snippet generation for the pattern under test
- Shareable permalinks that encode the full editor state in the URL
- ReDoS checks via an embedded recheck Playground

**For more background**, see the launch article:
- はてなブログ: https://aim2bpg.hatenablog.com/entry/2025/11/25/083000

When proposing changes, keep this philosophy in mind: favor solutions that work fully client-side,
keep the app deployable as a static site, and avoid reintroducing a server dependency.

---

## Architecture

Domain logic belongs in `app/models` as ActiveModel-based POROs — no `app/services/` or
`app/forms/`. Read the `architecture-philosophy` skill before adding domain logic, naming classes,
or reaching for a service object; it explains the reasoning so the direction holds going forward.

---

## Task Lifecycle

Every non-trivial task follows this arc. Skipping a phase rarely saves time — it usually shifts
the cost to a later phase where it's harder to fix.

### 1. Plan before writing code

Before touching any file, read the relevant code, map out the approach, and surface unknowns.
Use plan mode for tasks that span multiple files, touch the WASM build, or require a design
decision.

If the task is ambiguous — missing context, conflicting constraints, a genuine choice between
approaches — ask before starting. One clarifying question up front costs far less than building
in the wrong direction and walking it back.

Before starting, confirm:
- What is the scope? (What's in, what's out)
- Is there a hard constraint — WASM compatibility, static-site deployability, the no-services/forms
  rule — that will shape the approach?
- Is a branch + PR needed, or is a direct push to `main` appropriate?
- For tasks expected to span multiple sessions or requiring a design decision up front, create
  `.steering/[YYYYMMDD]-[feature]/tasklist.md` before touching any code — it preserves progress
  across sessions. See the `steering` skill for the format and template.

### 2. State the approach and wait for approval

Briefly describe the plan and get a nod before implementing. If the plan turns out to be wrong
mid-work — a surprising constraint, a misread of the codebase — stop, say so, and re-plan. Don't
silently adapt; the user can't review a decision they didn't know was made.

### 3. Work incrementally

Make one coherent change at a time. After each meaningful step — a passing test, a working
partial — check that things still hold before moving to the next step. This makes regressions easy
to catch and the change easy to explain.

**Pause and ask when genuinely uncertain**: an ambiguous requirement, a surprising finding in the
code, a decision with tradeoffs that belongs to the user. A wrong guess compounds; a quick
question resolves.

### 4. Finish it

When a task turns out harder, slower, or more tedious than expected, finish it — don't quietly
trim scope or push part of it to "later." Reasons like "this is taking too long," "this part is
tricky," or "I'll add the test afterward" are not good reasons to stop partway — they're exactly
the kind of shortcut an AI agent is statistically inclined to take, because the shortcut *looks*
like progress.

The only acceptable reason to skip part of a task is a **technical** one — the plan changed, the
direction changed, or that part turned out to be unnecessary. When that happens, say so plainly
and explain why, rather than letting it quietly disappear from the result.

If a task is too large to finish in one pass, split it into smaller pieces and finish each one —
don't leave any of them half-done. Silently-incomplete work looks identical to complete work
until someone hits the gap later, and by then the reasoning behind it is gone.

### 5. Verify before declaring done

Before reporting a task as complete:

- **Linters**: `bin/rubocop`, `bin/erb_lint --lint-all`, `bin/yarn biome check` (if code changed)
- **Tests**: `bin/rspec`
- **UI changes**: confirm in the browser (Rails dev server or WASM build — see `docs/development.md`)
- **WASM-touching changes**: `/verify-wasm` or run `bin/rails wasmify:build && bin/rails wasmify:pack` and verify in Chrome

### 6. Review your own diff

Read the full diff before declaring done. Look for:
- Unintended changes (files touched that shouldn't be)
- Missing test coverage for new code paths
- Anything that would surprise a future reader without a comment

For PR work, use `/create-pr` or fill in the PR template (`.github/pull_request_template.md`)
and note what manual verification you did.

### 7. Capture what you learned

After completing a non-trivial task — a bug fix, a feature, a version upgrade, an investigation
— briefly ask:

- Did we surface tacit knowledge that belongs in a skill or `docs/`?
- Did we make a design decision that future-me should know about before touching that area?
- Is there a multi-step procedure we just followed that would benefit from a `/command`?
- **Token efficiency**: Was context consumption proportionate to the task? Could a subagent
  have handled a large chunk (e.g. a long build, a broad search) to keep the main context
  lean? Note what worked and what would be worth doing differently next time.

If yes to any of these, say so explicitly rather than letting it disappear into the conversation.
The cost of writing it down while the context is fresh is low; the cost of rediscovering it later
is high.

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
| GitHub CLI | `gh` installed; prefer over `WebFetch` for GitHub ops — see `docs/development.md#github-cli` |

---

## Conventions

### Language

| Target | Language |
|---|---|
| Source code, comments | English |
| Commit messages | English |
| PR titles & descriptions | English |
| CLAUDE.md, `.claude/` files | English |

### Commit messages

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

### Branch strategy

**Direct push to `main`** is acceptable for single-file config or docs changes with low risk.

**Create a branch + PR** for code changes, version upgrades, CI/workflow changes, or anything
that touches the WASM build.

Branch naming: `chore/bump-ruby-4.0.5` · `fix/some-bug` · `feat/some-feature`

**Merging:** regular PRs use a merge commit. Dependabot PRs auto-merge with squash via
`.github/workflows/auto-merge.yml`.

### Pull request guidelines

- Keep each PR focused on one concern
- Self-review your diff before opening; leave a comment on anything that needs explaining
- Fill out the PR template (`.github/pull_request_template.md`) — What/Why/How structure
- Note any manual verification (e.g. "ran `wasmify:build` and checked the app in Chrome")

When leaving review comments (including `/code-review --comment`), mark severity and call out
good things alongside issues:

| Label | Meaning |
|---|---|
| `[must]` | Has to be addressed before merging |
| `[should]` | Worth fixing, but not a blocker |
| `[consider]` | An idea worth thinking about — up to the author |
| `[question]` | Asking to understand, not asking for a change |

---

## UI Design Decisions

These decisions were made during the 2025/10 design review and are reflected in the current code.
Don't change them without understanding the rationale:

- **SVG railroad diagram zoom**: modal display (the diagram image itself is the modal trigger). A
  new-tab / data-URI approach was evaluated and rejected — the modal is sufficient for full-view
  and matches the user expectation of clicking an image to enlarge it.
- **Terms of service**: shown on first launch only. The START button opens a ToS modal; the user
  must agree before the WASM runtime boots. A simple AI-generated ToS — not a full legal document
  — is enough to provide a baseline of protection.
- **Initial launch screen**: replaced the original "Launch" button with a user-friendly boot
  screen that notes it only appears on first visit. The bare "Launch" button looked suspicious
  and caused early exit before the app had loaded.

---

## AI Tooling Reference

### Project skills (auto-loaded when relevant)

| Skill | When it loads | Covers |
|---|---|---|
| `architecture-philosophy` | Adding domain logic, naming classes, reviewing a diff | ActiveModel PORO pattern, class naming, module vs class; for frontend, see `frontend-patterns` |
| `frontend-patterns` | Writing/reviewing Stimulus controllers, Alpine.js, ERB, Turbo Frames | Alpine.js vs Stimulus, Turbo Frame flow, ERB whitespace, SVG safety, browser-only constraint |
| `testing-guidelines` | Writing/reviewing specs, choosing spec layer, coverage failures | Spec layout, description style, mocking, Capybara driver selection, octocov thresholds |
| `ci-cd-pipeline` | Changing CI/CD, devcontainer, WASM build, deploy pipeline | Dotfile-driven versioning, WASM cache keys, Dependabot, Lefthook, CSP status, sitemap |
| `steering` | Starting a multi-session task, needing a design decision up front | Creates `.steering/[date]-[feature]/tasklist.md` to preserve progress across sessions |

### Project commands

| Command | Description |
|---|---|
| `/bump-ruby-wasm <version>` | Ruby patch version upgrade — dotfiles, rake patch, WASM rebuild, cache key behavior |
| `/bump-rails <version>` | Rails version upgrade — bundle update, railsdiff review, WASM verification |
| `/create-pr` | Draft and open a PR via `gh pr create` using the project PR template |
| `/verify-wasm` | Build WASM artefacts and verify the golden path headlessly via Playwright MCP |

### Built-in skills (always available)

| Command | Description |
|---|---|
| `/code-review [--comment] [--fix]` | Review current diff for bugs and cleanups. `--comment` posts inline PR comments; `--fix` applies findings |
| `/security-review` | Security-focused review of pending changes on the current branch |
| `/simplify` | Refactoring pass — reuse, simplification, efficiency (no bug hunting; use `/code-review` for that) |
| `/loop [interval]` | Run a command repeatedly on an interval — e.g. `/loop 5m /code-review` |
| `/schedule` | Create/manage scheduled remote agents on a cron schedule |

### Sub-agents (spawned via the Agent tool)

Claude Code can delegate work to specialised sub-agents. These are not slash commands — they are
invoked internally by the assistant when the task fits. You cannot call them directly, but you can
ask the assistant to use one explicitly (e.g. "use an Explore agent for this search").

| Agent type | When it's used | What it does |
|---|---|---|
| `Explore` | Codebase search — finding files, symbols, cross-references | Fast read-only search; use for "where is X defined?" or "which files reference Y?" — does NOT do analysis or full-file review |
| `Plan` | Designing implementation strategies, architectural decisions | Returns a step-by-step plan, identifies critical files, surfaces trade-offs — use before touching code that spans multiple files |
| `general-purpose` | Multi-step research, complex investigations | Broad research, web fetches, multi-file analysis — keeps large result sets out of the main context window |

**When sub-agents are NOT used:** simple file reads, targeted greps, single-file edits — these are
done inline. Sub-agents add cold-start cost; they are worth it only when the task is genuinely
open-ended or parallelisable.

### MCP servers

| Server | Purpose | Config |
|---|---|---|
| Playwright | Headless browser — `localhost` verification, WASM golden-path testing | `settings.json` → `mcpServers.playwright` |
