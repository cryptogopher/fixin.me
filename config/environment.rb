# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!

# Disable field_with_errors div wrapper for form inputs
ActionView::Base.field_error_proc = Proc.new { |html_tag, instance| html_tag }
