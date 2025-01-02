module ApplicationHelper
  # TODO: replace legacy content_tag with tag.tagname
  class LabelledFormBuilder < ActionView::Helpers::FormBuilder
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

    def form_for(&block)
      @template.content_tag(:table, class: "centered") { yield(self) } +
      # Display leftover error messages (there shouldn't be any)
      @template.content_tag(:div, @object&.errors.full_messages.join(@template.tag :br))
    end

    private

    def labelled_row_for(method, options)
      @template.content_tag :tr do
        @template.content_tag(:td, label_for(method, options), class: "unwrappable") +
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

  def labelled_form_for(record, options = {}, &block)
    options.merge! builder: LabelledFormBuilder
    form_for(record, **options) { |f| f.form_for(&block) }
  end

  class TabularFormBuilder < ActionView::Helpers::FormBuilder
    def initialize(...)
      super(...)
      @default_options.merge!(@options.slice(:form))
    end

    [:text_field, :password_field, :text_area].each do |selector|
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        def #{selector}(method, options = {})
          options[:maxlength] ||= object.class.type_for_attribute(method).limit
          if object.errors.include?(method)
            options[:pattern] = except_pattern(object.public_send(method), options[:pattern])
          end
          super
        end
      RUBY_EVAL
    end

    def number_field(method, options = {})
      value = object.public_send(method)
      if value.is_a? BigDecimal
        options[:value] = value.to_scientific
        type = object.class.type_for_attribute(method)
        options[:step] ||= BigDecimal(10).power(-type.scale)
        options[:max] ||= BigDecimal(10).power(type.precision - type.scale) - options[:step]
        options[:min] = options[:min] == :step ? options[:step] : options[:min] || -options[:max]
      end
      super
    end

    def button(value = nil, options = {}, &block)
      # button does not use #objectify_options
      options.merge!(@options.slice(:form))
      super
    end

    private

    def submit_default_value
      svg_name = object ? (object.persisted? ? 'update' : 'plus-circle-outline') : ''
      @template.svg_tag("pictograms/#{svg_name}") + super
    end

    def except_pattern(value, pattern = nil)
      "(?!^#{Regexp.escape(value)}$)" + (pattern || ".*")
    end
  end

  def tabular_fields_for(record_name, record_object = nil, options = {}, &block)
    # skip_default_ids causes turbo to generate unique ID for element with [autofocus].
    # Otherwise IDs are not unique when multiple forms are open and the first input gets focus.
    record_object, options = nil, record_object if record_object.is_a? Hash
    options.merge! builder: TabularFormBuilder, skip_default_ids: true
    render_errors(record_name)
    fields_for(record_name, record_object, **options, &block)
  end

  def tabular_form_with(**options, &block)
    options = options.deep_merge builder: TabularFormBuilder, html: {autocomplete: 'off'}
    form_with(**options, &block)
  end

  def svg_tag(source, options = {})
    content_tag :svg, options do
      tag.use href: image_path(source + ".svg") + "#icon"
    end
  end

  def navigation_menu
    menu_tabs = [
      ['units', "weight-kilogram", :restricted, 'right'],
      ['users', "account-multiple-outline", :admin],
    ]

    menu_tabs.map do |name, image, status, css_class|
      if current_user.at_least(status)
        link_to svg_tag("pictograms/#{image}") + t("#{name}.navigation"),
          {controller: "/#{name}", action: "index"},
          class: class_names('tab', css_class, active: name == current_tab)
      end
    end.join.html_safe
  end

  [:button_to, :link_to, :link_to_unless_current].each do |method_name|
    class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
      def image_#{method_name}(name, image = nil, options = nil, html_options = {}, &block)
        name = name.to_s
        name = svg_tag("pictograms/\#{image}") + name if image

        html_options[:class] = class_names(
          html_options[:class],
          'button',
          dangerous: html_options[:method] == :delete
        )
        if html_options[:onclick]&.is_a? Hash
          html_options[:onclick] = "return confirm('\#{html_options[:onclick][:confirm]}');"
        end

        if __method__.start_with?('image_link_to') &&
             !(html_options[:onclick] || html_options.dig(:data, :turbo_stream))
          name = name + '...'
        end

        send :#{method_name}, name, options, html_options, &block
      end
    RUBY_EVAL
  end

  def render_errors(record)
    flash.now[:alert] = record.errors.full_messages unless record.errors.empty?
  end

  def render_flash_messages
    flash.map do |entry, messages|
      Array(messages).map do |message|
        tag.div class: "flash #{entry}" do
          tag.div(sanitize(message)) + tag.button(sanitize("&times;"), tabindex: -1,
                                                  onclick: "this.parentElement.remove();")
        end
      end
    end.join.html_safe
  end

  def render_no_items
    tag.tr id: :no_items do
      tag.td t("#{controller_name}.no_items"), colspan: 10, class: 'hint'
    end
  end

  def render_turbo_stream(partial, locals = {})
    "Turbo.renderStreamMessage('#{j(render partial: partial, locals: locals)}'); return false;"
  end

  def disabled_attributes(disabled)
    disabled ? {disabled: true, aria: {disabled: true}, tabindex: -1} : {}
  end
end
