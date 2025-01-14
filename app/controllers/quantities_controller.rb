class QuantitiesController < ApplicationController
  before_action only: :new do
    find_quantity if params[:id].present?
  end
  before_action :find_quantity, only: [:edit, :update, :reparent, :destroy]

  before_action except: :index do
    raise AccessForbidden unless current_user.at_least(:active)
  end

  def index
    @quantities = current_user.quantities.ordered.includes(:parent).includes(:subquantities)
  end

  def new
    @quantity = current_user.quantities.new(parent: @quantity)
  end

  def create
    @quantity = current_user.quantities.new(quantity_params)
    if @quantity.save
      @before = @quantity.successive
      @ancestors = @quantity.ancestors
      flash.now[:notice] = t('.success', quantity: @quantity)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @quantity.update(quantity_params.except(:parent_id))
      @ancestors = @quantity.ancestors
      flash.now[:notice] = t('.success', quantity: @quantity)
    else
      render :edit
    end
  end

  def reparent
    permitted = params.require(:quantity).permit(:parent_id)
    @previous_ancestors = @quantity.ancestors

    @quantity.update!(permitted)

    @ancestors = @quantity.ancestors
    @quantity.depth = @ancestors.length
    @self_and_progenies = @quantity.progenies.unshift(@quantity)
    @before = @self_and_progenies.last.successive
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
