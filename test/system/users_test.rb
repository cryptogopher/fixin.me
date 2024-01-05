require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
  end

  test "sign in" do
    sign_in
    assert_no_current_path new_user_session_path
    assert_text t("devise.sessions.signed_in")
  end

  test "sign in fails with invalid password" do
    sign_in password: random_password
    assert_current_path new_user_session_path
    assert_text t("devise.failure.invalid", authentication_keys: User.human_attribute_name(:email))
  end

  test "sign out" do
    sign_in
    visit root_url
    click_on t("layouts.application.sign_out")
    assert_current_path new_user_session_path
    assert_text t("devise.sessions.signed_out")
  end

  test "recover password" do
    visit new_user_session_url
    click_on t(:recover_password)

    fill_in User.human_attribute_name(:email).capitalize,
      with: users.select(&:confirmed?).sample.email
    assert_emails 1 do
      click_on t(:recover_password)
    end
    assert_current_path new_user_session_path
    assert_text t("devise.passwords.send_instructions")

    with_last_email do |mail|
      visit Capybara.string(mail.body.to_s).find_link("Change my password")[:href]
    end
    new_password = random_password
    fill_in t("users.passwords.edit.new_password"), with: new_password
    fill_in t("users.passwords.edit.password_confirmation"), with: new_password
    assert_emails 1 do
      click_on t("users.passwords.edit.update_password")
    end
    assert_no_current_path user_password_path
    assert_text t("devise.passwords.updated")
  end

  test "register" do
    visit new_user_session_url
    click_on t(:register)

    fill_in User.human_attribute_name(:email).capitalize, with: random_email
    password = random_password
    fill_in User.human_attribute_name(:password).capitalize, with: password
    fill_in t("users.registrations.new.password_confirmation"), with: password
    assert_difference ->{User.count}, 1 do
      assert_emails 1 do
        click_on t(:register)
      end
    end

    assert_no_current_path new_user_registration_path
    assert_text t("devise.registrations.signed_up_but_unconfirmed")

    with_last_email do |mail|
      visit Capybara.string(mail.body.to_s).find_link("Confirm my account")[:href]
    end
    assert_current_path new_user_session_path
    assert_text t("devise.confirmations.confirmed")
    assert User.last.confirmed?
  end

  test "resend confirmation" do
    visit new_user_session_url
    click_on t(:register)
    click_on t(:resend_confirmation)

    fill_in User.human_attribute_name(:email).capitalize,
      with: users.reject(&:confirmed?).sample.email
    assert_emails 1 do
      click_on t(:resend_confirmation)
    end
    assert_current_path new_user_session_path
    assert_text t("devise.confirmations.send_instructions")

    with_last_email do |mail|
      visit Capybara.string(mail.body.to_s).find_link("Confirm my account")[:href]
    end
  end

  test "show profile" do
    sign_in user: users.select(&:admin?).select(&:confirmed?).sample
    click_on t("layouts.application.users")
    within all('tr').drop(1).sample do |tr|
      email = first(:link).text
      click_on email
      assert_current_path user_path(User.find_by_email!(email))
    end
  end

  test "disguise" do
    user = users.select(&:admin?).select(&:confirmed?).sample
    sign_in user: user

    click_on t("layouts.application.users")
    all(:link_or_button, text: t("users.index.disguise")).sample.click
    assert_current_path edit_user_registration_path
    # TODO: test for "Profile" link button after root_url changed to different
    # path then profile in routes.rb

    click_on t("layouts.application.revert")
    assert_current_path users_path
    assert_link user.email
  end

  test "disguise disallowed" do
    user = users.select(&:admin?).select(&:confirmed?).sample
    sign_in user: user

    click_on t("layouts.application.users")
    text = t("users.index.disguise")
    # Pick row without 'disguise' button
    undisguisable = all(:xpath, "//tbody//tr[not(descendant::*[contains(text(),\"#{text}\")])]")
    within undisguisable.sample do |tr|
      inject_button_to tr.find('td:last-child'), text,
        disguise_user_path(User.find_by_email!(first(:link).text))
      click_on text
    end
    assert_title "Bad request received (400)"
  end

  test "delete profile" do
    user = users.select(&:confirmed?).sample
    sign_in user: user
    # TODO: remove condition after root_url changed to different path than
    # profile in routes.rb
    unless has_current_path?(edit_user_registration_path)
      first(:link_or_button, user.email).click
    end
    assert_difference ->{ User.count }, -1 do
      accept_confirm { click_on t("users.registrations.edit.delete") }
    end
    assert_current_path new_user_session_path
  end

  test "index forbidden for non admin" do
    sign_in user: users.reject(&:admin?).select(&:confirmed?).sample
    visit users_path
    assert_title "Access is forbidden to this page (403)"
  end

  test "update profile" do
    # TODO
  end

  test "update status" do
    sign_in user: users.select(&:admin?).select(&:confirmed?).sample
    visit users_path

    within all(:xpath, "//tbody//tr[descendant::select]").sample do |tr|
      user = User.find_by_email!(first(:link).text)
      status = find(:select)
      new_status = (status.all(:option).map(&:value) - [status.value]).sample
      assert_changes ->{ user.reload.status }, from: status.value, to: new_status do
        status.select new_status
      end
    end
    assert_current_path users_path
  end

  test "update status disallowed" do
    sign_in user: users.select(&:admin?).select(&:confirmed?).sample
    visit users_path

    within all(:xpath, "//tbody//tr[not(descendant::select)]").sample do |tr|
      user = User.find_by_email!(first(:link).text)
      inject_button_to first('td'), "update status", user_path(user), method: :patch,
        params: {user: {status: User.statuses.keys.sample}}
      click_on "update status"
    end
    assert_title "Bad request received (400)"
  end

  test "update status forbidden for non admin" do
    sign_in user: users.reject(&:admin?).select(&:confirmed?).sample
    visit root_path
    inject_button_to find('body'), "update status", user_path(User.all.sample), method: :patch,
      params: {user: {status: User.statuses.keys.sample}}
    click_on "update status"
    assert_title "Access is forbidden to this page (403)"
  end
end
