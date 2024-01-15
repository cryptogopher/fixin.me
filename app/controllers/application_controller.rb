class ApplicationController < ActionController::Base
  helper_method :current_user_disguised?

  before_action :authenticate_user!

  class AccessForbidden < StandardError; end
  class ParameterInvalid < StandardError; end

  # Exceptions are handled depending on request format:
  # * HTML is handled by PublicExceptions, resulting in display of
  #   'public/<status-code>.html' template.
  # * TURBO_STREAM is handled by method specified below, which writes flash
  #   message and forces redirect to referer - to display flash and make page
  #   content consistent with database (which may or may not have been
  #   modified before exception).
  #   This requires referer to be available in TURBO_STREAM format. Otherwise
  #   Turbo will reload 2nd time with HTML format and flashes will be lost.
  rescue_from *ActionDispatch::ExceptionWrapper.rescue_responses.keys, with: :rescue_turbo

  protected

  def current_user_disguised?
    session[:revert_to_id].present?
  end

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

  private

  def rescue_turbo(exception)
    raise unless request.format.to_sym == :turbo_stream

    message_id = ActionDispatch::ExceptionWrapper.rescue_responses[exception.class.to_s]
    flash.alert = t("actioncontroller.exceptions.status.#{message_id}")
    redirect_to request.referer
  end
end
