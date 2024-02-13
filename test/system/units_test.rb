require "application_system_test_case"

class UnitsTest < ApplicationSystemTestCase
  setup do
    @user = sign_in
    visit units_path
  end

  test "index" do
    # Wait for the table to appear first, only then check row count
    within 'tbody' do
      assert_selector 'tr', count: @user.units.count
    end

    Unit.destroy_all
    visit units_path
    within 'tbody' do
      assert_selector 'tr', count: 1
      assert_text t('units.index.no_items')
    end
  end

  test "add unit" do
    click_on t('units.index.add_unit')

    within 'tbody > tr:has(input, textarea)' do
      assert_selector ':focus'
      maxlength = all(:fillable_field).to_h { |f| [f[:name], f[:maxlength].to_i || 1000] }
      fill_in 'unit[symbol]',
        with: SecureRandom.random_symbol(rand([1..15, 15..maxlength['unit[symbol]']].sample))
      fill_in 'unit[name]',
        with: [nil, SecureRandom.alphanumeric(rand(1..maxlength['unit[name]']))].sample
      assert_difference ->{ Unit.count }, 1 do
        click_on t('helpers.submit.create')
      end
    end

    within 'tbody' do
      assert_no_selector :fillable_field
      assert_selector 'tr', count: @user.units.count
    end
    assert_selector '.flash.notice', exact_text: t('units.create.success')
  end

  test "add and edit disallow opening multiple forms" do
    # Once new/edit form is open, other actions on the same page either replace
    # the form or leave it untouched
    # TODO: add non-empty form closing warning
    links = {}
    link_labels = {1 => [t('units.index.add_unit'), t('units.unit.add_subunit')],
                   0 => units.map(&:symbol)}
    link_labels.each_pair do |row_change, labels|
      all(:link_or_button, exact_text: Regexp.union(labels)).map { |l| links[l] = row_change }
    end
    link, rows = links.assoc(links.keys.sample).tap { |l, _| links.delete(l) }
    puts link[:text]
    assert_difference ->{ all('tbody tr').count }, rows do
      link.click
    end
    find 'tbody tr:has(input[type=text]:focus)'

    # Link should be now unavailable or unclickable
    begin
      assert_raises(Selenium::WebDriver::Error::ElementClickInterceptedError) do
        link.click
      end if link.visible?
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      link = nil
    end

    link = links.keys.select(&:visible?).sample
    assert_difference ->{ all('tbody tr').count }, links[link] - rows do
      link.tap{|l| puts l[:text]}.click
    end
    assert_selector 'tbody tr:has(input[type=text]:focus)', count: 1
  end

  # NOTE: extend with any add/edit link
  test "close new unit form with escape key" do
    click_on t('units.index.add_unit')
    first('tbody > tr').all(:field).sample.send_keys :escape
    within 'tbody' do
      assert_no_selector :fillable_field
    end
  end

  # NOTE: extend with any add/edit link
  test "close and reopen new unit form" do
    click_on t('units.index.add_unit')
    within 'tbody' do
      find(:link_or_button, exact_text: t(:cancel)).click
      assert_no_selector :fillable_field
    end
    click_on t('units.index.add_unit')
    assert_selector 'tbody > tr:has(input, textarea)'
  end
end
