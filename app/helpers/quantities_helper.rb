module QuantitiesHelper
  def quantity_option_text(quantity, checked = nil)
    prefix = case checked
             when true
               # Use color and gray unicode emoji to assure same width.
               # Avoid shapes similar to inputs (chackboxes, radio buttons etc.)
               # (U+27A1 U+FE0F)/U+1F7E6/U+2705/U+1F499 U+2004
               '💙 '
             when false
               # U+2B1C/U+1F90D U+2004
               '🤍 '
             else
               ''
             end
    sanitize('&emsp;' * quantity.depth + prefix + quantity.name)
  end
end
