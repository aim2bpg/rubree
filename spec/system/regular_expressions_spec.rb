require 'rails_helper'

RSpec.describe "RegularExpressions", type: :system do
  before do
    # NOTE: specify the driver name by setting the DRIVER environment variable
    case ENV.fetch("DRIVER", "rack_test")
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

  describe "User can create a new user" do
    specify do
      visit root_path

      fill_in 'Your regular expression:', with: '[A-Z]+'
      fill_in 'Test string:', with: 'no uppercase letters here'
  
      expect(page).to have_text('Rubree')
    end
  end
end