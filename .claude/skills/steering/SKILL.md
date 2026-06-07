---
name: steering
description: Create and follow a .steering/ task plan for work expected to span multiple sessions or requiring a design decision before implementation. Use when starting a feature, a non-trivial refactor, or any task where you'd otherwise lose context between sessions.
allowed-tools: Read, Write, Edit
---

# Steering Skill

For non-trivial tasks, create a `.steering/` directory with a `tasklist.md` that acts as the
single source of progress truth across sessions. Unlike Claude Code's internal task list, this
file persists after the session ends.

## When to use

Create a `.steering/` directory when the task:
- Is expected to span multiple sessions
- Requires a design decision before touching code
- Has enough phases/steps that losing context mid-task would be costly

**Skip it** for single-session tasks: version bumps, config changes, one-file bug fixes. Those
are covered by `/bump-ruby-wasm`, `/bump-rails`, or the standard Task Lifecycle in `CLAUDE.md`.

---

## Mode 1: Create the task plan

### Step 1 — Read relevant code first

Before writing anything, read the code that the task will touch. Form a concrete approach and
surface any constraints (WASM compatibility, static-site deployability, no-services/forms rule).

### Step 2 — Create the steering directory

```
.steering/[YYYYMMDD]-[feature-name]/tasklist.md
```

Use today's date and a short kebab-case feature name. Example:
`.steering/20260607-railroad-diagram-zoom/tasklist.md`

### Step 3 — Fill in the template

Copy `.claude/skills/steering/templates/tasklist.md` and fill in:
- The background / why section
- Concrete phases with actionable tasks
- Sub-tasks where a task is large enough to be ambiguous

Keep tasks small enough that each one can be marked `[x]` independently.

### Step 4 — State the plan and get approval

Show the tasklist.md to the user and get a nod before starting implementation.

---

## Mode 2: Execute

### The core rule

**Every task must reach `[x]` before the session ends.** The only exception is a technical reason
(implementation approach changed, task became unnecessary) — and even then, note the reason inline.

```markdown
- [x] ~~Task name~~ (skipped: approach changed — replaced by X because Y)
```

Reasons that are NOT acceptable: "this is taking too long", "I'll do it later", "this part is
tricky", "I'll add the test afterward". These are the exact shortcuts an AI agent takes
statistically — that is why they are called out explicitly.

### Step-by-step loop

For each task:

1. **Read** the tasklist.md to find the next unchecked task
2. **Mark in-progress** — update `[ ]` to `[~]` (optional, for long tasks) or go straight to `[x]`
3. **Implement**
4. **Mark complete** — update to `[x]` in tasklist.md immediately after completing
5. Repeat

Do not batch-update tasklist.md at the end. Update it after each task.

### Self-check every 5 tasks

- Did I update tasklist.md after the last task?
- Are there any `[ ]` tasks I've actually finished but forgot to mark?

### Before writing the retrospective

Read tasklist.md in full. If any `[ ]` remain:

- **Option A**: Implement them.
- **Option B**: Break them into smaller sub-tasks and implement those.
- **Option C** (technical reason only): Mark them skipped with a reason.

Do not write the retrospective until all tasks are `[x]` or explicitly skipped with a reason.

---

## Mode 3: Retrospective

After all tasks are complete, fill in the retrospective section of tasklist.md:

- What changed from the plan (and why)
- Technical decisions worth remembering
- Anything that should flow into a skill, `docs/`, or a `/command` (per CLAUDE.md §7)

Then ask: does anything surfaced here belong in a skill file or `docs/`? If yes, write it there —
the `.steering/` file is a working document, not permanent knowledge storage.
