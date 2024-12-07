module CoreExt::ActiveModel::Validations::NumericalityValidatesPrecisionAndScale
  def validate_each(record, attr_name, value, ...)
    super(record, attr_name, value, ...)

    if options[:precision] || options[:scale]
      attr_type = record.class.type_for_attribute(attr_name)
      value = BigDecimal(value) unless value.is_a? BigDecimal
      if options[:precision] && (value.precision > attr_type.precision)
        record.errors.add(attr_name, :precision_exceeded, **filtered_options(attr_type.precision))
      end
      if options[:scale] && (value.scale > attr_type.scale)
        record.errors.add(attr_name, :scale_exceeded, **filtered_options(attr_type.scale))
      end
    end
  end
end
