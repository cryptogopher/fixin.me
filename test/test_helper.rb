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

  # NOTE: use public #alphanumeric(chars: ...) from Ruby 3.3 onwards
  SecureRandom.class_eval do
    def self.random_symbol(n = 10)
      # Unicode characters: 32-126, 160-383
      choose([*' '..'~', 160.chr(Encoding::UTF_8), *'¡'..'ſ'], n)
    end
  end

  def randomize_user_password!(user)
    random_password.tap { |p| user.update!(password: p) }
  end

  def random_password
    SecureRandom.alphanumeric rand(Rails.configuration.devise.password_length)
  end

  def random_email
    "%s@%s.%s" % (1..3).map { SecureRandom.alphanumeric(rand(1..20)) }
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

  def with_last_email
    yield(ActionMailer::Base.deliveries.last)
  end
end
