require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
  end

  test 'sign in' do
    visit root_url
    assert find_link(href: new_user_session_path)[:disabled]

    sign_in
    assert_no_current_path new_user_session_path
    assert_text t('devise.sessions.signed_in')
  end

  test 'sign in fails with invalid credentials' do
    label = User.human_attribute_name(:email)
    # Both: valid and invalid emails should give the same (paranoid) error message.
    email = [users.sample.email, random_email].sample

    visit root_url
    fill_in label, with: email
    fill_in User.human_attribute_name(:password), with: random_password
    click_on t(:sign_in)

    assert_current_path new_user_session_path
    assert_text t('devise.failure.invalid', authentication_keys: label.downcase_first)
    assert find_link(href: new_user_session_path)[:disabled]
    assert has_field?(label, with: email)
  end

  test 'sign out' do
    sign_in
    visit root_url
    click_on t("layouts.application.sign_out")
    assert_current_path new_user_session_path
    assert_text t("devise.sessions.signed_out")
  end

  test 'recover password' do
    label = User.human_attribute_name(:email)
    email = users.select(&:confirmed?).sample.email

    visit root_url
    fill_in label, with: email
    # Form validations should allow empty password.
    assert has_field?(User.human_attribute_name(:password), with: nil)

    assert_emails 1 do
      click_on t(:recover_password)
      assert_current_path new_user_session_path
      # Wait for flash message to make sure async request has been processed.
      assert_text t("devise.passwords.send_paranoid_instructions")
    end
    assert has_field?(label, with: email)

    with_last_email do |mail|
      visit Capybara.string(mail.body.to_s).find_link("Change my password")[:href]
      assert_current_path edit_user_password_path, ignore_query: true
      # Make sure flash message is not displayed twice.
      assert_no_text t("devise.passwords.send_paranoid_instructions")
    end
    new_password = random_password
    fill_in t("users.passwords.edit.password_html"), with: new_password
    fill_in t("helpers.label.user.password_confirmation"), with: new_password
    assert_emails 1 do
      click_on t("users.passwords.edit.update_password")
      assert_current_path units_path
      assert_text t("devise.passwords.updated")
    end
  end

  test 'recover password for nonexistent user' do
    label = User.human_attribute_name(:email)
    email = random_email

    visit root_url
    fill_in label, with: email

    assert_no_emails do
      click_on t(:recover_password)
      assert_current_path new_user_session_path
      assert_text t("devise.passwords.send_paranoid_instructions")
    end
  end

  test 'register' do
    visit root_url
    click_on t(:register)
    assert find_link(href: new_user_registration_path)[:disabled]

    fill_in User.human_attribute_name(:email), with: random_email
    password = random_password
    fill_in User.human_attribute_name(:password), with: password
    fill_in t("users.profiles.new.password_confirmation"), with: password
    assert_difference ->{ User.count }, 1 do
      assert_emails 1 do
        click_on t(:register)
        assert_current_path new_user_session_path
        assert_text t("devise.registrations.signed_up_but_unconfirmed")
      end
    end

    assert_changes ->{ User.last.confirmed? }, from: false, to: true do
      with_last_email do |mail|
        visit Capybara.string(mail.body.to_s).find_link("Confirm my account")[:href]
        assert_current_path new_user_session_path
        assert_text t("devise.confirmations.confirmed")
      end
    end
  end

  test 'resend confirmation' do
    label = User.human_attribute_name(:email)
    user = users.reject(&:confirmed?).sample

    visit root_url
    click_on t(:register)
    fill_in label, with: user.email
    assert has_field?(User.human_attribute_name(:password), with: nil)

    assert_emails 1 do
      click_on t(:resend_confirmation)
      assert_current_path new_user_registration_path
      assert_text t("devise.confirmations.send_paranoid_instructions")
    end
    assert has_field?(label, with: user.email)

    assert_changes ->{ user.reload.confirmed? }, from: false, to: true do
      with_last_email do |mail|
        visit Capybara.string(mail.body.to_s).find_link("Confirm my account")[:href]
        assert_current_path new_user_session_path
        assert_no_text t("devise.confirmations.send_paranoid_instructions")
        assert_text t("devise.confirmations.confirmed")
      end
    end
  end

  test 'show profile' do
    sign_in user: users.select(&:admin?).select(&:confirmed?).sample
    click_on t("users.navigation")
    within all('tr').drop(1).sample do |tr|
      email = first(:link).text
      click_on email
      assert_current_path user_path(User.find_by_email!(email))
    end
  end

  test 'disguise' do
    user = users.select(&:admin?).select(&:confirmed?).sample
    sign_in user: user

    click_on t("users.navigation")
    link = all(:link_or_button, text: t("users.index.disguise")).sample
    email = link.ancestor('tr').first(:link)[:text]
    link.click
    assert_current_path units_path
    assert_link email

    click_on t("layouts.application.revert")
    assert_current_path users_path
    assert_link user.email
  end

  test 'disguise fails for admin when disallowed' do
    user = users.select(&:admin?).select(&:confirmed?).sample
    sign_in user: user

    click_on t("users.navigation")
    text = t("users.index.disguise")
    # Pick row without 'disguise' button
    undisguisable = all(:xpath, "//tbody//tr[not(descendant::*[contains(text(),\"#{text}\")])]")
    user_email = undisguisable.sample.first(:link).text
    visit disguise_user_path(User.find_by_email!(user_email))
    assert_title 'The change you wanted was rejected (422)'
  end

  test 'disguise forbidden for non admin' do
    sign_in user: users.reject(&:admin?).select(&:confirmed?).sample
    visit disguise_user_path(User.all.sample)
    assert_title 'Access is forbidden to this page (403)'
  end

  test 'delete profile' do
    user = sign_in
    # TODO: remove condition after root_url changed to different path than
    # profile in routes.rb
    unless has_current_path?(edit_user_registration_path)
      first(:link_or_button, user.email).click
    end
    assert_difference ->{ User.count }, -1 do
      accept_confirm { click_on t("users.profiles.edit.delete") }
      assert_current_path new_user_session_path
    end
    assert_text t("devise.registrations.destroyed")
  end

  test 'index forbidden for non admin' do
    sign_in user: users.reject(&:admin?).select(&:confirmed?).sample
    visit users_path
    assert_title "Access is forbidden to this page (403)"
  end

  test 'update profile' do
    # TODO
  end

  test 'update status' do
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

  test 'update status fails for admin when disallowed' do
    sign_in user: users.select(&:admin?).select(&:confirmed?).sample
    visit users_path

    within all(:xpath, "//tbody//tr[not(descendant::select)]").sample do |tr|
      user = User.find_by_email!(first(:link).text)
      inject_button_to find('td', exact_text: user.status), "update status",
        user_path(user), method: :patch,
        params: {user: {status: User.statuses.keys.sample}}, data: {turbo: false}
      click_on "update status"
    end
    assert_title 'The change you wanted was rejected (422)'
  end

  test 'update status forbidden for non admin' do
    sign_in user: users.reject(&:admin?).select(&:confirmed?).sample
    visit units_path
    inject_button_to find('body'), "update status", user_path(User.all.sample),
      method: :patch, params: {user: {status: User.statuses.keys.sample}}
    click_on "update status"
    assert_text t('actioncontroller.exceptions.status.forbidden')
  end
end
