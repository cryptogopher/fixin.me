class MeasurementsController < ApplicationController
  def index
  end

  def new
    @quantities = current_user.quantities.ordered
  end

  def create
  end

  def destroy
  end
end
