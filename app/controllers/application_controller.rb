class ApplicationController < ActionController::Base
  helper_method :current_user_at_least

  before_action :authenticate_user!

  class AccessForbidden < StandardError
  end

  def current_user_at_least(status)
    User.statuses[current_user.status] >= User.statuses[status]
  end

  protected

  def after_sign_out_path_for(scope)
    new_user_session_path
  end
end
