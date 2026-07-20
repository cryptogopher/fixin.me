require "test_helper"

# TODO: optimize execution time by monitoring/eliminating synchronization timeouts
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
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

  def sign_in(user: users.select(&:confirmed?).sample,
              password: randomize_user_password!(user))
    visit new_user_session_url
    fill_in User.human_attribute_name(:email), with: user.email
    fill_in User.human_attribute_name(:password), with: password
    click_on t(:sign_in)
    yield if block_given?
    user
  end

  def inject_button_to(inside, *button_options)
    button = button_to *button_options
    inside.evaluate_script("this.insertAdjacentHTML('beforeend', arguments[0]);",
                           button.html_safe)
  end

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
    # TODO: allow multiple iterations of tests? would require saving seed in
    # #setup to make reproducing easier
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

  Capybara.modify_selector(:link) do
    expression_filter(:disabled) do |xpath, value|
      builder(xpath).add_attribute_conditions('aria-disabled': value)
    end
  end

  Capybara.modify_selector(:table) do
    # Matches all rows, with partial row data (i.e. doesn't match row size).
    expression_filter(:rows_with, valid_values: [Array]) do |xpath, rows|
      rows_conditions = rows.map { |row| match_row(row) }.reduce(:&)
      xpath[match_row_count(rows.size)][rows_conditions]
    end
  end

  # This regex has to be only strict enough to properly reconstruct number. It
  # is not used for format validation.
  NUMBER = /\A(
    (?<base>\-?\d[\d\.]*)
    (×(?<pow>10(?<ws>\s)?(?<exp>(?(<-2>)()|(\-))[\d]+)))?
      |
    \g<pow>
  )\z/x
  # Finds table cell in current row corresponding to column name given in locator.
  # Based on Capybara :table and :table_row selectors.
  Capybara.add_selector(:table_cell, locator_type: [String, Symbol]) do
    xpath do |locator|
      column = XPath.string.n.is(locator.to_s)
      header_xp = XPath.ancestor(:table)[1].descendant(:tr)[1].descendant(:th)[column]
      position_xp = XPath.position.equals(header_xp.preceding_sibling.count.plus(1))
      XPath.descendant(:td).where(header_xp.boolean & position_xp)
    end

    expression_filter(:fillable) do |xpath, value|
      value ? xpath.where(XPath.descendant(:input, :select, :textarea)) : xpath
    end

    node_filter(:with) do |node, expected|
      value =
        case expected
        when Float
          node.text.match(NUMBER) { |m| "#{m['base'] || '1'}e#{m['exp']&.lstrip}".to_f }
        else
          node.text
        end
      (expected == value).tap do |result|
        add_error("Expected value to be #{expected.inspect}" \
                  " but was #{value.inspect}") unless result
      end
    end
  end

  Capybara.modify_selector(:table_row) do
    # Beware: filters of #boolean? type are called within different context.
    node_filter(:with_focus, :boolean) do |node, value|
      node.has_selector?(':focus') == value
    end
  end
end
