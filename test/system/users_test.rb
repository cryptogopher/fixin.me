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
      click_on t(:register)
    end
    assert_no_current_path new_user_registration_path
    assert_text t('devise.registrations.signed_up_but_unconfirmed')
  end

  #test "visiting the index" do
  #  visit users_url
  #  assert_selector "h1", text: "Users"
  #end

  #test "should create user" do
  #  visit users_url
  #  click_on "New user"

  #  fill_in "Email", with: @user.email
  #  fill_in "Status", with: @user.status
  #  click_on "Create User"

  #  assert_text "User was successfully created"
  #  click_on "Back"
  #end
end
