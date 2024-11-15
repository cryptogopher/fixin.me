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
    bases_units = arel_table.alias('bases_units')
    other_units = arel_table.alias('other_units')
    other_bases_units = arel_table.alias('other_bases_units')
    parent_units = arel_table.alias('parent_units')

    with(units: self.with_defaults).unscope(where: :user_id).left_joins(:base)
      .where.not(
        Arel::SelectManager.new.project(1).from(other_units)
          .outer_join(other_bases_units)
          .on(other_units[:base_id].eq(other_bases_units[:id]))
          .where(
            other_bases_units[:symbol].eq(bases_units[:symbol])
              .and(other_units[:symbol].eq(arel_table[:symbol]))
              .and(other_units[:user_id].not_eq(arel_table[:user_id]))
          ).exists
      ).joins(
        arel_table.create_join(parent_units,
                               arel_table.create_on(
                                 parent_units[:symbol].eq(bases_units[:symbol])
                                   .and(parent_units[:user_id].not_eq(bases_units[:user_id]))
                               ),
                               Arel::Nodes::OuterJoin)
      ).select(
        arel_table[Arel.star],
        Arel::Nodes::IsNotDistinctFrom.new(parent_units[:symbol], bases_units[:symbol])
          .as('portable')
      )
      # complete portability check with children
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

  def exportable?
    !default? && (base.nil? || base.default?)
  end
end
