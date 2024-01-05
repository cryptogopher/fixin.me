class Unit < ApplicationRecord
  attribute :multiplier, default: 1

  belongs_to :user, optional: true
  belongs_to :base, optional: true, class_name: "Unit"

  validates :symbol, presence: true, uniqueness: {scope: :user_id},
    length: {maximum: columns_hash['symbol'].limit}
  validates :name, length: {maximum: columns_hash['name'].limit}
  validates :multiplier, numericality: {equal_to: 1}, unless: :base
  validates :multiplier, numericality: {other_than: 1}, if: :base
  validate if: -> { base.present? } do
    errors.add(:base, :only_top_level_base_units) unless base.base.nil?
  end

  acts_as_nested_set parent_column: :base_id, scope: :user, dependent: :destroy,
    order_column: :multiplier

  scope :defaults, -> { where(user: nil) }

  after_save if: :base do |record|
    record.move_to_ordered_child_of(record.base, :multiplier)
  end

  before_destroy do
    # TODO: disallow destruction if any object depends on this unit
    nil
  end
end
