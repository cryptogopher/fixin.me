ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  include ActionMailer::TestHelper
  include ActionView::Helpers::SanitizeHelper
  include ActionView::Helpers::TranslationHelper

  # Allow skipping interpolations when translating for testing purposes
  INTERPOLATION_PATTERNS = Regexp.union(I18n.config.interpolation_patterns)
  def translate(key, **options)
    translation = options.empty? ? super.split(INTERPOLATION_PATTERNS, 2).first : super
    sanitize(translation, tags: [])
  end
  alias :t :translate

  CHARACTER_SET = {exemplar: 5, index: 1, numbers: 3, auxiliary: 1,
                   punctuation: 1/16r, symbols: 1/16r, space: 1/6r}
  # Initialize after setting Minitest.seed to ensure reproducibility.
  def character_set
    @@character_set ||=
      CHARACTER_SET.reduce([]) do |chars, (subset, factor)|
        s = t("activesupport.characters.subsets.#{subset}").chars
        if factor.is_a?(Rational)
          elements = factor * chars.length
          s *= (elements / s.length).ceil
          chars + s.sample(elements)
        else
          chars + s * factor
        end
      end
  end

  def random_string(*length_ranges, allow_blank: true, except: [])
    length = deep_rand(length_ranges)
    raise ArgumentError, "Allow blanks for 0 length" if length == 0 && !allow_blank
    begin
      result = character_set.sample(length).join
      # Rails String#blank? is based on [[:space:]] character class (String::BLANK_RE).
      # Here we use more general class including tabs, carriage returns and newlines.
      redo if !allow_blank && /^\p{Space}+$/ === result
    end while except.any? { |e| e === result }
    result
  end

  def deep_rand(*args)
    case args
    when Array
      args = args.sample
    when Range
      args = rand(args)
    else
      return args
    end while true
  end

  # Return string representation of number selected randomly within given limits.
  # Distrbiution is roughly uniform first with regard to: sign and exponent, then
  # significand, with some extra skew towards most expected values and boundaries.
  # Variants:
  #   min max exp_range         range (magnitude)
  #   -   +   MIN_EXP..min/max  0.5..min/max if min/max.exp
  #   -   -   max..min          0.5..min if min.exp, max...1.0 if max.exp
  #   -   0   MIN_EXP..min      0.5..min if min.exp
  #   0   +   MIN_EXP..max      0.5..max if max.exp
  #   +   +   min..max          0.5..max if max.exp, min...1.0 if min.exp
  # TODO: alternate between floating-point and exponential representation.
  def random_float(min: -Float::MAX_15, max: Float::MAX_15, except: [])
    # For now assume ranges are same on both sides of 0.
    assert_equal -min, max if min.negative? && max.positive?

    include_zero = (min.negative? && max.positive?) || min.zero? || max.zero?
    precision_range = [1..2, 3..4, 5..Float::DIG-1, Float::DIG]
    # Returns 0.0 <=> (precision == 0).
    precision_range << 0 if include_zero

    min_frexp, max_frexp = [min, max].map(&:abs).minmax.map { |f| Math.frexp(f) }
    fractions, exponents = min_frexp.zip(max_frexp)
    exponents[0] = Float::MIN_EXP if include_zero
    exp_range = Range.new(*exponents)
    exp_range &= [Float::MIN_EXP..-10, -9..-4, -3..0, 1..4, 5..10, 11..Float::MAX_EXP]
    begin
      precision = deep_rand(*precision_range)
      exp = deep_rand(*exp_range)

      range = [0.5, 1.0, true]
      range = [range[0], fractions[1], false] if exp == exponents[1]
      range = [fractions[0], range[1], range[2]] if exp == exponents[0] && !include_zero

      fr = rand(Range.new(*range))
      number = Math.ldexp(fr, exp)
      number *= [min.negative? ? -1.0 : 1.0, max.positive? ? 1.0 : -1.0].sample
      number = number.limit(precision).clamp(min, max)
    end while except.any? { |e| e === number }
    number.to_s
  end

  def randomize_user_password!(user)
    random_password.tap { |p| user.update!(password: p) }
  end

  def random_password
    Random.alphanumeric rand(Rails.configuration.devise.password_length)
  end

  def random_email
    "%s@%s.%s" % (1..3).map { Random.alphanumeric(rand(1..20)) }
  end

  def with_last_email
    yield(ActionMailer::Base.deliveries.last)
  end

  def column(attribute)
    model = self.class.name.delete_suffix('Test').singularize.constantize
    model.human_attribute_name(attribute)
  end
end
