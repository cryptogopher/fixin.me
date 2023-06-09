module ApplicationHelper
  class TabularFormBuilder < ActionView::Helpers::FormBuilder
    (field_helpers - [:label]).each do |selector|
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        def #{selector}(method, options = {})
          labelled_row_for(method, options) { super }
        end
      RUBY_EVAL
    end

    def select(method, choices = nil, options = {}, html_options = {})
      labelled_row_for(method, options) { super }
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

    def labelled_row_for(method, options)
      @template.content_tag :tr do
        @template.content_tag(:td, label_for(method, options)) +
        @template.content_tag(:td, options.delete(:readonly) ? @object.public_send(method) : yield,
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

  def image_button_to(name, image = nil, options = nil, html_options = {})
    image_element_to(:button, name, image, options, html_options)
  end

  def image_link_to(name, image = nil, options = nil, html_options = {})
    image_element_to(:link, name, image, options, html_options)
  end

  def svg_tag(source, options = {})
    content_tag :svg, options do
      tag.use href: image_path(source + ".svg") + "#icon"
    end
  end

  def navigation_menu
    menu_items = {right: [
      [".users", "account-multiple-outline", users_path, :admin],
      [".units", "weight-kilogram", units_path, :restricted],
    ]}

    menu_items.map do |alignment, items|
      content_tag :div, class: alignment do
        items.map do |label, image, path, status|
          if current_user.at_least(status)
            image_link_to t(label), image, path, class: "tab", current: :active
          end
        end.join.html_safe
      end
    end.join.html_safe
  end

  private

  def image_element_to(type, name, image = nil, options = nil, html_options = {})
    current = (url_for(options) == request.path) && html_options.delete(:current)
    return "" if current == :hide

    name = svg_tag("pictograms/#{image}") + name if image
    html_options[:class] = class_names(html_options[:class], "button", active: current == :active)
    if html_options[:onclick]&.is_a? Hash
      html_options[:onclick] = "return confirm('#{html_options[:onclick][:confirm]}');"
    end

    send "#{type}_to", name, options, html_options
  end
end
