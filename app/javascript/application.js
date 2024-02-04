// Configure your import map in config/importmap.rb. Read more:
// https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

function showPage(event) {
  document.documentElement.style.visibility="visible"
}
document.addEventListener('turbo:load', showPage)

/*
function beforeStreamRender(event) {
  console.log(event.target)
}
document.addEventListener('turbo:before-stream-render', beforeStreamRender)
*/

Turbo.session.streamMessageRenderer.appendFragment = async function (fragment) {
  for (let child of [...fragment.children]) {
    document.documentElement.appendChild(child)
    if (child.action == "click") {
      await new Promise((resolve) => {
        new MutationObserver((mutations, observer) => {
          mutations.forEach((m) => {
            if ([...m.removedNodes].includes(child)) {
              resolve(child)
              observer.disconnect()
            }
          })
        }).observe(document.documentElement, {childList: true})
      })
    }
  }
}


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

Turbo.StreamActions.blur = function() {
  blur()
}

Turbo.StreamActions.focus = function() {
  // NOTE: call blur() before setting focus?
  this.targetElements[0].focus({focusVisible: true})
}

Turbo.StreamActions.click = function() {
  this.targetElements.forEach((e) => { e.click() })
}
