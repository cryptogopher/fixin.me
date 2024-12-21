module CoreExt::ActionView::RecordIdentifierWithSuffix
  def dom_id(object, prefix = nil, suffix = nil)
    if suffix
      "#{super(object, prefix)}#{::ActionView::RecordIdentifier::JOIN}#{suffix}"
    else
      super(object, prefix)
    end
  end
end
