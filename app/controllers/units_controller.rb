class UnitsController < ApplicationController
  before_action :find_unit, only: [:edit, :update, :destroy]

  before_action except: :index do
    raise AccessForbidden unless current_user.at_least(:active)
  end
  before_action only: [:edit, :update, :destroy] do
    raise ArgumentError unless current_user == @unit.user
  end

  def index
    @units = current_user.units
  end

  def new
    @unit = current_user.units.new
  end

  def create
    @unit = current_user.units.new(unit_params)
    if @unit.save
      flash[:notice] = t(".success")
      @units = current_user.units
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @unit.update(unit_params)
      flash[:notice] = t(".success")
      redirect_to units_url
    else
      render :edit
    end
  end

  def destroy
    if @unit.destroy
      flash[:notice] = t(".success")
    end
    redirect_to units_url
  end

  private

  def unit_params
    params.require(:unit).permit(:symbol, :name, :base_id, :multiplier)
  end

  def find_unit
    @unit = Unit.find(params[:id])
  end
end
