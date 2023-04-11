require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # NOTE: remove when capabilities no longer used by Rails
  Selenium::WebDriver.logger.ignore(:capabilities)

  driven_by :selenium, using: :headless_firefox, screen_size: [1600, 900]
end
