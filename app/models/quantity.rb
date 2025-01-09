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
    numbered = Arel::Table.new('numbered')
    Quantity.with(numbered: numbered(:parent_id, :name)).with_recursive(quantities: [
      Arel::SelectManager.new.project(
        numbered[Arel.star],
        numbered.cast(numbered[:child_number], 'BINARY').as('path'),
        Arel::Nodes.build_quoted(0).as('depth')
      ).from(numbered).where(numbered[:parent_id].eq(nil)),
      Arel::SelectManager.new.project(
        numbered[Arel.star],
        arel_table[:path].concat(numbered[:child_number]),
        arel_table[:depth] + 1
      ).from(numbered).join(arel_table).on(numbered[:parent_id].eq(arel_table[:id]))
    ]).select(arel_table[Arel.star]).from(arel_table).order(arel_table[:path])
  }

  # TODO: extract named functions to custom Arel extension
  # https://gist.github.com/ProGM/c6df08da14708dcc28b5ca325df37ceb#extending-arel
  scope :numbered, ->(parent_column, order_column){
    select(
      arel_table[Arel.star],
      Arel::Nodes::NamedFunction.new(
        'LPAD',
        [
          Arel::Nodes::NamedFunction.new('ROW_NUMBER', [])
            .over(Arel::Nodes::Window.new.partition(parent_column).order(order_column)),
          Arel::SelectManager.new.project(
            Arel::Nodes::NamedFunction.new('LENGTH', [Arel.star.count])])
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

  def successive
    quantities = Quantity.arel_table
    Quantity.with(
      quantities: user.quantities.ordered.select(
        Arel::Nodes::NamedFunction.new('LAG', [quantities[:id]]).over.as('lag_id')
      )
    ).where(quantities[:lag_id].eq(id)).first
  end
end
