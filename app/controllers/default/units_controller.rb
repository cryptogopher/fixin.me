class Default::UnitsController < ApplicationController
  navigation_tab :units

  before_action except: :index do
    raise AccessForbidden unless current_user.at_least(:admin)
  end

  def index
    @units = current_user.units.defaults_diff
  end
end
