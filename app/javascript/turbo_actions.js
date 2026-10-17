// Turbo Streams actions.

const FORM_CONTROLS = ["BUTTON", "FIELDSET", "INPUT", "OPTGROUP", "OPTION", "SELECT",
                       "TEXTAREA"]

Object.assign(Turbo.StreamElement.prototype, {
  disableElement(element) {
    if (FORM_CONTROLS.includes(element.tagName)) {
      element.setAttribute("disabled", "disabled")
    } else {
      element.setAttribute("aria-disabled", "true")
      // NOTE: tabindex should not be disabled?
      element.setAttribute("tabindex", "-1")
    }
  },

  enableElement(element) {
    if (FORM_CONTROLS.includes(element.tagName)) {
      element.removeAttribute("disabled")
    } else {
      element.removeAttribute("aria-disabled")
      // Assume 'tabindex' is not used explicitly, so removing it is safe.
      element.removeAttribute("tabindex")
    }
  },

  showElement(element) { element.style.visibility = "visible" }
})

Object.assign(Turbo.StreamActions, {
  disable() {
    this.targetElements.forEach((e) => { this.disableElement(e) })
  },

  enable() {
    this.targetElements.forEach((e) => { this.enableElement(e) })
  },

  hide() {
    this.targetElements.forEach((e) => { e.style.visibility = "collapse" })
  },

  show() {
    this.targetElements.forEach((e) => { this.showElement(e) })
  },

  unselect() {
    this.targetElements.forEach((e) => { e.checked = false; this.enableElement(e) })
  },

  validate_form() {
    this.targetElements.forEach((form) => {
      this.templateContent.querySelectorAll("span").forEach((span) => {
        var control = document.querySelector(
          `[form="${form.id}"][name="${span.dataset.name}"]`
        )
        control.setCustomValidity(span.textContent)
        // Add event listener in capture phase to clear custom validity before
        // `[oninput]` or any other bubble phase handler is invoked.
        //   https://www.quirksmode.org/js/events_order.html
        // TODO: keep invalidating current value whenever user re-enters it. Store
        // invalid value and validation message in `[data-invalid-message/value]`
        // and check input value on "input" event (below) (using `[pattern]` may not
        // be suitable due to inability to customize validtion message; also
        // pattern may be used for other, conflicting purposes).
        // After user executes any other action (while form is open), remove `[data-]`
        // attributes and custom validation, as value may no longer be invalid.
        control.addEventListener(
          "input",
          function(event) { event.target.setCustomValidity("") },
          {capture: true, once: true}
        )
      })
      form.reportValidity()
    })
  },

  close_form() {
    this.targetElements.forEach((e) => {
      // Move focus if there's no focus or focus inside form being closed.
      const focused = document.activeElement
      if (!focused || (focused == document.body) || e.contains(focused)) {
        let nextForm = e.parentElement.querySelector(`#${e.id} ~ tr:has([autofocus])`)
        nextForm ??= e.parentElement.querySelector("tr:has([autofocus])")
        nextForm?.querySelector("[autofocus]").focus()
      }
      document.getElementById(e.dataset.form).remove()
      if ('link' in e.dataset) {
        this.enableElement(document.getElementById(e.dataset.link))
      }
      if ('hiddenRow' in e.dataset) {
        this.showElement(document.getElementById(e.dataset.hiddenRow))
      }
      e.remove()
    })
  }
})
