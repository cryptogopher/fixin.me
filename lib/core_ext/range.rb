class Range
  # TODO: cleanup comments after commit
  # * < nil, true < false
  #if a.end == b.end
  #  a.exclude_end? ^ b.exclude_end? ? (a.exclude_end? ? -1 : 1) : 0
  #else
  #  a.end <=> b.end || (a.end.nil? ? 1 : -1)
  #end
  #a.end == b.end ? (b.exclude_end? ? b : a) : [a, b].to_h.except(nil).min
  #*(l[0] == r[0] ? (r[1] ? r : l) : [l, r].reject{ |e| e[0].nil? }.min)
  def &(other)
    case other
    when Range
      return nil unless self.overlap?(other)

      both = [self, other]
      return Range.new(
        both.map(&:begin).compact.max,
        *if self.end == other.end
           other.exclude_end? ? [other] : [self]
        else
          both.select(&:end)
        end.map { |r| [r.end, r.exclude_end?] }.min
      )
    when Array
      return other.map { |o| self & o }.compact
    else
      return self.member?(other) ? other : nil
    end
  end
end
