require 'core_ext/array_delete_bang'
require 'core_ext/float'
require 'core_ext/range'

ActiveSupport.on_load :action_dispatch_system_test_case do
  # Add timestamp to screenshot filenames to make them unique.
  prepend CoreExt::ActionDispatch::SystemTesting::TestHelpers::ScreenshotHelper

  # Allow denormalized string comparison:
  # * https://github.com/orgs/teamcapybara/discussions/2841
  XPath::DSL.prepend CoreExt::XPath::DSL
end

ActiveSupport.on_load :active_record do
  # Validate that number fits into Float data type.
  ActiveModel::Validations::NumericalityValidator
    .prepend CoreExt::ActiveModel::Validations::NumericalityValidator

  # Temporary patch for https://github.com/rails/rails/pull/54658.
  ActiveRecord::Relation.include CoreExt::ActiveRecord::Relation
  Arel::Crud.prepend CoreExt::Arel::Crud
  Arel::Nodes::DeleteStatement.prepend CoreExt::Arel::Nodes::DeleteStatement
  Arel::Nodes::UpdateStatement.prepend CoreExt::Arel::Nodes::UpdateStatement
  Arel::SelectManager.prepend CoreExt::Arel::SelectManager
  Arel::TreeManager::StatementMethods
    .prepend CoreExt::Arel::TreeManager::StatementMethods
  Arel::Visitors::ToSql.prepend CoreExt::Arel::Visitors::ToSql

  # Currently not included patches for:
  # * https://github.com/rails/rails/issues/59706
  # * https://github.com/ruby-i18n/i18n/pull/755
  # * https://github.com/teamcapybara/capybara/pull/2862
end
