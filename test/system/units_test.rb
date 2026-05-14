require "application_system_test_case"

# Fixture prerequisites:
#  * user with multiple units (at least 1 w/o subunit) + subunits,
#  * user with single unit,
# FIXME: add confirmed user without units
#  * user with no units.
# Users need to be active and confirmed.

class UnitsTest < ApplicationSystemTestCase
  def sign_in(...)
    @link_labels = nil
    @user = super { click_on t('units.navigation') }
  end

  def link_labels
    @link_labels ||= {
      new_unit:     t('units.index.new_unit'),
      new_subunit:  t('units.unit.new_subunit'),
      edit:         Regexp.union(@user.units.map(&:symbol))
    }
  end

  test "index" do
    sign_in
    # Wait for the table to appear first, only then check row count.
    within 'tbody' do
      assert_selector 'tr', count: @user.units.count
    end

    # Cannot #destroy_all due to {dependent: :restrict*} on Unit.subunits association.
    @user.units.delete_all
    refresh
    within 'tbody' do
      assert_selector 'tr', count: 1
      assert_text t('units.no_items')
    end
  end

  test "new and create" do
    sign_in
    link_labels.slice!(:new_unit, :new_subunit)
    type, label = link_labels.to_a.sample
    new_link = all(:link, exact_text: label).sample
    new_link.click
    assert_equal 'disabled', new_link[:disabled]

    values = nil
    within 'tbody > tr:has(input[type=text], textarea)' do
      assert_selector ':focus'

      maxlength = all(:fillable_field).to_h do |field|
        [field[:name], field[:maxlength].to_i || 2**16]
      end
      values = {
        symbol: random_string(deep_rand(1..3, 4..maxlength['unit[symbol]']),
                              except: @user.units.map(&:symbol), allow_blank: false),
        description: random_string(rand(0..maxlength['unit[description]']))
      }.with_indifferent_access
      within :field, 'unit[multiplier]' do |field|
        values[:multiplier] = random_number(field[:max], field[:step])
      end if type == :new_subunit

      values.each_pair { |name, value| fill_in "unit[#{name}]", with: value }

      assert_difference ->{ Unit.count }, 1 do
        click_on t('helpers.submit.create')
      end
    end

    assert_selector '.flash.notice',
      text: t('units.create.success', unit: Unit.last.symbol)
    within 'tbody' do
      assert_no_selector :fillable_field
      assert_selector 'tr', count: @user.units.count
    end
    assert_no_selector :element, :a, 'disabled': 'disabled',
      exact_text: Regexp.union(link_labels.values)
    assert_equal values, Unit.last.attributes.slice(*values.keys)
  end

  test "create updates view in order" do
    # Destroy and re-create unit to verify its index position is unchanged.
    sign_in(user: users.select { |u| u.confirmed? && u.units.many? }.sample)

    link = all(:link_or_button, exact_text: t('units.unit.destroy')).sample
    symbol = link.ancestor('tr').first(:link).text
    index = link.ancestor('tbody').all('tr').index { |e| e.first(:link).text == symbol }
    unit = @user.units.find_by(symbol: symbol)

    link.click
    if unit.base_id?
      find_link(unit.base.symbol).ancestor('tr').click_on(t('units.unit.new_subunit'))
      fill_in 'unit[multiplier]', with: unit.multiplier
    else
      click_on t('units.index.new_unit')
    end
    fill_in 'unit[symbol]', with: unit.symbol
    click_on t('helpers.submit.create')

    within "tbody > tr:nth-child(#{index+1})" do
      assert_selector :link, exact_text: symbol
    end
  end

  test "new and edit on validation error" do
    sign_in
    # It's impossible to cause validation error on :edit with single unit.
    link_labels.delete(:edit) unless @user.units.many?
    type, label = link_labels.to_a.sample
    link = all(:link, exact_text: label).sample
    link.click

    get_values = -> { all(:field).map { |f| [f[:name], f[:value]] }.to_h }
    values = nil
    within 'tbody > tr:has(input[type=text])' do
      # Provide duplicate :symbol as input invalidatable server side.
      fill_in 'unit[symbol]',
        with: (@user.units.map(&:symbol) - [find_field('unit[symbol]').value]).sample
      values = get_values[]
      send_keys :enter
    end

    # Wait for flash before checking link :disabled status.
    assert_selector '.flash.alert'
    if type == :edit
      assert_no_selector :link, exact_text: link[:text]
    else
      assert_equal 'disabled', link[:disabled]
    end

    within 'tbody > tr:has(input[type=text])' do
      assert_equal values, get_values[]
    end
  end

  test "new and edit allow opening multiple forms" do
    # Require at least 1 unit to be able to open 2 forms.
    sign_in(user: users.select { |u| u.confirmed? && u.units.any? }.sample)
    links = link_labels.transform_values do |labels|
      all(:link, exact_text: labels).to_a
    end
    random_link = ->{ links.transform_values(&:sample).compact.to_a.sample }
    # Define <tr> count change depending on link clicked.
    tr_diff = {new_unit: 1, new_subunit: 1, edit: 0}

    type, link = random_link[].tap { |t, l| links[t].delete(l) }
    subunit_link = link.ancestor('tr')
      .first(:link, link_labels[:new_subunit], between: 0..1) if type == :edit
    assert_difference ->{ all('tbody tr').count }, tr_diff[type] do
      assert_difference ->{ all('tbody tr:has(input[type=text])').count }, 1 do
        link.click
      end
    end
    form = find('tbody tr:has(input:focus)')

    if type == :edit
      refute link.visible?
      refute subunit_link&.visible?
      links[:new_subunit].delete(subunit_link)
    else
      assert link[:disabled]
    end

    type, link = random_link[]
    assert_difference ->{ all('tbody tr').count }, tr_diff[type] do
      assert_difference ->{ all('tbody tr:has(input[type=text])').count }, 1 do
        link.click
      end
    end
    assert_not_equal form, find('tbody tr:has(input:focus)')
  end

  test "edit" do
    # NOTE: Check if displayed attributes match record
    assert true
  end

  # NOTE: extend with any add/edit link
  test "new form closes on escape key" do
    sign_in
    click_on t('units.index.new_unit')
    first('tbody > tr').all(:field).sample.send_keys :escape
    within 'tbody' do
      assert_no_selector :fillable_field
    end
  end

  # NOTE: extend with any add/edit link
  test "new form can be reopened after close" do
    sign_in
    click_on t('units.index.new_unit')
    within 'tbody' do
      find(:link_or_button, exact_text: t(:cancel)).click
      assert_no_selector :fillable_field
    end
    click_on t('units.index.new_unit')
    assert_selector 'tbody > tr:has(input, textarea)'
  end

  test "rebase" do
    # TODO
    assert true
  end

  test "destroy" do
    sign_in(user: users.select { |u| u.confirmed? && u.units.any? }.sample)
    link = all(:link_or_button, exact_text: t('units.unit.destroy')).sample
    symbol = link.ancestor('tr').first(:link).text
    assert_difference ->{ @user.units.count }, -1 do
      link.click
    end
    assert_selector 'tbody tr', count: [@user.units.count, 1].max
    assert_selector '.flash.notice', text: t('units.destroy.success', unit: symbol)
  end
end
