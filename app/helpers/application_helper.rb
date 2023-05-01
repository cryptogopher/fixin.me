module ApplicationHelper
  class TabularFormBuilder < ActionView::Helpers::FormBuilder
    (field_helpers - [:label]).each do |selector|
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        def #{selector}(method, options = {})
          labelled_row_for(method, super, options)
        end
      RUBY_EVAL
    end

    def select(method, choices = nil, options = {}, html_options = {})
      labelled_row_for(method, super, options)
    end

    def submit(value, options = {})
      @template.content_tag :tr do
        @template.content_tag :td, super, colspan: 2
      end
    end

    def table_form_for(&block)
      @template.content_tag(:table, class: "centered") { yield(self) } +
      # Display leftover error messages (there shouldn't be any)
      @template.content_tag(:div, @object&.errors.full_messages.join(@template.tag :br))
    end

    private

    def labelled_row_for(method, field, options)
      @template.content_tag :tr do
        @template.content_tag(:td, label_for(method, options)) +
        @template.content_tag(:td, options.delete(:readonly) ? @object.public_send(method) : field,
          @object&.errors[method].present? ?
            {class: "error", data: {content: @object&.errors.delete(method).join(" and ")}} :
            {})
      end
    end

    def label_for(method, options = {})
      return "" if (options[:label] == false)
      text = options.delete(:label)
      text ||= @object.class.human_attribute_name(method).capitalize

      classes = @template.class_names(required: options[:required],
                                      error: @object&.errors[method].present?)

      label(method, text+":", class: classes) +
        (@template.tag(:br) + @template.content_tag(:em, options.delete(:hint)) if options[:hint])
    end
  end

  def tabular_form_for(record, options = {}, &block)
    options.merge! builder: TabularFormBuilder
    form_for(record, **options, &-> (f) { f.table_form_for(&block) })
  end

  def image_link_to(name, image = nil, options = nil, html_options = {})
    current = html_options.delete(:current)
    return "" if (current == :hide) && (url_for(options) == request.path)

    name = svg_tag("pictograms/#{image}") + name if image
    classes = class_names(html_options[:class], "image-button", active: current == :active)
    html_options.merge!(class: classes) { |k, v1, v2| "#{v1} #{v2}" }

    link_to name, options, html_options
  end

  def svg_tag(source, options = {})
    content_tag :svg, options do
      tag.use href: image_path(source + ".svg") + "#icon"
    end
  end
end
