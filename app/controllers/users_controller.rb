class UsersController < ApplicationController
  helper_method :allow_disguise?

  before_action :find_user, only: [:show, :update, :disguise]

  before_action only: :revert do
    raise AccessForbidden unless current_user_disguised?
  end
  before_action except: :revert do
    raise AccessForbidden unless current_user.at_least(:admin)
  end

  def index
    @users = User.all
  end

  def show
  end

  def update
    raise ParameterInvalid if current_user == @user
    @user.update!(params.require(:user).permit(:status))
  end

  def disguise
    raise ParameterInvalid unless allow_disguise?(@user)
    session[:revert_to_id] = current_user.id
    bypass_sign_in(@user)
    # TODO: add flash with disguised username?
    redirect_to root_url
  end

  def revert
    @user = User.find(session.delete(:revert_to_id))
    bypass_sign_in(@user)
    redirect_to users_url
  end

  # NOTE: limited actions availabe to :admin by design. Users are meant to
  # manage their accounts by themselves through registrations. :admin
  # is allowed to sign-in (disguise) as user and make changes from there.

  protected

  def allow_disguise?(user)
    user&.confirmed? && (user != current_user) && !current_user_disguised?
  end

  private

  def find_user
    @user = User.find(params[:id])
  end
end
