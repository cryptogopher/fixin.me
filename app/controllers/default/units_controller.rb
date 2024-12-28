class Default::UnitsController < ApplicationController
  navigation_tab :units

  before_action :find_unit, only: :export
  before_action :find_unit_default, only: [:import, :destroy]

  before_action only: :import do
    raise AccessForbidden unless current_user.at_least(:active)
  end
  before_action except: [:index, :import] do
    raise AccessForbidden unless current_user.at_least(:admin)
  end

  def index
    @units = current_user.units.defaults_diff.includes(:base).includes(:subunits).ordered
  end

  def import
    @unit.port!(current_user)
    flash.now[:notice] = t('.success', unit: @unit)
  ensure
    run_and_render :index
  end

  #def import_all
    # From defaults_diff return not only portability, but reason for not being
    # portable: missing_base and nesting_too_deep. Add portable and
    # missing_base, if possible in one query
  #end

  def export
    @unit.port!(nil)
    flash.now[:notice] = t('.success', unit: @unit)
  ensure
    run_and_render :index
  end

  def destroy
    @unit.destroy!
    flash.now[:notice] = t('.success', unit: @unit)
  ensure
    run_and_render :index
  end

  private

  def find_unit
    @unit = Unit.find_by!(id: params[:id], user: current_user)
  end

  def find_unit_default
    @unit = Unit.find_by!(id: params[:id], user: nil)
  end
end
