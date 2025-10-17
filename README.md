[![CI](https://github.com/aim2bpg/rubree/actions/workflows/ci.yml/badge.svg)](https://github.com/aim2bpg/rubree/actions/workflows/ci.yml)
[![Deploy](https://github.com/aim2bpg/rubree/actions/workflows/deploy.yml/badge.svg)](https://github.com/aim2bpg/rubree/actions/workflows/deploy.yml)
[![coverage]](https://github.com/aim2bpg/rubree/docs/coverage.svg)
[![coverage]](https://github.com/aim2bpg/rubree/docs/time.svg)

# [WIP] Rubree

A Ruby-based regular expression editor.

Inspired by: https://rubular.com

![Site View](https://raw.githubusercontent.com/aim2bpg/rubree/main/app/assets/images/site_view.png)

## Technology stack

### ⚙️ Backend

- [Ruby](https://www.ruby-lang.org/de/) 3.3
  > Ruby 3.4 causes runtime issues in WebAssembly builds due to missing `bigdecimal` support when used as a gem,  
  > as described in [`wasmify-rails` Issue #7](https://github.com/palkan/wasmify-rails/issues/7).  
  > We use Ruby 3.3 as a stable fallback until full 3.4 support is confirmed.
- [Ruby on Rails](https://rubyonrails.org/) 8.0
- [Regexp::Parser](https://github.com/ammar/regexp_parser/) a regular expression parser library for Ruby

### 🎨 Frontend

- [Hotwire](https://hotwired.dev/) for building the frontend without using much JavaScript by sending HTML instead of JSON over the wire
- [TailwindCSS](https://tailwindcss.com/) to not have to write CSS at all
- [RailroadDiagrams](https://github.com/ydah/railroad_diagrams) a tiny Ruby+SVG library for drawing railroad syntax diagrams like JSON.org

### 🛠️ Development

- [Foreman](https://github.com/ddollar/foreman/) for jsbundling-rails, cssbundling-rails
- [Lefthook](https://github.com/evilmartians/lefthook/) Fast and powerful Git hooks manager for any type of projects

### 🧹 Linting and testing

- [Rubocop](https://rubocop.org/) the Ruby Linter/Formatter that Serves and Protects
- [ERB Lint](https://github.com/Shopify/erb_lint/) Lint your ERB or HTML files
- [Biome](https://biomejs.dev/) Format, lint, and more in a fraction of a second
- [RSpec](https://rspec.info/) for Ruby testing
- [Playwright](https://playwright.dev/) for E2E testing

### 🚀 Deployment

- [Wasmify Rails](https://github.com/palkan/wasmify-rails/) tools and extensions to pack and run Rails apps on Wasm

### 🖥️ Production

- [GitHub Pages](https://docs.github.com/en/pages/) for Ruby on Rails on WebAssembly, the full-stack in-browser

### 🤖 Shift-left security

- [Dependabot](https://github.com/dependabot/) automated dependency updates built into GitHub
- [Gitleaks](https://github.com/gitleaks/gitleaks/) Find secrets with Gitleaks
- [Brakeman](https://github.com/presidentbeef/brakeman/) a static analysis security vulnerability scanner for Ruby on Rails applications

### ▶️ CI/CD Tool

- [GitHub Actions](https://docs.github.com/en/actions/) for testing, linting, and building web application and deploy to GitHub Pages

## Getting started

### Install for development

1. Clone the repo locally:

```
git clone https://github.com/aim2bpg/rubree.git
cd rubree
```

2. Install gem and NPM packages and start the application locally:

```
bin/setup
```

3. Then open http://localhost:3000 in your browser.

4. (Optional) Install lefthook:

```
brew install lefthook
lefthook install
```

5. (Optional) Install gitleaks for lefthook:

```
brew install gitleaks
```

### Running linters

Rubocop:

```
bin/rubocop
```

ERB Lint:

```
bin/erb_lint --lint-all
```

Biome Lint:

```
bin/yarn biome check
```

Brakeman (security scan):

```
bin/brakeman --no-pager --skip-files app/assets/builds/,build/,node_modules/,pwa/,rubies/
```

### Fixing lint errors

Rubocop:

```
bin/rubocop -a
```

ERB Lint:

```
bin/erb_lint --lint-all -a
```

Biome Lint:

```
bin/yarn biome check --write
bin/yarn biome migrate --write
```

### Running tests locally

Run tests with the default Playwright (Chromium, headless) driver:

```
bin/rspec
```

Run tests with a specific driver by setting the DRIVER environment variable:

```
# Playwright - Chromium (with browser UI)
DRIVER=playwright_chromium bin/rspec

# Playwright - Chromium (headless)
DRIVER=playwright_chromium_headless bin/rspec

# Playwright - Firefox (with browser UI)
DRIVER=playwright_firefox bin/rspec

# Playwright - Firefox (headless)
DRIVER=playwright_firefox_headless bin/rspec

# Playwright - WebKit (with browser UI)
DRIVER=playwright_webkit bin/rspec

# Playwright - WebKit (headless)
DRIVER=playwright_webkit_headless bin/rspec

# Selenium - Chrome (with browser UI)
DRIVER=selenium_chrome bin/rspec

# Selenium - Chrome (headless)
DRIVER=selenium_chrome_headless bin/rspec

# Rack Test (no JS support)
DRIVER=rack_test bin/rspec
```

### Test deployment locally

- References
  - [Wasmify Rails](https://github.com/palkan/wasmify-rails?tab=readme-ov-file#step-2-binrails-wasmifybuildcore)
  - [Ruby on Rails on WebAssembly, the full-stack in-browser journey](https://web.dev/blog/ruby-on-rails-on-webassembly?hl=ja#next_level_a_blog_in_15_minutes_in_wasm)

## Roadmap

- [x] **Basic Match Handling**: Provides functionality to match regular expressions against test strings.
- [x] **Match Positions**: Supports the extraction and display of match start and end positions.
- [x] **Capture Groups**: Extracts and displays capture groups from regex matches.
- [x] **Named Captures**: Supports capturing named groups from regex matches.
- [x] **Regex Quick Reference**: Provides a concise list of commonly used regex syntax for quick reference.
- [x] **Regex Examples**: Interactive examples to test and visualize regex patterns in real-time.
- [x] **Execution Time Measurement**: Measures and reports the execution time of regex operations.
- [x] **Regex Diagram Generation**: Generates and visualizes regex patterns using SVG diagrams.
- [x] **Regexp Substitution Function**: Supports regex-based string substitution.
- [x] **Ruby Code Snippet Generation**: Automatically generates Ruby code snippets for testing regex patterns.
- [x] **Web Interface for Regex Testing**: Interactive web UI to test and visualize regular expressions in real-time.

---

### Supported Scope of `Regexp::Parser` Used for SVG Output in `Railroad Diagrams`

- [x] **Alternation**: `a\|b\|c`
- [x] **Anchors**: `\A`, `^`, `\b`
- [x] **Character Classes**: `[abc]`, `[^\\]`, `[a-d&&aeiou]`
- [x] **Character Types**: `\d`, `\H`, `\s`
- [x] **Cluster Types**: `\R`, `\X`
- [x] **Conditional Expressions**: `(?(cond)yes-subexp)`, `(?(cond)yes-subexp\|no-subexp)`
- [x] **Escape Sequences**: `\t`, `\\+`, `\?`
- [x] **Free Space**: whitespace and `# Comments` _(x modifier)_
- [x] **Grouped Expressions**:
  - [x] **Assertions**:
    - [x] **Lookahead**: `(?=abc)`
    - [x] **Negative Lookahead**: `(?!abc)`
    - [x] **Lookbehind**: `(?<=abc)`
    - [x] **Negative Lookbehind**: `(?<!abc)`
  - [x] **Atomic**: `(?>abc)`
  - [x] **Absence**: `(?~abc)`

- [x] **Back-references**:
  - [x] **Named**: `\k<name>`
  - [x] **Nest Level**: `\k<n-1>`
  - [x] **Numbered**: `\k<1>`
  - [x] **Relative**: `\k<-2>`
  - [x] **Traditional**: `\1` through `\9`

- [x] **Capturing**: `(abc)`
- [x] **Comments**: `(?# comment text)`
- [x] **Named Captures**: `(?<name>abc)`, `(?'name'abc)`
- [x] **Options**: `(?mi-x:abc)`, `(?a:\s\w+)`, `(?i)`
- [x] **Passive Captures**: `(?:abc)`
- [x] **Subexpression Calls**: `\g<name>`, `\g<1>`

- [x] **Keep**: `\K`, `(ab\Kc\|d\Ke)f`

- [x] **Literals** _(utf-8)_:
  - [x] `Ruby`, `ルビー`, `روبي`

- [x] **POSIX Classes**:
  - [x] `[:alpha:]`, `[:^digit:]`

- [x] **Quantifiers**:
  - [x] **Greedy**: `?`, `*`, `+`, `{m,M}`
  - [ ] **Reluctant (Lazy)**: `??`, `*?`, `+?`
  - [ ] **Possessive**: `?+`, `*+`, `++`

- [x] **String Escapes**:
  - [x] **Control**: `\C-C`, `\cD`
  - [x] **Hex**: `\x20`, `\xE2\x82\xAC`
  - [x] **Meta**: `\M-c`, `\M-\C-C`, `\M-\cC`, `\C-\M-C`, `\c\M-C`
  - [x] **Octal**: `\0`, `\01`, `\012`
  - [x] **Unicode**: `\uHHHH`, `\u{H+ H+}`

- [x] **Unicode Properties** _(Unicode 15.0.0)_:
  - [x] **Age**: `\p{Age=5.2}`, `\P{age=7.0}`, `\p{^age=8.0}`
  - [x] **Blocks**: `\p{InArmenian}`, `\P{InKhmer}`, `\p{^InThai}`
  - [x] **Classes**: `\p{Alpha}`, `\P{Space}`, `\p{^Alnum}`
  - [x] **Derived**: `\p{Math}`, `\P{Lowercase}`, `\p{^Cased}`
  - [x] **General Categories**: `\p{Lu}`, `\P{Cs}`, `\p{^sc}`
  - [x] **Scripts**: `\p{Arabic}`, `\P{Hiragana}`, `\p{^Greek}`
  - [x] **Simple**: `\p{Dash}`, `\p{Extender}`, `\p{^Hyphen}`

---

For more detailed information about supported syntax, refer to the official documentation:
[Supported Syntax - Regexp::Parser GitHub README](https://github.com/ammar/regexp_parser/blob/master/README.md#supported-syntax)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aim2bpg/rubree

## Licence

This project is licensed under the MIT License, see the LICENSE file for details
