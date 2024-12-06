module FixinMe
  module BigDecimalScientificNotation
    def to_scientific
      return 'NaN' unless finite?

      sign, coefficient, base, exponent = split
      (sign == -1 ? '-' : '') +
        (coefficient.length > 1 ? coefficient.insert(1, '.') : coefficient) +
        (exponent != 1 ? "e#{exponent-1}" : '')
    end
  end
end

BigDecimal.prepend(FixinMe::BigDecimalScientificNotation)
