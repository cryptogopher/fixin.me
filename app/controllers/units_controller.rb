class UnitsController < ApplicationController
  before_action only: :new do
    find_unit if params[:id].present?
  end
  before_action :find_unit, only: [:edit, :update, :rebase, :destroy]

  before_action except: :index do
    raise AccessForbidden unless current_user.at_least(:active)
  end

  def index
    @units = current_user.units.ordered.includes(:base, :subunits)
  end

  def new
    @unit = current_user.units.new(base: @unit)
  end

  def create
    @unit = current_user.units.new(params.expect(Unit::ATTRIBUTES))
    if @unit.save
      @before = @unit.successive
      flash.now[:notice] = t('.success', unit: @unit)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @unit.update(params.except(:base_id).expect(Unit::ATTRIBUTES))
      flash.now[:notice] = t('.success', unit: @unit)
    else
      render :edit
    end
  end

  # TODO: Avoid double table width change by first un-hiding table header,
  # then displaying index, e.g. by re-displaying header in index
  def rebase
    unit_params = params.expect(unit: :base_id)
    unit_params.merge!(multiplier: 1.0) if unit_params[:base_id].blank?

    @previous_base = @unit.base
    @unit.update!(unit_params)

    @before = @unit.successive
    if @unit.multiplier_previously_changed?
      flash.now[:notice] = t(".multiplier_reset", unit: @unit)
    end
  end

  def destroy
    @unit.destroy!
    flash.now[:notice] = t('.success', unit: @unit)
  end

  private

  def find_unit
    @unit = current_user.units.find_by!(id: params[:id])
  end
end
