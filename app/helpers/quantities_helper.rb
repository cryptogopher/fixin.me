module QuantitiesHelper
  def quantities_check_boxes
    # Closing <details> on focusout event depends on relatedTarget for internal
    # actions being non-null. To ensure this, all top-layer elements of
    # ::details-content must accept focus, e.g. <label> needs tabindex="-1" */
    collection_check_boxes(nil, :quantity, @quantities, :id, :to_s_with_depth,
                           include_hidden: false) do |b|
      content_tag :li, b.label(tabindex: -1) { b.check_box + b.text }
    end
  end
end
