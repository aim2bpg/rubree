#!/usr/bin/env ruby
# frozen_string_literal: true

# Print cache fingerprints for the WASM build (consumed by .github/workflows/deploy.yml).
#
# Must run with BUNDLE_ONLY=wasm so the Bundler definition matches what
# `bin/rails wasmify:build` sees (the rake task re-execs itself with BUNDLE_ONLY=wasm).
#
# Output is GITHUB_OUTPUT-compatible, one fingerprint per line:
#
#   exts=<sha256>  Native-extension gems that ruby_wasm cross-compiles into the
#                  rubies/*.tar.gz tarball. Mirrors RubyWasm::Packager::Core::
#                  BuildStrategy#specs_with_extensions: specs with extensions,
#                  minus config/wasmify.yml exclude_gems / ignore_gem_extensions
#                  (applied by Wasmify::Rails::Builder) and the packager's own
#                  EXCLUDED_GEMS. The tarball filename embeds an MD5 of exactly
#                  these full_names, so this fingerprint changes if and only if
#                  a recompile is needed.
#
#   all=<sha256>   Every gem resolved in the :wasm group. These are embedded
#                  into ruby.wasm as the /bundle filesystem image (the shim's
#                  `require "/bundle/setup"`), so any version change here makes
#                  the compiled ruby.wasm module stale even when no native
#                  extension changed. Includes ruby_wasm and wasmify-rails
#                  themselves, so toolchain bumps also rotate this fingerprint.
#
# Pass --list to also print the gem lists to stderr for debugging.

abort "error: run with BUNDLE_ONLY=wasm (got: #{ENV["BUNDLE_ONLY"].inspect})" unless ENV["BUNDLE_ONLY"] == "wasm"

require "bundler"
require "digest"
require "yaml"

definition = Bundler.definition
specs = definition.resolve.materialize(definition.requested_dependencies)

# A LazySpecification means a locked gem is not actually installed. Dropping it
# would silently shrink the fingerprint and risk reusing a stale cache entry, so
# fail loudly instead (CI installs the full bundle before running this script).
lazy = specs.select { |spec| spec.is_a?(Bundler::LazySpecification) }
abort "error: unmaterialized specs (run bundle install first): #{lazy.map(&:full_name).join(", ")}" if lazy.any?

wasmify_config = YAML.load_file(File.expand_path("../config/wasmify.yml", __dir__))
excluded = (wasmify_config["exclude_gems"] || []) +
  (wasmify_config["ignore_gem_extensions"] || []) +
  %w[ruby_wasm bundler] # RubyWasm::Packager::EXCLUDED_GEMS

ext_names = specs
  .select { |spec| spec.extensions.any? }
  .reject { |spec| excluded.include?(spec.name) }
  .map(&:full_name).sort
all_names = specs.map(&:full_name).sort

if ARGV.include?("--list")
  warn "exts:\n  #{ext_names.join("\n  ")}"
  warn "all:\n  #{all_names.join("\n  ")}"
end

puts "exts=#{Digest::SHA256.hexdigest(ext_names.join("\n"))}"
puts "all=#{Digest::SHA256.hexdigest(all_names.join("\n"))}"
