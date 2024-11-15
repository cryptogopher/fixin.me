class Default::UnitsController < ApplicationController
  navigation_tab :units

  before_action :find_unit, only: [:import, :export, :destroy]

  before_action except: :index do
    case action_name.to_sym
    when :import, :import_all
      raise AccessForbidden unless current_user.at_least(:active)
    else
      raise AccessForbidden unless current_user.at_least(:admin)
    end
  end

  def index
    @units = current_user.units.defaults_diff.includes(:base).ordered
  end

  def import
  end

  def import_all
  end

  def export
  end

  def destroy
  end
end
