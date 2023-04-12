require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
  end

  test "sign in" do
    visit new_user_session_url
    fill_in User.human_attribute_name(:email), with: @admin.email
    fill_in User.human_attribute_name(:password), with: 'admin'
    click_on t(:sign_in)
    assert_no_current_path new_user_session_path
    assert_text t('devise.sessions.signed_in')
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
