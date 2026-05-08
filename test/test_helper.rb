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
  #   * source: http://www.unicode.org/Public/UNIDATA/UnicodeData.txt
  #   * file format: http://www.unicode.org/L2/L1999/UnicodeData.html
  #   * select from graphic ranges: L, M, N, P, S, Zs
  UNICODE_CHARS = [
    *"\u0020".."\u007E",
    *"\u00A0".."\u00AC",
    *"\u00AE".."\u05FF",
    *"\u0606".."\u061B",
    *"\u061D".."\u06DC",
    *"\u06DE".."\u070E",
    *"\u0710".."\u07FF"
  ]
  def random_string(length, except: [], allow_blank: true)
    # Rails String#blank? is based on [[:space:]] character class (String::BLANK_RE).
    # Here we use more general class including tabs, cariage returns and newlines.
    except << /^\p{Space}+$/ unless allow_blank
    begin
      result = UNICODE_CHARS.sample(length).join
    end while except.any? { |e| e === result }
    result
  end

  # Range based string generation. Not finished, but saved as a potential
  # reference for future work. To work properly it needs to sort in collation
  # order of database.
  #def random_between(from, to, maxlength)
  #  # TODO: sort UNICODE_CHARS
  #  byebug
  #  result = ''
  #  maxlength.times do |i|
  #    case
  #    when from[i] == to[i]
  #      result += from[i]
  #    else
  #      from_index = UNICODE_CHARS.bsearch_index(from[i] || UNICODE_CHARS[0])
  #      to_index = UNICODE_CHARS.bsearch_index(to[i])
  #      index = rand(from_index..to_index)
  #      case
  #      when index == from_index
  #        result += UNICODE_CHARS[index]
  #        from[i+1..].each_char do |c|
  #          from_index = UNICODE_CHARS.bsearch_index(from[i])
  #          index = rand(from_index..UNICODE_CHARS.length-1)
  #          result += UNICODE_CHARS[index]
  #          break if index != from_index
  #        end
  #        if result == from
  #          if result.length < maxlength
  #            result += UNICODE_CHARS.sample
  #          else
  #            # TODO: succ result[i..]
  #            # raise if result == to
  #          end
  #        end
  #        break
  #      when index == to_index
  #        result += UNICODE_CHARS[index]
  #        to[i+1..].each_char do |c|
  #          to_index = UNICODE_CHARS.bsearch_index(to[i])
  #          index = rand(-1..to_index)
  #          break if index == -1
  #          result += UNICODE_CHARS[index]
  #          break if index != to_index
  #        end
  #        if result == to
  #          if result.length > i+1
  #            result = result[..-2]
  #          else
  #            # TODO: prev result[i..]
  #            # raise if result == from
  #          end
  #        end
  #        break
  #      else
  #        result += UNICODE_CHARS[index]
  #        break
  #      end
  #    end
  #  end
  #  return result += UNICODE_CHARS.sample(rand(0..maxlength-i-1)).join
  #  # if result == from/to ...
  #end

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
