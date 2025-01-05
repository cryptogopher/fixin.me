class QuantitiesController < ApplicationController
  before_action except: :index do
    raise AccessForbidden unless current_user.at_least(:active)
  end

  def index
    @quantities = current_user.quantities.includes(:parent).includes(:subquantities).ordered
  end
end
