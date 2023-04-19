require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
  end

  test "sign in" do
    sign_in
    assert_no_current_path new_user_session_path
    assert_text t('devise.sessions.signed_in')
  end

  test "sign in fails with invalid password" do
    sign_in password: random_password
    assert_current_path new_user_session_path
    assert_text t('devise.failure.invalid', authentication_keys: User.human_attribute_name(:email))
  end

  test "sign out" do
    sign_in user: @admin
    visit root_url
    click_on t(:sign_out)
    assert_current_path new_user_session_path
    assert_text t('devise.sessions.signed_out')
  end

  test "register" do
    visit new_user_session_url
    click_link t(:register)

    fill_in User.human_attribute_name(:email).capitalize, with: random_email
    password = random_password
    fill_in User.human_attribute_name(:password).capitalize, with: password
    fill_in t('users.registrations.new.password_confirmation'), with: password
    assert_difference ->{User.count}, 1 do
      assert_emails 1 do
        click_on t(:register)
      end
    end

    assert_no_current_path new_user_registration_path
    assert_text t('devise.registrations.signed_up_but_unconfirmed')

    with_last_email do |mail|
      visit Capybara.string(mail.body.to_s).find_link("Confirm my account")[:href]
    end
    assert_current_path new_user_session_path
    assert_text t('devise.confirmations.confirmed')
    assert User.last.confirmed?
  end

  test "recover password" do
    visit new_user_session_url
    click_link t(:recover_password)

    fill_in User.human_attribute_name(:email).capitalize, with: users.sample.email
    assert_emails 1 do
      click_on t(:recover_password)
    end
    assert_current_path new_user_session_path
    assert_text t('devise.passwords.send_instructions')

    with_last_email do |mail|
      visit Capybara.string(mail.body.to_s).find_link("Change my password")[:href]
    end
    new_password = random_password
    fill_in t('users.passwords.edit.new_password'), with: new_password
    fill_in t('users.passwords.edit.password_confirmation'), with: new_password
    assert_emails 1 do
      click_on t('users.passwords.edit.update_password')
    end
    assert_no_current_path user_password_path
    assert_text t('devise.passwords.updated')
  end
end
