# [Feature name]

## Background

{Why this task exists — what problem it solves or what change triggered it.}

## Approach

{Brief description of the chosen approach and any key constraints
(WASM compatibility, static-site deployability, no-services/forms rule, etc.).
One paragraph is enough — capture the decision, not a full design doc.}

---

## 🚨 Completion rule

All tasks must reach `[x]` before this task is considered done.
Acceptable skip reason: technical only (approach changed, task became unnecessary).
Not acceptable: "takes too long", "tricky", "will do later".

Skipping format:
```
- [x] ~~Task name~~ (skipped: <specific technical reason>)
```

---

## Phase 1: {Phase name}

- [ ] {Task}
  - [ ] {Sub-task}
  - [ ] {Sub-task}
- [ ] {Task}

## Phase 2: {Phase name}

- [ ] {Task}
- [ ] {Task}

## Phase N: Verify

- [ ] Linters pass
  - [ ] `bin/rubocop`
  - [ ] `bin/erb_lint --lint-all`
  - [ ] `bin/yarn biome check`
- [ ] Tests pass: `bin/rspec`
- [ ] (If WASM-touching) `bin/rails wasmify:build && bin/rails wasmify:pack`, verify in Chrome
- [ ] Self-review diff — no unintended changes, no missing test coverage

---

## Retrospective

### Completed

{YYYY-MM-DD}

### What changed from the plan

- {Task or approach that was different from the original plan, and why}

### Decisions worth remembering

- {Technical decision that a future reader should know about before touching this area}

### Knowledge to carry forward

- {Anything that belongs in a skill, `docs/`, or a `/command` — per CLAUDE.md §7}
