module CoreExt::XPath::DSL::NormalizeSpaceDefault
  def normalize_space(...)
    Capybara.default_normalize_ws ? super : current
  end

  alias_method :n, :normalize_space
  alias_method :normalize, :normalize_space
end
