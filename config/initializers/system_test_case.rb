ActiveSupport.on_load :action_dispatch_system_test_case do
  prepend CoreExt::ActionDispatch::SystemTesting::TestHelpers::CustomScreenshotHelperUniqueId
end
