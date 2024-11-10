class Unit < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :base, optional: true, class_name: "Unit"
  has_many :subunits, class_name: "Unit", dependent: :restrict_with_error, inverse_of: :base

  validate if: ->{ base.present? } do
    errors.add(:base, :user_mismatch) unless user == base.user
    errors.add(:base, :multilevel_nesting) if base.base.present?
  end
  validates :symbol, presence: true, uniqueness: {scope: :user_id},
    length: {maximum: columns_hash['symbol'].limit}
  validates :name, length: {maximum: columns_hash['name'].limit}
  validates :multiplier, numericality: {equal_to: 1}, unless: :base
  validates :multiplier, numericality: {other_than: 0}, if: :base

  scope :defaults, ->{ where(user: nil) }
  scope :with_defaults, ->{ self.or(Unit.where(user: nil)) }
  scope :defaults_diff, ->{
    other_units = Unit.arel_table.alias('other_units')
    other_bases_units = Unit.arel_table.alias('other_bases_units')
    constraints = other_bases_units[:id].eq(other_units[:base_id])
      .and(other_bases_units[:symbol].eq(Arel::Table.new(:bases_units)[:symbol]))
      .and(other_units[:symbol].eq(arel_table[:symbol]))
      .and(other_units[:user_id].not_eq(arel_table[:user_id]))

    with_defaults
      .joins(
        arel_table.create_join(
          arel_table.grouping([other_units, other_bases_units]),
          arel_table.create_on(constraints),
          Arel::Nodes::OuterJoin
        ).to_sql
      )
      .where({other_units: {id: nil}})
  }
  scope :ordered, ->{
    left_outer_joins(:base)
      .order(arel_table.coalesce(Arel::Table.new(:bases_units)[:symbol], arel_table[:symbol]),
             arel_table[:base_id].asc.nulls_first, :multiplier, :symbol)
  }

  before_destroy do
    # TODO: disallow destruction if any object depends on this unit
    nil
  end

  def movable?
    subunits.empty?
  end

  def default?
    user.nil?
  end
end
