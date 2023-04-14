module ApplicationHelper
  class TabularFormBuilder < ActionView::Helpers::FormBuilder
    (field_helpers - [:label]).each do |selector|
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        def #{selector}(method, options = {})
          @template.content_tag :tr do
            @template.content_tag(:td, label_for(method, options)) +
            @template.content_tag(:td, super)
          end
        end
      RUBY_EVAL
    end

    def label_for(method, options = {})
      text = options.delete(:label)
      text ||= @object.class.human_attribute_name(method).capitalize

      classes = @template.class_names(required: options[:required],
                                      error: @object&.errors[method].present?)

      label(method, text, class: classes) +
        (@template.tag(:br) + @template.content_tag(:em, options.delete(:hint)) if options[:hint])
    end

    def submit(value, options = {})
      @template.content_tag :tr do
        @template.content_tag :td, super, colspan: 2
      end
    end

    def table_form_for(&block)
      @template.content_tag(:table) { yield(self) }
    end
  end

  def tabular_form_for(record, options = {}, &block)
    options.merge! builder: TabularFormBuilder
    options.merge! data: {turbo: false}
    form_for(record, **options, &-> (f) { f.table_form_for(&block) })
  end

  def image_link_to(name, image = nil, options = nil, html_options = nil)
    return "" if html_options.delete(:unless_current) && (url_for(options) == request.path)

    name = svg_tag("pictograms/#{image}.svg#icon") + name if image
    link_to name, options, html_options
  end

  def svg_tag(source, options = {})
    image_name, id = source.split('#')
    content_tag :svg, options do
      tag.use href: "#{image_path(image_name)}##{id}"
    end
  end
end
