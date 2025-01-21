class Readout < ApplicationRecord
  belongs_to :user
  belongs_to :quantity
  belongs_to :unit
end
