---

name: testing-guidelines
description: Conventions for writing, organizing, and running RSpec tests in Rubree — spec layout, description style, mocking, system-spec driver selection, and the octocov coverage/ratio/time thresholds enforced on every PR. Use when writing or reviewing specs, deciding which spec layer (model/request/system) to use, or wondering why a PR's coverage check failed.
---

# Testing Guidelines

Tests live in `spec/`, organized by layer: `models/`, `requests/`, `controllers/`, `system/`,
with shared setup in `support/`. Pick the layer that matches what you're testing — most logic
belongs in model specs (fast, isolated); use request/system specs for things that only show up
when Rails or the browser is involved.

## Write descriptions as plain English sentences

```ruby
# ✅ from spec/models/regular_expression/example_spec.rb
RSpec.describe RegularExpression::Example do
  describe '.categories' do
    it 'returns a hash of categories with examples' do
      cats = described_class.categories
      expect(cats).to be_a(Hash)
      expect(cats).not_to be_empty
    end
  end
end

# ❌ avoid cryptic or implementation-shaped names
it 'categories_test_1' do
it 'works' do
```

`described_class` stands in for `RegularExpression::Example` — use it instead of repeating the
class name, so a rename doesn't leave the spec out of sync.

## Build the data inline — there's no FactoryBot

When a spec needs a stand-in object, build it as a plain Ruby class or hash right there in the
spec, instead of reaching for fixtures or a factory gem:

```ruby
# from spec/requests/regular_expressions_controller_spec.rb
def build_fake(raise_once: false)
  klass = Class.new do
    include ActiveModel::Model
    attr_accessor :regular_expression, :test_string, :raised

    def diagram_svg
      '<svg/>'
    end

    def unready?; false; end
    def valid?; true; end
  end

  klass.new
end
```

Keep this lightweight approach unless a spec's setup grows large enough to genuinely justify
introducing a shared factory.

## Stub collaborators, then verify they were called

```ruby
# ✅ from spec/requests/regular_expressions_controller_spec.rb
fake = build_fake
allow(RegularExpression).to receive(:new).and_return(fake)
allow(fake).to receive(:substitute)

post regular_expressions_path, params: params

expect(fake).to have_received(:substitute)

# ❌ avoid reaching into internals to assert state changed
expect(fake.instance_variable_get(:@did)).to be true
```

`allow(...).to receive(...)` plus `have_received(...)` keeps the spec focused on the interaction
("was `substitute` called?") rather than the collaborator's private implementation.

## Comment the _why_, not the _what_

```ruby
# ✅ from spec/system/regular_expressions_spec.rb
it 'ensures legacy examples panel is removed and reference panel is present' do
  # The examples panel used to live in the page body; it was moved to the
  # header dropdown. Assert we don't have the legacy container and that the
  # reference panel is still present on the page.
  expect(page).to have_no_css 'div#examples-panel', visible: :all
  expect(page).to have_css 'div#reference-panel'
end
```

The comment explains a non-obvious history (why this assertion exists at all) — not what
`have_no_css` does.

## System specs: select by `data-*` attributes

```ruby
# ✅ from spec/system/regular_expressions_spec.rb — Stimulus targets survive markup/styling changes
find('button[data-regexp-examples-target="caretButton"]', wait: true).click
expect(page).to have_css("button[data-header-category='#{cat.to_s.parameterize}']")

# ❌ avoid selecting by CSS classes — they change with styling, not behavior
find('.dropdown-toggle-button').click
```

The Capybara driver is selected via the `DRIVER` env var (see `spec/support/capybara.rb` and
[Development Guide → Running tests locally](../../../docs/development.md#running-tests-locally)
for the full list); it defaults to headless Playwright/Chromium. When a system spec depends on
browser-specific behavior, it will also run against Firefox, WebKit, and Selenium/Chrome
automatically, via the matrixed `system_test` job in CI (not locally — see below).

## Coverage and quality bars (`.octocov.yml`)

These thresholds are enforced via octocov on every PR — keep them in mind when adding code:

| Metric                                 | Target                                                |
| -------------------------------------- | ----------------------------------------------------- |
| Line coverage                          | ≥ 95% (and no more than 1pt drop vs. the base branch) |
| Code-to-test ratio (`app/` vs `spec/`) | ≥ 1 : 1.5                                             |
| Test suite execution time              | ≤ 3 minutes                                           |

In practice this means: write a spec alongside any new code (don't leave it for later), and
prefer fast model/request specs over slow system specs where either would do — system specs are
necessary for browser-dependent behavior, but they're the main driver of suite execution time.

## Running tests

Run the suite locally with `bin/rspec` (see
[Development Guide → Running tests locally](../../../docs/development.md#running-tests-locally)
for `DRIVER=...` options to target a specific browser/engine). Lefthook (`lefthook.yml`) runs the
full suite plus linters on `pre-commit` only, using the default Playwright/Chromium driver —
there is no `pre-push` hook. Cross-browser system specs (Firefox, WebKit, Selenium/Chrome) run as
a matrixed `system_test` job in `ci.yml` instead (one parallel GitHub Actions job per browser),
not on every local push.

This split exists because running all three browsers serially on every `git push` was slow
(several minutes), and — on arm64 hosts (Apple Silicon Macs) — the Selenium/Chrome leg couldn't
run there at all (see below), so the hook's coverage depended on the host's CPU architecture.
Moving it to CI makes cross-browser coverage consistent across every contributor's machine
(Intel/Apple Silicon Mac, Windows, Linux) and keeps local `git push` fast; you can still run any
single driver locally with `DRIVER=...` when debugging a browser-specific failure.

### Selenium/Chrome inside the Dev Container and in CI

When running with `DRIVER=selenium_chrome` or `selenium_chrome_headless` inside the Dev Container
or in CI, Chrome requires `--no-sandbox` and `--disable-dev-shm-usage`. These flags are applied
automatically when `REMOTE_CONTAINERS=true` (set by VS Code's Dev Containers extension) or
`CI=true` (set by GitHub Actions):

```ruby
# spec/support/capybara.rb — active inside the Dev Container and in CI
if ENV["REMOTE_CONTAINERS"] == "true" || ENV["CI"] == "true"
  Capybara.register_driver(:selenium_chrome_headless) do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--no-sandbox")          # Docker/CI can't create Chrome sandbox processes
    options.add_argument("--disable-dev-shm-usage") # /dev/shm too small in most containers
    ...
  end
end
```

Outside those environments (a local macOS/Windows install without Docker), this block is skipped
and the default driver configuration applies. If Chrome behaves unexpectedly in CI but not
locally, check whether the Selenium driver is picking up the right options for its environment.

**arm64 Dev Container hosts (e.g. Apple Silicon Macs) still can't run this check locally.**
Google publishes no arm64 build of Chrome, and Ubuntu's `chromium` apt package is just a stub
that requires snap (unreliable inside containers) — there's no working substitute, so
`.devcontainer/setup.sh` skips the install entirely on arm64. A manual
`DRIVER=selenium_chrome_headless` run simply isn't available on those hosts — but since this
check now only runs in CI's `system_test` job (an x86_64 GitHub-hosted runner), that's no longer
a gap in coverage, just a local-debugging limitation.
