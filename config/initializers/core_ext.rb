require 'core_ext/array_delete_bang'
require 'core_ext/big_decimal_scientific_notation'

ActiveSupport.on_load :action_dispatch_system_test_case do
  prepend CoreExt::ActionDispatch::SystemTesting::TestHelpers::ScreenshotHelperUniqueId
end

ActiveSupport.on_load :action_view do
  ActionView::RecordIdentifier.prepend CoreExt::ActionView::RecordIdentifierWithSuffix
end

ActiveSupport.on_load :active_record do
  ActiveModel::Validations::NumericalityValidator
    .prepend CoreExt::ActiveModel::Validations::NumericalityValidatesPrecisionAndScale

  # Temporary patch for https://github.com/rails/rails/pull/54658
  Arel::TreeManager::StatementMethods
    .prepend CoreExt::Arel::TreeManager::StatementMethodsCteUpdateAndDelete
  Arel::Nodes::DeleteStatement
    .prepend CoreExt::Arel::Nodes::DeleteStatementCteUpdateAndDelete
  Arel::Nodes::UpdateStatement
    .prepend CoreExt::Arel::Nodes::UpdateStatementCteUpdateAndDelete
  Arel::Visitors::ToSql.prepend CoreExt::Arel::Visitors::ToSqlCteUpdateAndDelete
  Arel::Crud.prepend CoreExt::Arel::CrudCteUpdateAndDelete
  Arel::SelectManager.prepend CoreExt::Arel::SelectManagerCteUpdateAndDelete
end
