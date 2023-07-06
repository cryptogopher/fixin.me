#require "bigdecimal"
#require "bigdecimal/util"

module FixinMe
  module BigDecimalWithGrouping
    def to_s(format = "3F")
      super(format)
    end
  end
end

BigDecimal.prepend(FixinMe::BigDecimalWithGrouping)
