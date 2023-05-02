class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  class AccessForbidden < StandardError
  end

  protected

  def after_sign_in_path_for(scope)
    if current_user.at_least(:admin)
      users_path
    else
      edit_user_registration_path
    end
  end

  def after_sign_out_path_for(scope)
    new_user_session_path
  end
end
