class Quantity < ApplicationRecord
  ATTRIBUTES = [:name, :description, :parent_id]

  belongs_to :user, optional: true
  belongs_to :parent, optional: true, class_name: "Quantity"
  has_many :subquantities, class_name: "Quantity", inverse_of: :parent,
    dependent: :restrict_with_error

  validate if: ->{ parent.present? } do
    errors.add(:parent, :user_mismatch) unless user == parent.user
  end
  validates :name, presence: true, uniqueness: {scope: [:user_id, :parent_id]},
    length: {maximum: type_for_attribute(:name).limit}
  validates :description, length: {maximum: type_for_attribute(:description).limit}

  # Not persisted attribute
  attribute :depth, :integer

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
            Arel::Nodes::NamedFunction.new('LENGTH', [Arel.star.count])
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
    subquantities.empty?
  end

  def default?
    parent_id.nil?
  end

  # Return: self, ancestors and successive record in order of appearance,
  # including :depth attribute. Used for partial view reload.
  def successive
    quantities = Quantity.arel_table

    Quantity.with(
      quantities: user.quantities.ordered.select(
        Arel::Nodes::NamedFunction.new('LAG', [quantities[:id]]).over.as('lag_id')
      )
    ).where(quantities[:lag_id].eq(id)).first
  end

  # Return: ancestors of (possibly destroyed) self; include depths, also on
  # self (unless destroyed)
  def ancestors
    quantities = Quantity.arel_table
    ancestors = Arel::Table.new('ancestors')

    # Ancestors are listed bottom up, so it's impossible to know depth at the
    # start. Start with depth = 0 and count downwards, then adjust by the
    # amount needed to set biggest negative depth to 0.
    Quantity.with_recursive(ancestors: [
      user.quantities.select(quantities[Arel.star], Arel::Nodes.build_quoted(0).as('depth'))
        .where(id: parent_id),
      user.quantities.select(quantities[Arel.star], ancestors[:depth] - 1)
        .joins(quantities.create_join(
          ancestors, quantities.create_on(quantities[:id].eq(ancestors[:parent_id]))
        ))
    ]).select(ancestors[Arel.star]).from(ancestors).to_a.then do |records|
      records.map(&:depth).min&.abs.then do |maxdepth|
        self.depth = (maxdepth || -1) + 1 unless frozen?
        records.each { |r| r.depth += maxdepth }
      end
    end
  end
end
