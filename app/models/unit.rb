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
    sub_units = arel_table.alias('sub_units')

    Unit.with(units: self.with_defaults).left_joins(:base)
      # Exclude Units that are/have default counterpart
      .where.not(
        Arel::SelectManager.new.project(1).from(other_units)
          .outer_join(other_bases_units)
          .on(other_units[:base_id].eq(other_bases_units[:id]))
          .where(
            other_bases_units[:symbol].is_not_distinct_from(bases_units[:symbol])
              .and(other_units[:symbol].eq(arel_table[:symbol]))
              .and(other_units[:user_id].is_distinct_from(arel_table[:user_id]))
          ).exists
      # Decide if Unit can be im-/exported based on existing hierarchy:
      # * same base unit symbol has to exist
      # * unit with subunits can only be ported to root
      ).select(
        arel_table[Arel.star],
        arel_table[:base_id].eq(nil).or(
          (
            Arel::SelectManager.new.project(1).from(other_units)
              .join(sub_units).on(other_units[:id].eq(sub_units[:base_id]))
              .where(
                other_units[:symbol].eq(arel_table[:symbol])
                  .and(other_units[:user_id].is_distinct_from(arel_table[:user_id]))
              )
              .exists.not
          ).and(
            Arel::SelectManager.new.project(1).from(other_bases_units)
              .where(
                other_bases_units[:symbol].is_not_distinct_from(bases_units[:symbol])
                  .and(other_bases_units[:user_id].is_distinct_from(bases_units[:user_id]))
              )
              .exists
          )
        ).as('portable')
      )
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
    user_id.nil?
  end

  def exportable?
    !default? && (base.nil? || base.default?)
  end
end
