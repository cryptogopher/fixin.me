module QuantitiesHelper
  def quantity_options(quantities, selected: nil)
    values = quantities.map { |q| [sanitize('&emsp;' * q.depth + q.name), q.id] }
    values.unshift([t('.select_quantity'), nil, {hidden: true}])
    options_for_select(values, selected: selected)
  end
end
