class MeasurementsController < ApplicationController
  before_action :find_quantity, only: [:new]

  def index
    @quantities = current_user.quantities.ordered
  end

  def new
    readouts_params = params.permit(user: [readouts_attributes: Readout::ATTRIBUTES])
    build_attrs = readouts_params.dig(:user, :readouts_attributes)&.values
    prev_readouts = build_attrs ? Array(current_user.readouts.build(build_attrs)) : []

    quantities =
      case params[:scope]
      when 'children'
        @quantity.subquantities
      when 'subtree'
        @quantity.progenies
      else
        [@quantity]
      end
    quantities -= prev_readouts.map(&:quantity)
    new_readouts = current_user.readouts.build(quantities.map { |q| {quantity: q} })
    @readouts = prev_readouts + new_readouts

    @ancestor_fullname = current_user.quantities
      .common_ancestors(@readouts.map { |r| r.quantity.parent_id }).first&.fullname || ''
    @units = current_user.units.ordered
  end

  def create
  end

  def destroy
  end

  private

  def find_quantity
    @quantity = current_user.quantities.find_by!(id: params[:id])
  end
end
