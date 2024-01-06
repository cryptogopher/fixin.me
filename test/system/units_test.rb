require "application_system_test_case"

class UnitsTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
    sign_in
    visit units_path
  end

  test "index" do
    assert_selector 'tbody > tr', count: Unit.count
    assert_current_path units_path
  end

  test "add unit" do
    click_on t('units.index.add_unit')
    assert_no_selector :link_or_button, text: t('units.index.add_unit')

    within first('tbody > tr') do
      assert_selector ':focus'
      maxlength = all(:fillable_field).to_h { |f| [f[:name], f[:maxlength].to_i || 1000] }
      fill_in 'unit[symbol]',
        with: SecureRandom.random_symbol(rand([1..15, 15..maxlength['unit[symbol]']].sample))
      fill_in 'unit[name]',
        with: [nil, SecureRandom.alphanumeric(rand(1..maxlength['unit[name]']))].sample
      assert_difference ->{ Unit.count }, 1 do
        click_on t(:add)
      end
    end

    within('tbody') do
      assert_no_selector :fillable_field
      assert_selector 'tr', count: Unit.count
    end
    assert_selector :link_or_button, text: t('units.index.add_unit')

    # assert_selector flash
  end
end
