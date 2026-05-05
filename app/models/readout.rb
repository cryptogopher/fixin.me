class Readout < ApplicationRecord
  ATTRIBUTES = [:quantity_id, :value, :unit_id]

  belongs_to :user
  belongs_to :quantity
  belongs_to :unit

  # TODO: validate quantity.user_id == unit.user_id != NULL
end
