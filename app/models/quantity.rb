class Quantity < ApplicationRecord
  ATTRIBUTES = [:name, :description, :parent_id]
  attr_cached :depth, :pathname

  belongs_to :user, optional: true
  belongs_to :parent, optional: true, class_name: "Quantity"
  has_many :subquantities, ->{ order(:name) }, class_name: "Quantity",
    inverse_of: :parent, dependent: :restrict_with_error
  has_many :readouts, dependent: :restrict_with_error

  validate if: ->{ parent.present? } do
    errors.add(:parent, :user_mismatch) unless user_id == parent.user_id
    errors.add(:parent, :self_reference) if id == parent_id
  end
  validate if: ->{ parent.present? }, on: :update do
    # TODO: should not report error for (parent == self)
    errors.add(:parent, :descendant_reference) if ancestor_of?(parent)
  end
  validates :name, presence: true, uniqueness: {scope: [:user_id, :parent_id]},
    length: {maximum: type_for_attribute(:name).limit}
  # FIXME: length validation for :text type column is probably wrong; reported
  # limit is in bytes (at least for MySQL) and check is for #length (i.e.
  # characters); this doesn't seem to apply to :string (implemented as varchar)
  validates :description, length: {maximum: type_for_attribute(:description).limit}

  # Update :depths of progenies after parent change
  before_save if: :parent_changed? do
    self[:depth] = parent&.depth&.succ || 0
  end

  after_update if: :depth_previously_changed? do
    quantities = Quantity.arel_table
    selected = Arel::Table.new('selected')

    Quantity.with_recursive(selected: [
      quantities.project(quantities[:id].as('quantity_id'), quantities[:depth])
        .where(quantities[:id].eq(id)),
      quantities.project(quantities[:id], selected[:depth] + 1)
        .join(selected).on(selected[:quantity_id].eq(quantities[:parent_id]))
    ]).joins(:selected).update_all(depth: selected[:depth])
  end

  # Update :pathnames of progenies after parent/name change
  PATHNAME_DELIMITER = ' → '

  before_save if: -> { parent_changed? || name_changed? } do
    self[:pathname] = (parent ? parent.pathname + PATHNAME_DELIMITER : '') + self[:name]
  end

  after_update if: :pathname_previously_changed? do
    quantities = Quantity.arel_table
    selected = Arel::Table.new('selected')

    Quantity.with_recursive(selected: [
      quantities.project(quantities[:id].as('quantity_id'), quantities[:pathname])
        .where(quantities[:id].eq(id)),
      quantities.project(
        quantities[:id],
        selected[:pathname].concat(Arel::Nodes.build_quoted(PATHNAME_DELIMITER))
          .concat(quantities[:name])
      ).join(selected).on(selected[:quantity_id].eq(quantities[:parent_id]))
    ]).joins(:selected).update_all(pathname: selected[:pathname])
  end

  scope :defaults, ->{ where(user: nil) }

  # Return: ordered [sub]hierarchy
  scope :ordered, ->(**kwargs) {
    with_path(**kwargs).order(arel_table[:path])
  }

  # TODO: sort recursive CTE using ORDER BY; it's supported by SQLite, so
  # drop MySQL until it is available (?)
  # Only ORDER BY allows proper i.e. not placing limits on user data and
  # efficient with regard to paging (LIMIT/OFFSET) depth-first search.
  # Sorting based on numbering is less elegant/efficient (MySQL: ROW_NUMBER cannot
  # be used inside recursive CTE and needs separate SELECT,
  # https://bugs.mysql.com/bug.php?id=96538).
  # Sorting based on pathname requires I) padding to maximum column length or
  # II) delimiter which a) cannot be used in sorted column and b) sorts before
  # anything else (this adds complexity; NULL cannot be used when sorting).
  # Sorting based on ARRAY is only available on PostgreSQL.
  scope :with_path, ->(root: nil, include_root: true) {
    with_number = Arel::Table.new('with_number')

    self.model.with(with_number: with_number(:parent_id, :name))
      .with_recursive(arel_table.name => [
        with_number.project(
          with_number[Arel.star],
          with_number.cast(with_number[:number], 'BINARY').as('path')
        ).where(with_number[root && include_root ? :id : :parent_id].eq(root)),
        with_number.project(
          with_number[Arel.star],
          arel_table[:path].concat(with_number[:number])
        ).join(arel_table).on(with_number[:parent_id].eq(arel_table[:id]))
      ])
  }

  # TODO: extract named functions to custom Arel extension
  # NOTE: once recursive queries allow use of window functions, this scope can
  # be merged with :ordered
  # https://gist.github.com/ProGM/c6df08da14708dcc28b5ca325df37ceb#extending-arel
  scope :with_number, ->(parent_column, order_column) {
    select(
      arel_table[Arel.star],
      Arel::Nodes::NamedFunction.new(
        'LPAD',
        [
          Arel::Nodes::NamedFunction.new('ROW_NUMBER', [])
            .over(Arel::Nodes::Window.new.partition(parent_column).order(order_column)),
          Arel::SelectManager.new.project(
            Arel::Nodes::NamedFunction.new('LENGTH', [Arel.star.count])
          ).from(arel_table),
          Arel::Nodes.build_quoted('0')
        ],
      ).as('number')
    )
  }

  def to_s
    tag.pre name
  end

  def to_s_with_depth
    # em space, U+2003
    ' ' * depth + name
  end

  def destroyable?
    subquantities.empty?
  end

  def default?
    parent_id.nil?
  end

  # Common ancestors, assuming node is a descendant of itself
  scope :common_ancestors, ->(of) {
    selected = Arel::Table.new('selected')

    # Take unique IDs, so self can be called with parent nodes of collection to
    # get common ancestors of collection _excluding_ nodes in collection.
    uniq_of = of.uniq
    model.with(selected: self).with_recursive(arel_table.name => [
      selected.project(selected[Arel.star]).where(selected[:id].in(uniq_of)),
      selected.project(selected[Arel.star])
        .join(arel_table).on(selected[:id].eq(arel_table[:parent_id]))
    ]).select(arel_table[Arel.star])
      .group(column_names)
      .having(arel_table[:id].count.eq(uniq_of.size))
      .order(arel_table[:depth].desc)
  }

  # Return: succeeding record in order of appearance, used for partial view reload.
  # TODO: add scope returning succeeding element for multiple records
  def succeeding
    quantities = Quantity.arel_table
    Quantity.with(lagging_quantities: user.quantities.with_path.select(
      quantities[Arel.star],
      # For SQLite 'OVER () ORDER BY x' is not equivalent to 'OVER (ORDER BY x)'.
      Arel::Nodes::NamedFunction.new('LAG', [quantities[:id]])
        .over(Arel::Nodes::Window.new.order(Quantity.ordered.order_values)).as('lag_id')
    )).from(Arel::Table.new(:lagging_quantities).as(:quantities))
      .where(quantities[:lag_id].eq(id)).take
  end

  def with_progenies
    user.quantities.ordered(root: id).to_a
  end

  def progenies
    user.quantities.ordered(root: id, include_root: false).to_a
  end

  # Return: record with ID `of` with its ancestors, sorted by :depth
  scope :with_ancestors, ->(of) {
    selected = Arel::Table.new('selected')

    model.with(selected: self).with_recursive(arel_table.name => [
      selected.project(selected[Arel.star]).where(selected[:id].eq(of)),
      selected.project(selected[Arel.star])
        .join(arel_table).on(selected[:id].eq(arel_table[:parent_id]))
    ])
  }

  # Return: ancestors of (possibly destroyed) self
  def ancestors
    user.quantities.with_ancestors(parent_id).order(:depth).to_a
  end

  def ancestor_of?(progeny)
    user.quantities.with_ancestors(progeny.id).exists?(id)
  end

  def relative_pathname(ancestor)
    pathname.delete_prefix(ancestor ? ancestor.pathname + PATHNAME_DELIMITER : '')
  end
end
