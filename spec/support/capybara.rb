RSpec.configure do |config|
  config.before(:each, type: :system) do
    driver_env = ENV['DRIVER'] || 'playwright'

    case driver_env
    when 'playwright'
      driven_by(:playwright)
    when 'selenium_chrome'
      driven_by(:selenium_chrome)
    when 'selenium_chrome_headless'
      driven_by(:selenium_chrome_headless)
    else
      raise "Unknown DRIVER: #{driver_env}"
    end
  end
end

Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(app, browser_type: :chromium, headless: true)
end

Capybara.default_max_wait_time = 15
Capybara.default_driver = :playwright
Capybara.javascript_driver = :playwright
