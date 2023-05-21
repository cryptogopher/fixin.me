require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include ActionView::Helpers::UrlHelper

  # NOTE: remove when capabilities no longer used by Rails
  Selenium::WebDriver.logger.ignore(:capabilities)
  Capybara.configure do |config|
    config.save_path = "#{Rails.root}/tmp/screenshots/"
  end

  driven_by :selenium, using: :headless_firefox, screen_size: [2400, 1600] do |options|
    options.add_preference('browser.download.folderList', 2)
    options.add_preference('browser.download.dir', "#{Rails.root}/tmp/")
  end

  def sign_in(user: users.select(&:confirmed?).sample, password: randomize_user_password!(user))
    visit new_user_session_url
    fill_in User.human_attribute_name(:email).capitalize, with: user.email
    fill_in User.human_attribute_name(:password).capitalize, with: password
    click_on t(:sign_in)
  end

  def inject_button_to(after, *button_options)
    button = button_to *button_options
    evaluate_script("arguments[0].insertAdjacentHTML('beforeend', '#{button.html_safe}');", after)
  end

  #def assert_stale(element)
  #  assert_raise(Selenium::WebDriver::Error::StaleElementReferenceError) { element.tag_name }
  #end
end
