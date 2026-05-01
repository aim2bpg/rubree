# frozen_string_literal: true

# Monkey-patches for ruby_wasm / wasmify-rails to support Ruby 3.4+ WASM builds.
#
# Fixes applied:
#   1. Source URL override — use latest Ruby patch versions (4.0.3)
#   2. Parser override   — force parse.y instead of Prism (Prism crashes in WASM)
#   3. shim.rb patch     — add `require "rubygems"` for Ruby 4.0 (Gem pre-defined at C level)
#
# NOTE: wasmify-rails 0.4.1's builder.rb patches `build_source_aliases` but
#       ruby_wasm 2.9.0 renamed it to `build_config_aliases`, so the gem's
#       override is silently broken. This file uses the correct method name.

require "wasmify/rails/builder"

# --- 1. Override Ruby source tarball URLs ---
RubyWasm::CLI.singleton_class.prepend(Module.new do
  def build_config_aliases(root)
    super.tap do |sources|
      sources["4.0"][:src][:url] = "https://cache.ruby-lang.org/pub/ruby/4.0/ruby-4.0.3.tar.gz"
    end
  end
end)

# # --- 2. Force parse.y parser (Prism crashes in WASM: pm_parser_init memory fault) ---
# require "ruby_wasm/build"

# RubyWasm::CrossRubyProduct.prepend(Module.new do
#   private

#   def configure_args(build_triple, toolchain)
#     super.tap do |args|
#       unless args.any? { |a| a.include?("--with-parser=parse.y") }
#         idx = args.index("--disable-install-doc")
#         if idx
#           args.insert(idx, "--with-parser=parse.y")
#         else
#           args << "--with-parser=parse.y"
#         end
#       end
#     end
#   end
# end)

# --- 3. Patch shim.rb: add `require "rubygems"` for Ruby 4.0 ---
# Ruby 4.0 pre-defines Gem at C level but doesn't fully load rubygems.
# Bundler requires Gem::Deprecate, so shim.rb must load rubygems first.
shim_path = Gem.loaded_specs["wasmify-rails"]&.gem_dir&.then { |d| File.join(d, "lib/wasmify/rails/shim.rb") }
if shim_path && File.exist?(shim_path)
  content = File.read(shim_path)
  unless content.include?('require "rubygems"')
    patched = content.sub(
      %r{^(require "/bundle/setup")},
      "require \"rubygems\"\n\\1"
    )
    File.write(shim_path, patched)
  end
end
