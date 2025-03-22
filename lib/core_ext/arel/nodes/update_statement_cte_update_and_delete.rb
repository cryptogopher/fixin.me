module CoreExt::Arel::Nodes::UpdateStatementCteUpdateAndDelete
  attr_accessor :with

  def initialize(...)
    super
    @with = nil
  end

  def hash
    [self.class, @relation, @wheres, @orders, @limit, @offset, @key, @with].hash
  end

  def eql?(other)
    eql?(other) && self.with == other.with
  end
end
