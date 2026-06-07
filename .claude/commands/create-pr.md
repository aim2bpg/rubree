# create-pr

Create a pull request for the current branch using `gh pr create`, following Rubree's PR template.

## Usage

```
/create-pr
```

## Steps

1. **Verify branch and gh auth**
   ```bash
   git branch --show-current   # must not be main
   gh auth status              # must be authenticated
   ```
   If `gh` is not authenticated, see `docs/development.md#github-cli`.

2. **Gather change context**
   ```bash
   git log main..HEAD --oneline
   git diff main..HEAD --stat
   ```
   Read the diff of any non-obvious changed files to understand the full scope.

3. **Check for open `.steering/` plan**
   If a `.steering/` directory exists for this task, read its `tasklist.md` retrospective section
   — it may contain the "What/Why/How" content needed for the PR body.

4. **Draft PR title and body**

   Title: follow commit message conventions from `CLAUDE.md`:
   - `feat: <description>` / `fix: <description>` / `chore: <description>` / `docs: <description>`
   - Keep under 70 characters

   Body: fill in the PR template (`.github/pull_request_template.md`):
   - **Overview (What)**: what changed
   - **Background (Why)**: why it was needed
   - **Details (How)**: key implementation decisions
   - **Verification**: how it was tested (linters, rspec, WASM build, browser check)
   - **Additional Notes**: related issues, follow-ups

5. **Create the PR**
   ```bash
   gh pr create \
     --base main \
     --title "<title>" \
     --body "$(cat <<'EOF'
   <body>
   EOF
   )"
   ```

6. **Confirm and share the URL**
   The `gh pr create` output includes the PR URL — share it with the user.

## Notes

- `gh pr create` is in the `ask` list in `settings.json` — confirm the permission prompt before proceeding.
- For Dependabot PRs, skip this command — they are auto-created and auto-merged per the Branch Strategy.
- If `gh` auth is blocked, fallback: run `gh pr create` manually with the `! gh pr create` prefix in the Claude Code prompt to execute it yourself.
