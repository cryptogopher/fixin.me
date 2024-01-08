class Unit < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :base, optional: true, class_name: "Unit"

  validates :symbol, presence: true, uniqueness: {scope: :user_id},
    length: {maximum: columns_hash['symbol'].limit}
  validates :name, length: {maximum: columns_hash['name'].limit}
  validates :multiplier, absence: true, unless: :base
  validates :multiplier, presence: true, numericality: {other_than: 0}, if: :base
  validate if: ->{ base&.base.present? } do
    errors.add(:base, :multilevel_nesting)
  end

  acts_as_nested_set parent_column: :base_id, scope: :user, dependent: :destroy,
    order_column: :multiplier

  scope :defaults, ->{ where(user: nil) }
  scope :ordered, ->{
    parent_symbol = Arel::Nodes::NamedFunction.new(
                      'COALESCE',
                      [Arel::Table.new(:bases_units)[:symbol], Unit.arel_table[:symbol]]
                    )
    left_outer_joins(:base).order(parent_symbol, :multiplier)
  }

  before_destroy do
    # TODO: disallow destruction if any object depends on this unit
    nil
  end
end
