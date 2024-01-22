// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

function showPage(event) {
  document.documentElement.style.visibility="visible"
}
document.addEventListener('turbo:load', showPage)


Turbo.StreamActions.disable = function() {
  this.targetElements.forEach((e) => {
    e.setAttribute("disabled", "disabled")
    e.setAttribute("aria-disabled", "true")
    e.setAttribute("tabindex", "-1")
  })
}

Turbo.StreamActions.enable = function() {
  this.targetElements.forEach((e) => {
    e.removeAttribute("disabled")
    e.removeAttribute("aria-disabled")
    // 'tabindex' is not used explicitly, so removing it is safe
    e.removeAttribute("tabindex")
  })
}

Turbo.StreamActions.focus = function() {
  this.targetElements[0].focus({focusVisible: true})
}
