require "application_system_test_case"

# Fixture prerequisites:
#  * user with multiple units + subunits
#  * user with single unit
#  * user with no units

class UnitsTest < ApplicationSystemTestCase
  LINK_LABELS = {}

  setup do
    @user = sign_in

    LINK_LABELS.clear
    LINK_LABELS[:new_unit] = t('units.index.new_unit')
    LINK_LABELS[:new_subunit] = t('units.unit.new_subunit')
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
      assert_text t('units.no_items')
    end
  end

  test "new and create" do
    type, label = LINK_LABELS.assoc([:new_unit, :new_subunit].sample)
    new_link = all(:link, exact_text: label).sample
    new_link.click
    assert_equal 'disabled', new_link[:disabled]

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
      end if type == :new_subunit

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
      exact_text: Regexp.union(LINK_LABELS.fetch_values(:new_unit, :new_subunit))
    assert_equal values, Unit.last.attributes.slice(*values.keys)
  end

  test "new and edit on validation error" do
    # It's not possible to cause validation error on :edit with single unit
    LINK_LABELS.delete(:edit) unless @user.units.count > 1
    type, label = LINK_LABELS.to_a.sample
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

  test "new and edit allow opening multiple forms" do
    # Requires at least 1 unit to be able to open 2 forms
    links = LINK_LABELS.transform_values { |labels| all(:link, exact_text: labels).to_a }
    random_link = ->{ links.transform_values(&:sample).compact.to_a.sample }
    # Define tr count change depending on link clicked
    tr_diff = {new_unit: 1, new_subunit: 1, edit: 0}

    type, link = random_link[].tap { |t, l| links[t].delete(l) }
    subunit_link = link.ancestor('tr')
      .first(:link, LINK_LABELS[:new_subunit], between: 0..1) if type == :edit
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

  #test "edit" do
    # NOTE: Check if displayed attributes match record
  #end

  # NOTE: extend with any add/edit link
  test "close new unit form with escape key" do
    click_on t('units.index.new_unit')
    first('tbody > tr').all(:field).sample.send_keys :escape
    within 'tbody' do
      assert_no_selector :fillable_field
    end
  end

  # NOTE: extend with any add/edit link
  test "close and reopen new unit form" do
    click_on t('units.index.new_unit')
    within 'tbody' do
      find(:link_or_button, exact_text: t(:cancel)).click
      assert_no_selector :fillable_field
    end
    click_on t('units.index.new_unit')
    assert_selector 'tbody > tr:has(input, textarea)'
  end

  test "destroy" do
    link = all(:link_or_button, exact_text: t('units.unit.destroy')).sample
    label = link.ancestor('tr').first(:link)[:text]
    assert_difference ->{ @user.units.count }, -1 do
      link.click
    end
    assert_selector 'tbody tr', count: [@user.units.count, 1].max
    assert_selector '.flash.notice', text: t('units.destroy.success', unit: label)
  end
end
