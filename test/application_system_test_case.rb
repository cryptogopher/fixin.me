require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # NOTE: remove when capabilities no longer used by Rails
  Selenium::WebDriver.logger.ignore(:capabilities)

  driven_by :selenium, using: :headless_firefox, screen_size: [2400, 1600]

  def sign_in(user: users.select(&:confirmed?).sample, password: randomize_user_password!(user))
    visit new_user_session_url
    fill_in User.human_attribute_name(:email).capitalize, with: user.email
    fill_in User.human_attribute_name(:password).capitalize, with: password
    click_on t(:sign_in)
  end
end
