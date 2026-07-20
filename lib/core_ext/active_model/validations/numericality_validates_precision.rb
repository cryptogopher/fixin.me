module CoreExt::ActiveModel::Validations::NumericalityValidatesPrecision
  def validate_each(record, attr_name, value, **kwargs)
    super(record, attr_name, value, **kwargs)

    # Check if value can be represented using Float data type.
    # BigDecimal is used as a reference due to its arbitrary precision.
    if record.class.type_for_attribute(attr_name).type == :float && !value.is_a?(Float)
      unless value.to_d == value.to_f.to_d(kwargs[:precision])
        record.errors.add(attr_name, :out_of_range, **filtered_options(value))
      end
    end
  end
end
