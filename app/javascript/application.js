// Configure your import map in config/importmap.rb. Read more:
// https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

function showPage(event) {
  document.documentElement.style.visibility="visible"
}
document.addEventListener('turbo:load', showPage)


Turbo.StreamElement.prototype.enableElement = function(element) {
    element.removeAttribute("disabled")
    element.removeAttribute("aria-disabled")
    // 'tabindex' is not used explicitly, so removing it is safe
    element.removeAttribute("tabindex")
}


Turbo.StreamActions.disable = function() {
  this.targetElements.forEach((e) => {
    e.setAttribute("disabled", "disabled")
    e.setAttribute("aria-disabled", "true")
    e.setAttribute("tabindex", "-1")
  })
}

Turbo.StreamActions.enable = function() {
  this.targetElements.forEach((e) => { this.enableElement(e) })
}

Turbo.StreamActions.hide = function() {
  this.targetElements.forEach((e) => { e.style.display = "none" })
}

Turbo.StreamActions.close_form = function() {
  this.targetElements.forEach((e) => {
    document.getElementById(e.getAttribute("data-form")).remove()
    if (e.hasAttribute("data-link")) {
      this.enableElement(document.getElementById(e.getAttribute("data-link")))
    }
    if (e.hasAttribute("data-hidden-row")) {
      document.getElementById(e.getAttribute("data-hidden-row")).removeAttribute("style")
    }
    e.remove()
  })
}
