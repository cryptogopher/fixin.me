ActiveSupport.on_load :turbo_streams_tag_builder do
  def disable(target)
    action :disable, target
  end

  def disable_all(targets)
    action_all :disable, targets
  end
end
