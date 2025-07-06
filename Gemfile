source "https://rubygems.org"

ruby file: ".ruby-version"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2", group: [:default, :wasm]
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft", group: [:default, :wasm]
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 2.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails", group: [:default, :wasm]
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails", group: [:default, :wasm]
# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Tools and extensions to pack and run Rails apps on Wasm [https://github.com/palkan/wasmify-rails/]
gem "wasmify-rails", "~> 0.2.3", group: [:default, :wasm]

# A regular expression parser library for Ruby [https://github.com/ammar/regexp_parser/]
gem "regexp_parser", group: [:default, :wasm]

# A tiny Ruby+SVG library for drawing railroad syntax diagrams like JSON.org. [https://github.com/ydah/railroad_diagrams/]
gem "railroad_diagrams", group: [:default, :wasm]

group :wasm do
  gem "tzinfo-data"
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Code style checking for RSpec files (https://github.com/rubocop/rubocop-rspec)
  gem "rubocop-rspec", require: false

  # Code style checking for RSpec Rails files (https://github.com/rubocop/rubocop-rspec_rails)
  gem "rubocop-rspec_rails", require: false

  # Code style checking for Capybara test files (https://github.com/rubocop/rubocop-capybara)
  gem "rubocop-capybara", require: false

  # Lint your ERB or HTML files [https://github.com/Shopify/erb_lint/]
  gem "erb_lint"

  # RSpec for Rails (https://github.com/rspec/rspec-rails)
  gem "rspec-rails"
end

group :test do
  # Capybara aims to simplify the process of integration testing Rack applications, such as Rails, Sinatra or Merb (https://github.com/teamcapybara/capybara)
  gem "capybara"
  gem "capybara-playwright-driver"
  gem "playwright-ruby-client"
end
