module ApplicationHelper
  class TabularFormBuilder < ActionView::Helpers::FormBuilder
    (field_helpers - [:label]).each do |selector|
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        def #{selector}(method, options = {})
          @template.content_tag :div, class: "form-row" do
            label_text = label(method, options.delete(:label))
            label_class = ["form-label"]
            label_class << "required" if options[:required]
            label_class << "error" if @object&.errors[method].present?

            @template.content_tag(:div, label_text, class: label_class) +
            @template.content_tag(:div, super, class: "form-field")
          end
        end
      RUBY_EVAL
    end

    def submit(value, options = {})
      @template.content_tag :div, super, class: "form-actions"
    end
  end

  def tabular_form_for(record, options = {}, &block)
    options.merge! builder: TabularFormBuilder
    form_for(record, **options, &block)
  end

  def svg_tag(source, options = {})
    image_name, id = source.split('#')
    content_tag :svg, options do
      tag.use href: "#{image_path(image_name)}##{id}"
    end
  end
end
