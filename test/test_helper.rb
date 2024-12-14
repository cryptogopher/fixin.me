ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  include ActionMailer::TestHelper
  include ActionView::Helpers::TranslationHelper

  # List of categorized Unicode characters:
  # * http://www.unicode.org/Public/UNIDATA/UnicodeData.txt
  # File format: http://www.unicode.org/L2/L1999/UnicodeData.html
  # Select from graphic ranges: L, M, N, P, S, Zs
  UNICODE_CHARS = {
    1 => [*"\u0020".."\u007E"],
    2 => [*"\u00A0".."\u00AC",
          *"\u00AE".."\u05FF",
          *"\u0606".."\u061B",
          *"\u061D".."\u06DC",
          *"\u06DE".."\u070E",
          *"\u0710".."\u07FF"]
  }
  UNICODE_CHARS.default = UNICODE_CHARS[1] + UNICODE_CHARS[2]
  def random_string(bytes = 10)
    result = ''
    while bytes > 0
      result += UNICODE_CHARS[bytes].sample.tap { |c| bytes -= c.bytesize }
    end
    result
  end

  # Assumes: max >= step and step = 1e[-]N, both as strings
  def random_number(max, step)
    max.delete!('.')
    precision = max.length
    start = rand(precision) + 1
    d = (rand(max.to_i) + 1) % 10**start
    length = rand([0, 1..4, 4..precision].sample)
    d = d.truncate(-start + length)
    d = 10**(start - length) if d.zero?
    BigDecimal(step) * d
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
end
