class MeasurementsController < ApplicationController
  def index
    @quantities = current_user.quantities.ordered
  end

  def new
  end

  def create
  end

  def destroy
  end
end
