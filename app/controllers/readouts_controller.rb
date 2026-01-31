class ReadoutsController < ApplicationController
  before_action :find_quantities, only: [:new]
  before_action :find_quantity, only: [:discard]
  before_action :find_prev_quantities, only: [:new, :discard]

  def new
    @quantities -= @prev_quantities
    # TODO: raise ParameterInvalid if new_quantities.empty?
    @readouts = current_user.readouts.build(@quantities.map { |q| {quantity: q} })

    @user_units = current_user.units.ordered

    quantities = @prev_quantities + @quantities
    @superquantity = current_user.quantities
      .common_ancestors(quantities.map(&:parent_id)).first
  end

  def discard
    @prev_quantities -= [@quantity]

    @superquantity = current_user.quantities
      .common_ancestors(@prev_quantities.map(&:parent_id)).first
  end

  private

  def find_quantities
    @quantities = current_user.quantities.find(params[:quantity])
  end

  def find_quantity
    @quantity = current_user.quantities.find_by!(id: params[:id])
  end

  def find_prev_quantities
    prev_quantity_ids = params[:readouts]&.map { |r| r[:quantity_id] } || []
    @prev_quantities = current_user.quantities.find(prev_quantity_ids)
  end
end
