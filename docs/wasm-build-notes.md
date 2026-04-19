# WASM Build Notes

This document records the issues encountered and workarounds applied when building Ruby as WebAssembly for Rubree.

## Table of Contents

- [Ruby 3.4 Issues](#ruby-34-issues)
  - [1. Prism parser crashes in WASM](#1-prism-parser-crashes-in-wasm)
  - [2. RubyGems deprecate.rb block passing failure](#2-rubygems-deprecaterb-block-passing-failure)
  - [3. wasmify-rails source URL override broken](#3-wasmify-rails-source-url-override-broken)
  - [4. bigdecimal in exclude_gems causes LoadError](#4-bigdecimal-in-exclude_gems-causes-loaderror)
- [Ruby 4.0 Additional Issues](#ruby-40-additional-issues)
  - [5. Gem::Deprecate not loaded in WASM runtime](#5-gemdeprecate-not-loaded-in-wasm-runtime)
  - [6. ruby_wasm platform gem incompatible with Ruby 4.0](#6-ruby_wasm-platform-gem-incompatible-with-ruby-40)
- [Patches and Workarounds Summary](#patches-and-workarounds-summary)
- [Upstream References](#upstream-references)

---

## Ruby 3.4 Issues

These issues were first discovered during Ruby 3.4.8 WASM support (PR [#527](https://github.com/aim2bpg/rubree/pull/527)). Issues 1–2 also apply to Ruby 4.0.


### 1. Prism parser crashes in WASM (Closed)

- **Status**: No longer reproducible. The original memory fault was due to a misconfiguration in wasmify-rails (source URL override and missing patches). After correcting the setup, the crash does not occur, and the issue is considered resolved upstream.
- **Upstream**: [ruby/prism#4065](https://github.com/ruby/prism/issues/4065)


### 2. RubyGems deprecate.rb block passing failure (Closed)

- **Status**: No longer reproducible. The error was due to an outdated patch and/or old RubyGems version in wasmify-rails. With the latest upstream fixes and correct configuration, the problem does not occur.
- **Upstream**: [ruby/rubygems#9456](https://github.com/ruby/rubygems/issues/9456)

### 3. wasmify-rails source URL override broken

- **Symptom**: WASM build silently uses wrong Ruby source tarball
- **Root cause**: `ruby_wasm` 2.9.0 renamed `build_source_aliases` to `build_config_aliases`, so wasmify-rails 0.4.1's monkey-patch is silently ignored
**Fix**: `lib/tasks/wasmify_patches.rake` overrides the `build_config_aliases` method to set correct source URLs for Ruby 3.3.11, 3.4.8, and 4.0.2 (temporary workaround for wasmify-rails <= 0.4.1).
  - *April 2026*: [palkan/wasmify-rails#11](https://github.com/palkan/wasmify-rails/pull/11) has been merged to main, but the gem version is not yet updated. The patch is still required for now, and will be removed after the next gem release.

### 4. bigdecimal in exclude_gems causes LoadError

- **Symptom**: `LoadError` for bigdecimal during WASM pack
- **Root cause**: `bigdecimal` moved from `ext/` to a bundled gem in Ruby 3.4
- **Fix**: Removed `bigdecimal` from `config/wasmify.yml` `exclude_gems`
- **Upstream**: [palkan/wasmify-rails#7](https://github.com/palkan/wasmify-rails/issues/7)

---

## Ruby 4.0 Additional Issues

These issues appeared when upgrading from Ruby 3.4 to 4.0 (PRs [#528](https://github.com/aim2bpg/rubree/pull/528)–[#530](https://github.com/aim2bpg/rubree/pull/530)).

### 5. Gem::Deprecate not loaded in WASM runtime

- **Symptom**: `uninitialized constant Gem::Deprecate (NameError)` at boot in WASM
- **Root cause**: Ruby 4.0 pre-defines the `Gem` module at the C level, causing `require "rubygems"` to be skipped (it thinks RubyGems is already loaded). But `Gem::Deprecate` and other classes are not actually defined
**Fix**: Auto-patch wasmify-rails' `shim.rb` to add `require "rubygems"` before `require "/bundle/setup"` (idempotent, temporary workaround via `lib/tasks/wasmify_patches.rake`).
  - *April 2026*: [palkan/wasmify-rails#12](https://github.com/palkan/wasmify-rails/pull/12) has been merged to main, but the gem version is not yet updated. The patch is still required for now, and will be removed after the next gem release.


### 6. ruby_wasm platform gem incompatible with Ruby 4.0 (Closed)

Temporary workarounds were required due to lack of Ruby 4.0 platform gem support, but this was resolved with official support in ruby_wasm 2.9.4.
(See details in [ruby/ruby.wasm#636](https://github.com/ruby/ruby.wasm/issues/636))

---

## Patches and Workarounds Summary

| File | Purpose | Applies to |
|---|---|---|
| `ruby_wasm_patches/fix-default-parser-parse-y.patch` | Force parse.y parser in `version.c` | Ruby 3.4, 4.0 |
| `ruby_wasm_patches/fix-deprecate-class-eval-block.patch` | Convert deprecate.rb to heredoc style | Ruby 3.4, 4.0 (different patch content) |
| `lib/tasks/wasmify_patches.rake` | Source URL override (`build_config_aliases`), parser injection, shim.rb patch (`require "rubygems"`) | Ruby 3.3, 3.4, 4.0 (PRs have been merged upstream, but the patch is still required for the current gem version; will be removed after the next release) |

---

## Upstream References

| Issue / PR | Repository | Status |
|---|---|---|
| [#4065](https://github.com/ruby/prism/issues/4065) Prism parser WASM crash | [ruby/prism](https://github.com/ruby/prism) | Open |
| [#9456](https://github.com/ruby/rubygems/issues/9456) `class_eval` block passing in WASM | [ruby/rubygems](https://github.com/ruby/rubygems) | Open |
| [#11](https://github.com/palkan/wasmify-rails/pull/11) `build_source_aliases` rename | [palkan/wasmify-rails](https://github.com/palkan/wasmify-rails) | Merged (April 2026, gem not yet updated) |
| [#12](https://github.com/palkan/wasmify-rails/pull/12) `shim.rb` missing `require "rubygems"` for Ruby 4.0 | [palkan/wasmify-rails](https://github.com/palkan/wasmify-rails) | Merged (April 2026, gem not yet updated) |
| [#7](https://github.com/palkan/wasmify-rails/issues/7) bigdecimal compatibility with Ruby 3.4 | [palkan/wasmify-rails](https://github.com/palkan/wasmify-rails) | Open |
| [#636](https://github.com/ruby/ruby.wasm/issues/636) Platform gem Ruby 4.0 precompiled binaries | [ruby/ruby.wasm](https://github.com/ruby/ruby.wasm) | Closed |