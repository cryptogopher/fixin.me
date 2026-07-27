module CoreExt::ActionView::RecordIdentifierWithSuffix
  # TODO: replace dom_id with dom_target, then remove this override
  def dom_id(object, prefix = nil, suffix = nil)
    if suffix
      "#{super(object, prefix)}#{::ActionView::RecordIdentifier::JOIN}#{suffix}"
    else
      super(object, prefix)
    end
  end
end
