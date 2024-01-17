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
    assert_no_selector :link_or_button, text: t('units.index.add_unit')

    within first('tbody > tr') do
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

    within('tbody') do
      assert_no_selector :fillable_field
      assert_selector 'tr', count: @user.units.count
    end
    assert_selector :link_or_button, text: t('units.index.add_unit')

    # assert_selector flash
  end

  test "close new unit form with escape" do
    click_on t('units.index.add_unit')
    first('tbody > tr').all(:field).sample.send_keys :escape
    within('tbody') do
      assert_no_selector :fillable_field
    end
  end
end
