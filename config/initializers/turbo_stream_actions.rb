ActiveSupport.on_load :turbo_streams_tag_builder do
  def disable(target)
    action :disable, target, allow_inferred_rendering: false
  end

  def disable_all(targets)
    action_all :disable, targets, allow_inferred_rendering: false
  end

  def enable(target)
    action :enable, target, allow_inferred_rendering: false
  end

  def enable_all(targets)
    action_all :enable, targets, allow_inferred_rendering: false
  end

  def focus(target)
    action :focus, target, allow_inferred_rendering: false
  end
end
