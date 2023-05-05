class UsersController < ApplicationController
  before_action :find_user, only: [:show]
  before_action do
    raise AccessForbidden unless current_user.at_least(:admin)
  end

  def index
    @users = User.all
  end

  def show
  end

  # TODO: add #update to change user status
  # TODO: add #become/#revert to change to user view

  # NOTE: limited actions availabe to :admin by design. Users are meant to
  # manage their accounts by themselves through registrations. In future :admin
  # may be allowed to sing-in as user and make changes there.

  private

  def find_user
    @user = User.find(params[:id])
  end
end
