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
      flash.now[:notice] = t(".success")
      run_and_render :index
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @unit.update(unit_params.except(:base_id))
      flash.now[:notice] = t(".success")
      run_and_render :index
    else
      render :edit
    end
  end

  def rebase
    permitted = params.require(:unit).permit(:base_id)
    if permitted[:base_id].blank? && @unit.multiplier != 1
      permitted.merge!(multiplier: 1)
      flash.now[:notice] = t(".multiplier_reset", symbol: @unit.symbol)
    end

    run_and_render :index if @unit.update(permitted)
  end

  def destroy
    if @unit.destroy
      flash.now[:notice] = t(".success")
    end
    run_and_render :index
  end

  private

  def unit_params
    params.require(:unit).permit(:symbol, :name, :base_id, :multiplier)
  end

  def find_unit
    @unit = Unit.find_by!(id: params[:id], user: current_user)
  end
end
