class UsersController < ApplicationController
  before_action :find_user, only: [:destroy]
  before_action do
    raise AccessForbidden unless current_user.at_least(:admin)
  end

  def index
    @users = User.all
  end

  # TODO: add #show and #update to change user status
  # TODO: remove admin dependent fields from registrations#edit and move them to
  # #show

  # NOTE: limited actions availabe to :admin by design. Users are meant to
  # manage their accounts by themselves through registrations. In future :admin
  # may be allowed to sing-in as user and make changes there.

  private

  def find_user
    @user = User.find(params[:id])
  end
end
