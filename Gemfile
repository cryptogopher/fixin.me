source "https://rubygems.org"

gem "rails", "~> 7.1.2"
gem "sprockets-rails"
gem "mysql2", "~> 0.5"
gem "puma", "~> 6.0"
gem "sassc-rails"
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

gem "devise"

gem 'importmap-rails', '~> 1.2.3'
# turborails >= 2.0.0 required with npm v8.0.0 with support for [autofocus]
# attribute in turbo-streams
gem 'turbo-rails', '> 1.5.0'

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
end
