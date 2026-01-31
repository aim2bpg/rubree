# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby (RuboCop)", "bin/rubocop"
  step "Style: Ruby (ERB Lint)", "bin/erb_lint --lint-all"
  step "Style: JavaScript (Biome)", "yarn run lint"

  step "Security: Gitleaks", "gitleaks detect --source=\"$(pwd)\" --verbose --redact --log-opts=\"--all --full-history\""
  step "Security: Brakeman code analysis", "bin/brakeman --no-pager --skip-files app/assets/builds/,build/,node_modules/,pwa/,rubies/"

  step "Test: RSpec", "bin/rspec"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
