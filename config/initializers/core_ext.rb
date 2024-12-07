require 'core_ext/big_decimal_scientific_notation'

ActiveSupport.on_load :active_record do
  ActiveModel::Validations::NumericalityValidator.prepend CoreExt::ActiveModel::Validations::NumericalityValidatesPrecisionAndScale
end

ActiveSupport.on_load :action_dispatch_system_test_case do
  prepend CoreExt::ActionDispatch::SystemTesting::TestHelpers::ScreenshotHelperUniqueId
end
