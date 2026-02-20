module ApplicationHelper
  class LabeledFormBuilder < ActionView::Helpers::FormBuilder
    (field_helpers - [:label, :hidden_field]).each do |selector|
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        def #{selector}(method, options = {})
          labeled_field_for(method, options) { super }
        end
      RUBY_EVAL
    end

    def select(method, choices = nil, options = {}, html_options = {})
      labeled_field_for(method, options) { super }
    end

    private

    def labeled_field_for(method, options)
      field = if options.delete(:readonly) then
                value = object.public_send(method)
                value = @template.l(value) if value.respond_to?(:strftime)
                value ||= options[:placeholder]
              else
                yield
              end
      label_for(method, options) + field
    end

    def label_for(method, options = {})
      classes = @template.class_names(required: options[:required],
                                      error: object.errors[method].present?)

      handler = {missing_interpolation_argument_handler: method(:interpolation_missing)}
      # Label translation search order:
      #   controller.action.* => helpers.label.model.* => activerecord.attributes.model.*
      # First 2 levels are translated recursively.
      label(method, class: classes) do |builder|
        translation = I18n.config.with(**handler) { deep_translate(method, **options) }
        translation.presence || "#{builder.translation}:"
      end
    end

    def interpolation_missing(key, values, string)
      @template.instance_values[key.to_s] || deep_translate(key, **values)
    end

    # Extension to label text translation:
    # * recursive translation,
    # * interpolation of (_relative_) translation key names and instance variables,
    # * pluralization based on any interpolable value
    # TODO: add unit tests for the above
    def deep_translate(key, **options)
      options[:default] = [
        :".#{key}",
        :"helpers.label.#{@object_name}.#{key}_html",
        :"helpers.label.#{@object_name}.#{key}",
        ""
      ]

      # At least 1 interpolation key is required for #translate to act on
      # missing interpolation arguments (i.e. call custom handler).
      # Also setting `key` to nil avoids recurrent translation.
      options[key] = nil

      @template.t(".#{key}_html", **options) do |translation, resolved_key|
        if translation.is_a?(Array) && (count = translation.to_h[:count])
          @template.t(resolved_key, count: I18n.interpolate(count, **options), **options)
        else
          translation
        end
      end
    end
  end

  def labeled_form_for(record, options = {}, &block)
    extra_options = {builder: LabeledFormBuilder,
                     data: {turbo: false},
                     html: {class: 'labeled-form'}}
    options = options.deep_merge(extra_options) do |key, left, right|
      key == :class ? class_names(left, right) : right
    end
    form_for(record, **options, &block)
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
      attr_type = object.type_for_attribute(method)
      if attr_type.type == :decimal
        options[:value] = object.public_send(method)&.to_scientific
        options[:step] ||= BigDecimal(10).power(-attr_type.scale)
        options[:max] ||= BigDecimal(10).power(attr_type.precision - attr_type.scale) -
          options[:step]
        options[:min] = options[:min] == :step ? options[:step] : options[:min]
        options[:min] ||= -options[:max]
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
      @template.svg_tag("pictograms/#{svg_name}", super)
    end

    def except_pattern(value, pattern = nil)
      "(?!^#{Regexp.escape(value)}$)" + (pattern || ".*")
    end
  end

  def tabular_fields_for(record_name, record_object = nil, options = {}, &block)
    # skip_default_ids causes turbo to generate unique ID for element with
    # [autofocus].  Otherwise IDs are not unique when multiple forms are open
    # and the first input gets focus.
    record_object, options = nil, record_object if record_object.is_a?(Hash)
    options.merge!(builder: TabularFormBuilder, skip_default_ids: true)
    # TODO: set error message with setCustomValidity instead of rendering to flash?
    render_errors(record_object || record_name)
    fields_for(record_name, record_object, **options, &block)
  end

  def tabular_form_with(**options, &block)
    options = options.deep_merge(builder: TabularFormBuilder,
                                 html: {autocomplete: 'off'})
    form_with(**options, &block)
  end

  def svg_tag(source, label = nil, options = {})
    svg_tag = tag.svg(options) do
      tag.use(href: "#{image_path(source + ".svg")}#icon")
    end
    label.blank? ? svg_tag : svg_tag + tag.span(label)
  end

  def navigation_menu
    menu_tabs = [
      ['measurements', 'scale-bathroom', :restricted],
      ['quantities', 'axis-arrow', :restricted, 'right'],
      ['units', 'weight-gram', :restricted],
      ['users', 'account-multiple-outline', :admin],
    ]

    menu_tabs.map do |name, image, status, css_class|
      if current_user.at_least(status)
        link_to svg_tag("pictograms/#{image}", t("#{name}.navigation")),
          {controller: "/#{name}", action: "index"},
          class: class_names('tab', css_class, active: name == current_tab)
      end
    end.join.html_safe
  end

  def image_button_to(name, image = nil, options = nil, html_options = {})
    name, html_options = link_or_button_options(:button, name, image, html_options)
    button_to name, options, html_options
  end

  def image_button_tag(name, image = nil, html_options = {})
    name, html_options = link_or_button_options(:button, name, image, html_options)
    button_tag name, html_options
  end

  def image_link_to(name, image = nil, options = nil, html_options = {})
    name, html_options = link_or_button_options(:link, name, image, html_options)
    link_to name, options, html_options
  end

  DISABLED_ATTRIBUTES = {disabled: true, aria: {disabled: true}, tabindex: -1}

  def image_button_to_if(condition, name, image = nil, options = nil, html_options = {})
    name, html_options = link_or_button_options(:button, name, image, html_options)
    html_options = html_options.deep_merge DISABLED_ATTRIBUTES unless condition
    button_to name, options, html_options
  end

  def image_link_to_unless_current(name, image = nil, options = nil, html_options = {})
    name, html_options = link_or_button_options(:link, name, image, html_options)
    # NOTE: Starting from Rails 8.1.0, below condition can be replaced with:
    #   current_page?(options, method: [:get, :post])
    if request.path == url_for(options)
      html_options = html_options.deep_merge DISABLED_ATTRIBUTES
    end
    link_to name, options, html_options
  end

  def render_errors(records)
    # Conversion of flash to Array only required because of Devise
    flash[:alert] = Array(flash[:alert])
    Array(records).each { |record| flash[:alert] += record.errors.full_messages }
  end

  def render_flash_messages
    flash.map do |entry, messages|
      # Conversion of flash to Array only required because of Devise
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
      tag.td t("#{controller_path.tr('/', '.')}.no_items"), colspan: 10, class: 'hint'
    end
  end

  def render_turbo_stream(partial, locals = {})
    "Turbo.renderStreamMessage('#{j(render partial: partial, locals: locals)}'); return false;"
  end

  private

  def link_or_button_options(type, name, image = nil, html_options)
    html_options[:class] = class_names(
      html_options[:class],
      'button',
      dangerous: html_options[:method] == :delete
    )

    if html_options[:onclick]&.is_a? Hash
      html_options[:onclick] = "return confirm('\#{html_options[:onclick][:confirm]}');"
    end

    link_is_local = html_options[:onclick] || html_options.dig(:data, :turbo_stream)
    name = name.to_s
    name += '...' if type == :link && !link_is_local
    name = svg_tag("pictograms/#{image}", name) if image

    [name, html_options]
  end
end
