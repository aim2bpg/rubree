require 'capybara/rspec'

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by(:playwright)
  end
end

Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(app, browser_type: :chromium, headless: true)
end
Capybara.default_max_wait_time = 15
Capybara.default_driver = :playwright
Capybara.javascript_driver = :playwright
