class UnitsController < ApplicationController
  before_action only: :new do
    find_unit if params[:id].present?
  end
  before_action :find_unit, only: [:edit, :update, :rebase, :destroy]

  before_action except: :index do
    raise AccessForbidden unless current_user.at_least(:active)
  end

  def index
    @units = current_user.units.includes(:subunits).ordered
  end

  def new
    @unit = current_user.units.new(base: @unit)
  end

  def create
    @unit = current_user.units.new(unit_params)
    if @unit.save
      flash.now[:notice] = t('.success', unit: @unit)
      run_and_render :index
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @unit.update(unit_params.except(:base_id))
      flash.now[:notice] = t('.success', unit: @unit)
      run_and_render :index
    else
      render :edit
    end
  end

  def rebase
    permitted = params.require(:unit).permit(:base_id)
    permitted.merge!(multiplier: 1) if permitted[:base_id].blank? && @unit.multiplier != 1

    @unit.update!(permitted)

    if @unit.multiplier_previously_changed?
      flash.now[:notice] = t(".multiplier_reset", unit: @unit)
    end
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

  def unit_params
    params.require(:unit).permit(Unit::ATTRIBUTES)
  end

  def find_unit
    @unit = Unit.find_by!(id: params[:id], user: current_user)
  end
end
