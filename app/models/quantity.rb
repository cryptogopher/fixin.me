class Quantity < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :parent, optional: true, class_name: "Quantity"
  has_many :subquantities, class_name: "Quantity", inverse_of: :parent,
    dependent: :restrict_with_error

  validate if: ->{ parent.present? } do
    errors.add(:parent, :user_mismatch) unless user == parent.user
  end
  validates :name, presence: true, length: {maximum: type_for_attribute(:name).limit}
  validates :description, length: {maximum: type_for_attribute(:description).limit}

  scope :defaults, ->{ where(user: nil) }
  scope :ordered, ->{
    left_outer_joins(:parent).order(ordering)
  }

  def self.ordering
    [arel_table.coalesce(Arel::Table.new(:parents_quantities)[:name], arel_table[:name]),
     arel_table[:parent_id].not_eq(nil),
     :name]
  end

  def to_s
    name
  end

  def movable?
    subunits.empty?
  end

  def default?
    parent_id.nil?
  end
end
