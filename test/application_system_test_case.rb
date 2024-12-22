require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  extend ActionView::Helpers::TranslationHelper
  include ActionView::Helpers::UrlHelper

  # NOTE: geckodriver installed with Firefox, ignore incompatibility warning
  Selenium::WebDriver.logger
    .ignore(:selenium_manager, :clear_session_storage, :clear_local_storage)

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
    user
  end

  def inject_button_to(after, *button_options)
    button = button_to *button_options
    evaluate_script("arguments[0].insertAdjacentHTML('beforeend', '#{button.html_safe}');", after)
  end

  #def assert_stale(element)
  #  assert_raises(Selenium::WebDriver::Error::StaleElementReferenceError) { element.tag_name }
  #end

  # HTML does not allow [disabled] attribute on <a> tag, so it's not possible to
  # easily find them using e.g. :link selector
  #Capybara.add_selector(:disabled_link) do
  #  label "<a> tag with [disabled] attribute"
  #end

  #test "click disabled link" do
    # Link should be unclickable
    # assert_raises(Selenium::WebDriver::Error::ElementClickInterceptedError) do
    #   # Use custom selector for disabled links
    #   find('a[disabled]').click
    # end
  #end
end
