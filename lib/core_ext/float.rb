# If a decimal string with at most 15 significant digits is converted to the
# IEEE 754 double-precision format, giving a normal number, and then converted
# back to a decimal string with the same number of digits, the final result
# should match the original string.
# If an IEEE 754 double-precision number is converted to a decimal string with
# at least 17 significant digits, and then converted back to double-precision
# representation, the final result must match the original number:
#   ("%.16e" % self).to_f == self
class Float
  def to_scientific
    sign, significand, exponent = split
    sign + significand + (exponent != 0 ? "e#{exponent}" : '')
  end

  # Converts value to HTML formatted scientific notation.
  def to_html(show_unity: true)
    result, significand, exponent = split
    result += significand if significand != '1' || (exponent == 0 && show_unity)
    if exponent != 0
      result += "&times;" if significand != '1'
      result += "10<sup>% d</sup>" % exponent
    end
    result.html_safe
  end

  # Assume #finite? is true.
  def limit(precision = DIG)
    return 0.0 if precision.zero?
    sign, significand, exponent = split(DIG_MAX)
    "#{sign}#{significand[..precision]}e#{exponent}".to_f
  end

  private

  SPLIT_FLOAT = /(-?)(.*?)\.?0*e(.*)/

  # Format `%e` displays starting from significant digit (not 0).
  def split(digits = DIG)
    return ['', to_s[..2], 0] unless finite?
    return ['', '0', 0] if digits.zero?
    ("%.#{digits - 1}e" % self).match(SPLIT_FLOAT).captures
      .then { |sign, significand, exponent| [sign, significand, exponent.to_i] }
  end

  # The maximum number of significant decimal digits in a double-precision
  # floating point number.
  DIG_MAX = 17
  # Smallest and largest double-precision floating point numbers with DIG
  # precision.
  # TODO: change MIN_15 to MIN.ceil(MIN_10_EXP - DIG) after #ceil fix in Ruby
  # v4.0.5: https://bugs.ruby-lang.org/issues/22079
  MIN_15 = MIN.ceil(-(MIN_10_EXP - 1))
  MAX_15 = MAX.floor(-(MAX_10_EXP - DIG + 1))
end
