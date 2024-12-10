require "application_system_test_case"

class UnitsTest < ApplicationSystemTestCase
  ADD_UNIT_LABELS = [t('units.index.add_unit'), t('units.unit.add_subunit')]

  setup do
    @user = sign_in
    visit units_path
  end

  test "index" do
    # Wait for the table to appear first, only then check row count
    within 'tbody' do
      assert_selector 'tr', count: @user.units.count
    end

    # Cannot #destroy_all due to {dependent: :restrict*} on Unit.subunits association
    @user.units.delete_all
    visit units_path
    within 'tbody' do
      assert_selector 'tr', count: 1
      assert_text t('units.index.no_items')
    end
  end

  # TODO: check if Add buton is properly disabled/enabled
  # TODO: extend with add subunit
  test "add unit" do
    click_on t('units.index.add_unit')

    within 'tbody > tr:has(input[type=text], textarea)' do
      assert_selector ':focus'
      maxlength = all(:fillable_field).to_h { |f| [f[:name], f[:maxlength].to_i || 1000] }
      fill_in 'unit[symbol]',
        with: SecureRandom.random_symbol(rand([1..15, 15..maxlength['unit[symbol]']].sample))
      fill_in 'unit[description]',
        with: [nil, SecureRandom.alphanumeric(rand(1..maxlength['unit[description]']))].sample
      assert_difference ->{ Unit.count }, 1 do
        click_on t('helpers.submit.create')
      end
    end

    within 'tbody' do
      assert_no_selector :fillable_field
      assert_selector 'tr', count: @user.units.count
    end
    assert_selector '.flash.notice', text: /^#{t('units.create.success', unit: @user.units.last)}/
  end

  # TODO: check proper form/button redisplay and flash messages
  test "add unit on validation error" do
  end

  # TODO: add non-empty form closing warning
  test "add and edit disallow opening multiple forms" do
    # Once new/edit form is open, attempt to open another one will close it
    links = {}
    # Define tr count change depending on link clicked
    link_labels = {1 => ADD_UNIT_LABELS, 0 => units.map(&:symbol)}
    link_labels.each_pair do |row_change, labels|
      all(:link_or_button, exact_text: Regexp.union(labels)).map { |l| links[l] = row_change }
    end

    link, rows = links.assoc(links.keys.sample).tap { |l, _| links.delete(l) }
    assert_difference ->{ all('tbody tr').count }, rows do
      link.click
    end
    find('tbody tr:has(input[type=text])').assert_selector ':focus'
    assert !link.visible? || link[:disabled]

    link = links.keys.select(&:visible?).sample
    assert_difference ->{ all('tbody tr').count }, links[link] - rows do
      link.click
    end
    find('tbody tr:has(input[type=text])').assert_selector ':focus'
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
