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

### 1. Prism parser crashes in WASM

- **Symptom**: `pm_parser_init` causes `memory fault at wasm address 0xfffffffc` — out-of-bounds memory access during `eval` / `class_eval` with string arguments
- **Root cause**: Prism parser's C implementation has memory access patterns incompatible with WASM's linear memory model
- **Fix**: Two-part workaround:
  1. Source patch: force `RB_DEFAULT_PARSER` to `RB_DEFAULT_PARSER_PARSE_Y` in `version.c` (`ruby_wasm_patches/fix-default-parser-parse-y.patch`)
  2. Build config: inject `--with-parser=parse.y` via monkey-patch in `lib/tasks/wasmify_patches.rake`
- **Upstream**: [ruby/prism#4065](https://github.com/ruby/prism/issues/4065)

### 2. RubyGems deprecate.rb block passing failure

- **Symptom**: `ArgumentError: wrong number of arguments (given 0, expected 1..3)` at boot
- **Root cause**: WASM runtime does not pass blocks through `class_eval do ... end` correctly. RubyGems' `deprecate.rb` uses `class_eval do / define_method` pattern which fails
- **Fix**: Source patch converting `class_eval do/define_method` to `class_eval <<~RUBY/def` heredoc style (`ruby_wasm_patches/fix-deprecate-class-eval-block.patch`)
- **Upstream**: [ruby/rubygems#9456](https://github.com/ruby/rubygems/issues/9456)
- **Note**: The patch differs between Ruby 3.4 and 4.0 due to changed method signatures (`rubygems_deprecate` gained `version` parameter in 4.0)

### 3. wasmify-rails source URL override broken

- **Symptom**: WASM build silently uses wrong Ruby source tarball
- **Root cause**: `ruby_wasm` 2.9.0 renamed `build_source_aliases` to `build_config_aliases`, so wasmify-rails 0.4.1's monkey-patch is silently ignored
- **Fix**: `lib/tasks/wasmify_patches.rake` overrides the correct `build_config_aliases` method to set source URLs for Ruby 3.3.11, 3.4.8, and 4.0.2 (temporary workaround until upstream PR is merged)
- **Upstream**: [palkan/wasmify-rails#11](https://github.com/palkan/wasmify-rails/pull/11)

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
- **Fix**: Auto-patch wasmify-rails' `shim.rb` to add `require "rubygems"` before `require "/bundle/setup"`. Implemented in `lib/tasks/wasmify_patches.rake` (idempotent, temporary workaround until upstream PR is merged)
- **Upstream**: [palkan/wasmify-rails#12](https://github.com/palkan/wasmify-rails/pull/12)


### 6. ruby_wasm platform gem incompatible with Ruby 4.0 (Closed)

Temporary workarounds were required due to lack of Ruby 4.0 platform gem support, but this was resolved with official support in ruby_wasm 2.9.4.
(See details in [ruby/ruby.wasm#636](https://github.com/ruby/ruby.wasm/issues/636))

---

## Patches and Workarounds Summary

| File | Purpose | Applies to |
|---|---|---|
| `ruby_wasm_patches/fix-default-parser-parse-y.patch` | Force parse.y parser in `version.c` | Ruby 3.4, 4.0 |
| `ruby_wasm_patches/fix-deprecate-class-eval-block.patch` | Convert deprecate.rb to heredoc style | Ruby 3.4, 4.0 (different patch content) |
| `lib/tasks/wasmify_patches.rake` | Source URL override, parser injection, shim.rb patch | Ruby 3.3, 3.4, 4.0 |

---

## Upstream References

| Issue / PR | Repository | Status |
|---|---|---|
| [#4065](https://github.com/ruby/prism/issues/4065) Prism parser WASM crash | [ruby/prism](https://github.com/ruby/prism) | Open |
| [#9456](https://github.com/ruby/rubygems/issues/9456) `class_eval` block passing in WASM | [ruby/rubygems](https://github.com/ruby/rubygems) | Open |
| [#11](https://github.com/palkan/wasmify-rails/pull/11) `build_source_aliases` rename | [palkan/wasmify-rails](https://github.com/palkan/wasmify-rails) | Open |
| [#12](https://github.com/palkan/wasmify-rails/pull/12) `shim.rb` missing `require "rubygems"` for Ruby 4.0 | [palkan/wasmify-rails](https://github.com/palkan/wasmify-rails) | Open |
| [#7](https://github.com/palkan/wasmify-rails/issues/7) bigdecimal compatibility with Ruby 3.4 | [palkan/wasmify-rails](https://github.com/palkan/wasmify-rails) | Open |
| [#636](https://github.com/ruby/ruby.wasm/issues/636) Platform gem Ruby 4.0 precompiled binaries | [ruby/ruby.wasm](https://github.com/ruby/ruby.wasm) | Closed |