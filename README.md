[![CI](https://github.com/aim2bpg/rubree/actions/workflows/ci.yml/badge.svg)](https://github.com/aim2bpg/rubree/actions/workflows/ci.yml)
[![Deploy](https://github.com/aim2bpg/rubree/actions/workflows/deploy.yml/badge.svg)](https://github.com/aim2bpg/rubree/actions/workflows/deploy.yml)

# [WIP] Rubree

A Ruby-based regular expression editor.

Inspired by: https://rubular.com

## Technology stack

### ⚙️ Backend

- [Ruby](https://www.ruby-lang.org/de/) 3.3
- [Ruby on Rails](https://rubyonrails.org/) 8.0
- [Regexp::Parser](https://github.com/ammar/regexp_parser/) a regular expression parser library for Ruby

### 🎨 Frontend

- [Hotwire](https://hotwired.dev/) for building the frontend without using much JavaScript by sending HTML instead of JSON over the wire
- [TailwindCSS](https://tailwindcss.com/) to not have to write CSS at all
- [RailroadDiagrams](https://github.com/ydah/railroad_diagrams) a tiny Ruby+SVG library for drawing railroad syntax diagrams like JSON.org

### 🛠️ Development

- [Forman](https://github.com/ddollar/foreman/) for jsbundling-rails, cssbundling-rails
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
git clone git@github.com:aim2bpg/rubree.git
cd rubree
```

2. Install gem and NPM packages and start the application locally:

```
bin/setup
```

3. Install gitleaks for lefthook:

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

### Running tests locally

Ruby test:

```
bin/rspec
```

### Test deployment locally

- References
  - [Wasmify Rails](https://github.com/palkan/wasmify-rails?tab=readme-ov-file#step-2-binrails-wasmifybuildcore)
  - [Ruby on Rails on WebAssembly, the full-stack in-browser journey](https://web.dev/blog/ruby-on-rails-on-webassembly?hl=ja#next_level_a_blog_in_15_minutes_in_wasm)

## Roadmap

- [ ] Regexp replacement funciton
- [ ] ..

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aim2bpg/rubree

## Lisence

This project is licensed under the MIT License, see the LICENSE file for details
