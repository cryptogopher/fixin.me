source "https://rubygems.org"

# The requirement for the Ruby version comes from Rails
gem "rails", "~> 7.2.3"
gem "sprockets-rails"
gem "puma", "~> 6.0"
gem "sassc-rails"
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

# TODO: select db gems automatically
#   database_config = ERB.new(File.read("config/database.yml")).result
#   YAML.load(database_config, aliases: true).values.map { |env| env["adapter"] }.uniq
group :mysql, optional: true do
  gem "mysql2", "~> 0.5"
end
group :postgresql, optional: true do
  gem "pg", "~> 1.5"
end
group :sqlite, optional: true do
  gem "sqlite3", "~> 2.7"
end

gem "devise"

gem "importmap-rails"
gem "turbo-rails", "~> 2.0"

group :development, :test do
  gem "byebug"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  # Remove minitest version restriction after error fixed:
  #   railties-7.2.3/lib/rails/test_unit/line_filtering.rb:7:in `run':
  #     wrong number of arguments (given 3, expected 1..2) (ArgumentError)
  #   from /var/www/.gem/ruby/3.3.0/gems/minitest-6.0.2/lib/minitest.rb:473:in
  #     `block (2 levels) in run_suite'
  gem "minitest", "< 6"
end
