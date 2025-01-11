class QuantitiesController < ApplicationController
  before_action only: :new do
    find_quantity if params[:id].present?
  end
  before_action :find_quantity, only: [:edit, :update, :rebase, :destroy]

  before_action except: :index do
    raise AccessForbidden unless current_user.at_least(:active)
  end

  def index
    @quantities = current_user.quantities.includes(:parent).includes(:subquantities).ordered
  end

  def new
    @quantity = current_user.quantities.new(parent: @quantity)
  end

  def create
    @quantity = current_user.quantities.new(quantity_params)
    if @quantity.save
      @before, @quantity, @ancestors = @quantity.succ_and_ancestors
      flash.now[:notice] = t('.success', quantity: @quantity)
    else
      render :new
    end
  end

  def destroy
    @quantity.destroy!
    @ancestors = @quantity.ancestors
    flash.now[:notice] = t('.success', quantity: @quantity)
  end

  private

  def quantity_params
    params.require(:quantity).permit(Quantity::ATTRIBUTES)
  end

  def find_quantity
    @quantity = Quantity.find_by!(id: params[:id], user: current_user)
  end
end
