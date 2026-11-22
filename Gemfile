source "https://rubygems.org"

# The requirement for the Ruby version comes from Rails.
gem "rails", "~> 8.1.4"
gem "sprockets-rails"
gem "puma", "~> 6.0"
gem "sassc-rails"
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem.
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem "sqlite3", "~> 2.7"

gem "devise", "~> 5.0.4"

gem "importmap-rails"
gem "turbo-rails", "~> 2.0"

group :development, :test do
  gem "byebug"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console].
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler].
  # gem "rack-mini-profiler"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing].
  # TODO: move back from git after this PR is included:
  #   https://github.com/teamcapybara/capybara/pull/2862
  gem "capybara", git: "https://github.com/teamcapybara/capybara", branch: "table_row-optional-header-and-integer-locator"
  gem "selenium-webdriver"
end

# TODO: remove after upgrade to next version containing PR:
#   https://github.com/ruby-i18n/i18n/pull/755
gem "i18n", git: "https://github.com/ruby-i18n/i18n", branch: "delegate-missing-interpolation-handler"
