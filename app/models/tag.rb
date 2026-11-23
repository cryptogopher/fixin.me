class Tag < ApplicationRecord
  ATTRIBUTES = {tag: [:label, :description, :supertag_id]}
  attr_cached :depth

  belongs_to :user
  belongs_to :supertag, optional: true, class_name: "Tag"
  alias_method :parent, :supertag
  has_many :subtags, ->{ order(:label) }, class_name: "Tag", inverse_of: :supertag,
    # Database allows cascade deletion, this is application level safety net.
    dependent: :restrict_with_error
  #has_many :quantities, dependent: :restrict_with_error

  # TODO: try to remove validations and replace them with db constraints.
  # All :supertag checks may be performed on record instead of :supertag_id, as
  # record is loaded anyway by presence validator.
  # Disallow #blank? (i.e. non-nil, non-existent ID) record association.
  # TODO: use version below after bug fixed, https://github.com/rails/rails/issues/59879
  # validates :supertag, allow_nil: true, presence: true, comparison: {...}
  validates :supertag, if: :supertag_id, presence: true,
    # TODO: add check constraint
    comparison: {other_than: :itself, message: :self_reference}
  # TODO: add foreign key constraint tag.user == supertag.user
  validates :user_id, if: :supertag_id,
    comparison: {equal_to: ->(tag){ tag.supertag.user_id }, message: :user_mismatch}
  validate on: :update, if: :supertag_changed? do
    errors.add(:supertag, :descendant_reference) if ancestor_of?(supertag)
  end
  validates :label, presence: true, uniqueness: {scope: :user_id},
    length: {maximum: type_for_attribute(:label).limit}
  validates :description, length: {maximum: type_for_attribute(:description).limit}

  after_initialize :update_depth, if: :new_record?
  before_save :update_depth, if: :supertag_changed?

  after_update if: :depth_previously_changed? do
    Tag.with_recursive(updated: [
      Tag.reselect(id: :tag_id).select(depth: :tag_depth).where(id: id),
      Tag.reselect(:id, 'tag_depth + 1').joins('JOIN updated ON tag_id = supertag_id')
    # JOIN could be replaced with 'FROM updated WHERE id = tag_id' if Rails
    # supported UPDATE FROM, https://sqlite.org/lang_update.html#update_from
    ]).joins(:updated).update_all('depth = tag_depth')
  end

  def to_s
    tag.pre label
  end

  def to_s_with_depth
    # em space, U+2003
    ' ' * depth + label
  end

  def destroyable?
    subtags.empty?
  end

  # TODO: move to ApplicationRecord?
  default_scope { select(arel_table[Arel.star]) }

  # Return: ordered [sub]hierarchy.
  scope :ordered, ->(root: nil, include_root: true) {
    Tag.with_recursive(ordered: [
      where(root && include_root ? :id : :supertag_id => root),
      Tag.joins('JOIN ordered ON tags.supertag_id = ordered.id')
        .order(depth: :desc, label: :asc)
    ]).from('ordered AS tags')
  }

  # Return: ancestors of `leaf(s)`, inclusive.
  scope :ancestors, ->(leafs) {
    return none if leafs.nil?
    Tag.with_recursive(ancestors: [
      Tag.where(id: leafs),
      Tag.joins('JOIN ancestors ON tags.id = ancestors.supertag_id')
    ]).from('ancestors AS tags')
  }

  # Return: succeeding record in order of appearance. Used for partial view reload.
  def succeeding(subtree = false)
    # Recursive SELECT cannot use window functions.  WHERE is evaluated before
    # window function in SELECT - requires use of subquery.
    # This is more compact, but probably less efficient version. Also it doesn't
    # support `subtree` option. May be freely removed, or replace longer version.
    #Tag.from(user.tags.ordered.select.lag(:id), :tags).where(lag_id: id).take

    Tag.from(
      # NULL default causes children of self to be skipped (label comparison fails).
      Tag.ancestors(id).select.lag(:label, default: subtree ? nil : ''), :left
    ).joins('
      JOIN tags ON (left.id = tags.supertag_id AND left.lag_label < tags.label) OR
      (left.supertag_id IS NULL AND tags.supertag_id IS NULL AND left.label < tags.label)
    ').order(depth: :desc, label: :asc).take
  end

  # Return: ancestors of (possibly destroyed) self.
  def ancestors
    Tag.ancestors(supertag_id).order(:depth)
  end

  def with_progenies
    user.tags.ordered(root: id)
  end

  def ancestor_of?(progeny)
    Tag.ancestors(progeny.respond_to?(:id) ? progeny.id : progeny).exists?(id)
  end

  private

  def update_depth
    self[:depth] = supertag&.depth&.succ || 0
  end
end
