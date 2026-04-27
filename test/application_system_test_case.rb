require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include ActionView::Helpers::SanitizeHelper
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
    fill_in User.human_attribute_name(:email), with: user.email
    fill_in User.human_attribute_name(:password), with: password
    click_on t(:sign_in)
    user
  end

  def inject_button_to(inside, *button_options)
    button = button_to *button_options
    inside.evaluate_script("this.insertAdjacentHTML('beforeend', arguments[0]);",
                           button.html_safe)
  end

  # Allow skipping interpolations when translating for testing purposes
  INTERPOLATION_PATTERNS = Regexp.union(I18n.config.interpolation_patterns)
  def translate(key, **options)
    translation = options.empty? ? super.split(INTERPOLATION_PATTERNS, 2).first : super
    sanitize(translation, tags: [])
  end
  alias :t :translate

  DB_CONFIGS = ActiveRecord::Base.configurations.configs_for(env_name: "test")
  TEST_CONFIGS = Hash.new(DB_CONFIGS.first.name.to_sym)
  class << self
    # NOTE: alternative to current solution is to create shards:
    #   ActiveRecord::Base.connects_to(
    #     shards: {mysql2: {writing: :mysql2}, sqlite3: {writing: :sqlite3}}
    #   )
    # and use them in one of the following ways:
    # * set config.active_record.shard_selector/shard_resolver
    # * run tests within: ActiveRecord::Base.connected_to(shard: :sqlite3) { test_ }
    # Remove this note once current solution is confirmed to work.
    #
    # Test block should not be modified here, as it would change its binding from
    # instance level to class level.
    if DB_CONFIGS.many?
      def test(name, ...)
        DB_CONFIGS.each do |config|
          TEST_CONFIGS[super("#{config.name} #{name}", ...)] = config.name.to_sym
        end
      end
    end
  end
  setup do
    ActiveRecord::Base.establish_connection(TEST_CONFIGS[name.to_sym])
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
