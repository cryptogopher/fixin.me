class Unit < ApplicationRecord
  attribute :multiplier, default: 1

  belongs_to :user, optional: true
  # TODO: validate base.user == user
  belongs_to :base, optional: true, class_name: "Unit"

  validates :symbol, presence: true, uniqueness: {scope: :user_id},
    length: {maximum: columns_hash['symbol'].limit}
  validates :name, length: {maximum: columns_hash['name'].limit}
  validates :multiplier, numericality: {equal_to: 1}, unless: :base
  validates :multiplier, numericality: {other_than: 0}, if: :base
  validate if: ->{ base&.base.present? } do
    errors.add(:base, :multilevel_nesting)
  end

  scope :defaults, ->{ where(user: nil) }
  scope :ordered, ->{
    parent_symbol = Arel::Nodes::NamedFunction.new(
                      'COALESCE',
                      [Arel::Table.new(:bases_units)[:symbol], arel_table[:symbol]]
                    )
    left_outer_joins(:base).order(parent_symbol, arel_table[:base_id].asc.nulls_first, :multiplier)
  }

  before_destroy do
    # TODO: disallow destruction if any object depends on this unit
    nil
  end
end
