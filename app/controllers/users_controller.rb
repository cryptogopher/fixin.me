class UsersController < ApplicationController
  helper_method :allow_disguise?

  before_action :find_user, only: [:show, :update, :disguise]
  before_action except: :revert do
    raise AccessForbidden unless current_user.at_least(:admin)
  end
  before_action only: :revert do
    raise AccessForbidden unless current_user_disguised?
  end

  def index
    @users = User.all
  end

  def show
  end

  def update
    @user.update!(params.require(:user).permit(:status))
  end

  def disguise
    raise ArgumentError unless allow_disguise?(@user)
    session[:revert_to_id] = current_user.id
    bypass_sign_in(@user)
    redirect_to root_url
  end

  def revert
    @user = User.find(session.delete(:revert_to_id))
    bypass_sign_in(@user)
    redirect_to users_url
  end

  # NOTE: limited actions availabe to :admin by design. Users are meant to
  # manage their accounts by themselves through registrations. In future :admin
  # may be allowed to sing-in as user and make changes there.

  protected

  def allow_disguise?(user)
    user&.confirmed? && (user != current_user) && !current_user_disguised?
  end

  private

  def find_user
    @user = User.find(params[:id])
  end

end
