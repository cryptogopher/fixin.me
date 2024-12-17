require "application_system_test_case"

# Fixture prerequisites:
#  * user with multiple units + subunits
#  * user with single unit
#  * user with no units

class UnitsTest < ApplicationSystemTestCase
  LINK_LABELS = {
    add_unit: t('units.index.add_unit'),
    add_subunit: t('units.unit.add_subunit'),
    edit: nil
  }

  setup do
    @user = sign_in
    LINK_LABELS[:edit] = Regexp.union(@user.units.map(&:symbol))

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

  test "new and create" do
    type, label = LINK_LABELS.assoc([:add_unit, :add_subunit].sample)
    add_link = all(:link, exact_text: label).sample
    add_link.click
    assert_equal 'disabled', add_link[:disabled]

    values = nil
    within 'tbody > tr:has(input[type=text], textarea)' do
      assert_selector ':focus'

      maxlength = all(:fillable_field).to_h { |f| [f[:name], f[:maxlength].to_i || 2**16] }
      values = {
        symbol: random_string(rand([1..3, 4..maxlength['unit[symbol]']].sample),
                              except: units.map(&:symbol)),
        description: random_string(rand(0..maxlength['unit[description]']))
      }.with_indifferent_access
      within :field, 'unit[multiplier]' do |field|
        values[:multiplier] = random_number(field[:max], field[:step])
      end if type == :add_subunit

      values.each_pair { |name, value| fill_in "unit[#{name}]", with: value }

      assert_difference ->{ Unit.count }, 1 do
        click_on t('helpers.submit.create')
      end
    end

    assert_selector '.flash.notice', text: t('units.create.success', unit: Unit.last.symbol)
    within 'tbody' do
      assert_no_selector :fillable_field
      assert_selector 'tr', count: @user.units.count
    end
    assert_no_selector :element, :a, 'disabled': 'disabled',
      exact_text: Regexp.union(LINK_LABELS.fetch_values(:add_unit, :add_subunit))
    assert_equal values, Unit.last.attributes.slice(*values.keys)
  end

  test "new and edit on validation error" do
    # It's not possible to cause validation error on :edit with single unit
    LINK_LABELS.delete(:edit) unless @user.units.count > 1
    type, label = LINK_LABELS.assoc(LINK_LABELS.keys.sample)
    link = all(:link, exact_text: label).sample
    link.click

    get_values = -> { all(:field).map { |f| [f[:name], f[:value]] }.to_h }
    values = nil
    within 'tbody > tr:has(input[type=text])' do
      # Provide duplicate :symbol as input invalidatable server side
      fill_in 'unit[symbol]',
        with: (@user.units.map(&:symbol) - [find_field('unit[symbol]').value]).sample
      values = get_values[]
      send_keys :enter
    end

    # Wait for flash before checking link :disabled status
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

  # TODO: add non-empty form closing warning
  test "new and edit disallow opening multiple forms" do
    # Once new/edit form is open, attempt to open another one will close it
    links = {}
    targets = {}
    LINK_LABELS.each_pair do |type, labels|
      links[type] = all(:link_or_button, exact_text: labels).to_a
      targets[type] = links[type].sample
    end
    # Define tr count change depending on link clicked
    row_change = {add_unit: 1, add_subunit: 1, edit: 0}

    type, link = targets.assoc(targets.keys.sample).tap { |t, _| targets.delete(t) }
    rows = row_change[type]
    assert_difference ->{ all('tbody tr').count }, rows do
      link.click
    end
    within('tbody tr:has(input[type=text])') { assert_selector ':focus' }
    if type == :edit
      assert !link.visible?
      [:add_subunit, :edit].each do |t|
        assert_difference(->{ links[t].length }, -1) { links[t].select!(&:visible?) }
      end
    else
      assert link[:disabled]
    end

    targets.merge([:add_subunit, :edit].map { |t| [t, links[t].sample] }.to_h)
    type, link = targets.assoc(targets.keys.sample)
    assert_difference ->{ all('tbody tr').count }, row_change[type] - rows do
      link.click
    end
    within('tbody tr:has(input[type=text])') { assert_selector ':focus' }
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
