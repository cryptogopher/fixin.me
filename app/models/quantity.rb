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
    cte = Arel::Table.new('cte')
    numbered = Arel::Table.new('numbered')
    Quantity.with(numbered: numbered(:parent_id, :name)).with_recursive(
      cte:
      [
        Arel::SelectManager.new.project(
          numbered[Arel.star],
          numbered.cast(numbered[:child_number], 'BINARY').as('path')
        ).from(numbered).where(numbered[:parent_id].eq(nil)),
        Arel::SelectManager.new.project(
          numbered[Arel.star],
          cte[:path].concat(numbered[:child_number])
        ).from(numbered).join(cte).on(numbered[:parent_id].eq(cte[:id]))
      ]
    ).select(cte[Arel.star]).from(cte).order(cte[:path])
  }

  scope :numbered, ->(parent_column, order_column){
    select(
      arel_table[Arel.star],
      Arel::Nodes::NamedFunction.new(
        'LPAD',
        [
          Arel::Nodes::NamedFunction.new(
            'ROW_NUMBER', []
          ).over(
            Arel::Nodes::Window.new.partition(parent_column).order(order_column)
          ),
          Arel::SelectManager.new.project(
            Arel::Nodes::NamedFunction.new(
              'LENGTH', [Arel::Nodes::NamedFunction.new('COUNT', [Arel.star])]
            )
          ),
          Arel::Nodes.build_quoted('0')
        ],
      ).as('child_number')
    )
  }

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
