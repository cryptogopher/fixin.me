class MeasurementsController < ApplicationController
  def index
    @measurements = []
    #@measurements = current_user.units.ordered.includes(:base, :subunits)
  end

  def new
    @quantities = current_user.quantities.ordered
  end

  def create
  end

  def destroy
  end
end
