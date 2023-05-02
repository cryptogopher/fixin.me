class UsersController < ApplicationController
  before_action :find_user, only: [:destroy]
  before_action do
    raise AccessForbidden unless (current_user == @user) || current_user.at_least(:admin)
  end

  def index
    @users = User.all
  end

  def destroy
    @user.destroy
    redirect_to action: :index, notice: t(".success")
  end

  private

  def find_user
    @user = User.find(params[:id])
  end
end
