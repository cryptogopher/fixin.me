class MeasurementsController < ApplicationController
  before_action :find_quantity, only: [:new, :discard]
  before_action :find_prev_quantities, only: [:new, :discard]

  def index
    @quantities = current_user.quantities.ordered
  end

  def new
    quantities =
      case params[:scope]
      when 'children'
        @quantity.subquantities
      when 'subtree'
        @quantity.progenies
      else
        [@quantity]
      end
    quantities -= @prev_quantities
    @readouts = current_user.readouts.build(quantities.map { |q| {quantity: q} })

    @units = current_user.units.ordered

    all_quantities = @prev_quantities + quantities
    @common_ancestor = current_user.quantities
      .common_ancestors(all_quantities.map(&:parent_id)).first
  end

  def discard
    @prev_quantities -= [@quantity]

    @common_ancestor = current_user.quantities
      .common_ancestors(@prev_quantities.map(&:parent_id)).first
  end

  def create
  end

  def destroy
  end

  private

  def find_quantity
    @quantity = current_user.quantities.find_by!(id: params[:id])
  end

  def find_prev_quantities
    prev_quantity_ids = params[:readouts]&.map { |r| r[:quantity_id] } || []
    @prev_quantities = current_user.quantities.find(prev_quantity_ids)
  end
end
