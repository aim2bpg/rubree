RSpec.configure do |config|
  config.before(:each, type: :system) do
    case ENV.fetch("DRIVER", "playwright_chromium_headless")
    when "rack_test"
      driven_by(:rack_test)
    when "selenium_chrome"
      driven_by(:selenium_chrome)
    when "selenium_chrome_headless"
      driven_by(:selenium_chrome_headless)
    when "playwright_chromium"
      driven_by(:playwright, options: { headless: false, browser_type: :chromium })
    when "playwright_chromium_headless"
      driven_by(:playwright, options: { headless: true, browser_type: :chromium })
    when "playwright_firefox"
      driven_by(:playwright, options: { headless: false, browser_type: :firefox })
    when "playwright_firefox_headless"
      driven_by(:playwright, options: { headless: true, browser_type: :firefox })
    when "playwright_webkit"
      driven_by(:playwright, options: { headless: false, browser_type: :webkit })
    when "playwright_webkit_headless"
      driven_by(:playwright, options: { headless: true, browser_type: :webkit })
    else
      raise "Invalid DRIVER: #{driver}"
    end
  end
end

Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(app, browser_type: :chromium, headless: true)
end

Capybara.default_max_wait_time = 15
Capybara.default_driver = :playwright
Capybara.javascript_driver = :playwright
