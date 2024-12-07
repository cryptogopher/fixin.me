module CoreExt
  module BigDecimalScientificNotation
    def to_scientific
      return 'NaN' unless finite?

      sign, coefficient, base, exponent = split
      (sign == -1 ? '-' : '') +
        (coefficient.length > 1 ? coefficient.insert(1, '.') : coefficient) +
        (exponent != 1 ? "e#{exponent-1}" : '')
    end

    # Converts value to HTML formatted scientific notation
    def to_html
      sign, coefficient, base, exponent = split
      return 'NaN' unless sign

      result = (sign == -1 ? '-' : '')
      unless coefficient == '1' && sign == 1
        if coefficient.length > 1
          result += coefficient.insert(1, '.')
        elsif
          result += coefficient
        end
        if exponent != 1
          result += "&times;"
        end
      end
      if exponent != 1
        result += "10<sup>% d</sup>" % [exponent-1]
      end
      result.html_safe
    end
  end
end

BigDecimal.prepend CoreExt::BigDecimalScientificNotation
