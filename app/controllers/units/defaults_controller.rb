class Units::DefaultsController < ApplicationController
  navigation_tab :units

  before_action except: :index do
    raise AccessForbidden unless current_user.at_least(:admin)
  end

  def index
  end
end
