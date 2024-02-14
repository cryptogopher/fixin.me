module CoreExt::ActionDispatch::SystemTesting::TestHelpers::CustomScreenshotHelperUniqueId
  private

  def unique
    Time.current.strftime("%Y-%m-%d %H:%M:%S.%9N_#{Minitest.seed}")
  end
end
