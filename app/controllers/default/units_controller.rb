class Default::UnitsController < ApplicationController
  navigation_tab :units

  before_action -> { find_unit(current_user) }, only: :export
  before_action -> { find_unit(nil) }, only: [:import, :destroy]

  before_action except: :index do
    case action_name.to_sym
    when :import, :import_all
      raise AccessForbidden unless current_user.at_least(:active)
    else
      raise AccessForbidden unless current_user.at_least(:admin)
    end
  end

  def index
    @units = current_user.units.defaults_diff.includes(:base).ordered
  end

  def import
    current_user.units
      .find_or_initialize_by(symbol: @unit.symbol)
      .update!(base: @base, **@unit.slice(:name, :multiplier))
    run_and_render :index
  end

  def import_all
    # From defaults_diff return not only portability, but reason for not being
    # portable: missing_base and nesting_too_deep. Add portable and
    # missing_base, if possible in one query
  end

  def export
  end

  def destroy
  end

  private

  def find_unit(user)
    @unit = Unit.find_by!(id: params[:id], user: user)
    @base = Unit.find_by!(symbol: @unit.base.symbol, user: user ? nil : current_user) if @unit.base
  end
end
