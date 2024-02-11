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

/*
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

window.renderTurboStream = function (message) {
  // Render if not already rendering, otherwise just append fragment to DOM
  if (document.documentElement.getElementsByTagName("turbo-stream").length == 0) {
    Turbo.renderStreamMessage(message)
  } else {
    Turbo.session.streamMessageRenderer
      .appendFragment(Turbo.StreamMessage.wrap(message).fragment)
  }
}
*/

Turbo.StreamElement.prototype.enableElement = function(element) {
    element.removeAttribute("disabled")
    element.removeAttribute("aria-disabled")
    // 'tabindex' is not used explicitly, so removing it is safe
    element.removeAttribute("tabindex")
}

Turbo.StreamElement.prototype.removePreviousForm = function(form) {
  const id = form.id
  const row = document.getElementById(id + "_cached")
  form.remove()
  if (row) {
    row.id = id
    row.style.display = "revert"
  }
  if (form.hasAttribute("data-link-id")) {
    const link = document.getElementById(form.getAttribute("data-link-id"))
    this.enableElement(link)
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
  this.targetElements.forEach((e) => { this.enableElement(e) })
}

Turbo.StreamActions.blur = function() {
  blur()
}

Turbo.StreamActions.focus = function() {
  // NOTE: call blur() before setting focus?
  this.targetElements[0].focus({focusVisible: true})
}

Turbo.StreamActions.prepend_form = function() {
  this.targetElements.forEach((e) => {
    [...e.getElementsByClassName("form")].forEach((f) => {
      this.removePreviousForm(f)
    })
    e.prepend(this.templateContent)
  })
}

Turbo.StreamActions.after_form = function() {
  this.targetElements.forEach((e) => {
    [...e.parentElement?.getElementsByClassName("form")].forEach((f) => {
      this.removePreviousForm(f)
    })
    e.parentElement?.insertBefore(this.templateContent, e.nextSibling)
  })
}

Turbo.StreamActions.replace_form = function() {
  this.targetElements.forEach((e) => {
    [...e.parentElement?.getElementsByClassName("form")].forEach((f) => {
      this.removePreviousForm(f)
    })
    e.style.display = "none"
    e.id = e.id + "_cached"
    e.parentElement?.insertBefore(this.templateContent, e.nextSibling)
  })
}

Turbo.StreamActions.close_form = function() {
  this.targetElements.forEach((e) => {
    this.removePreviousForm(e.closest(".form"))
  })
}

/*
Turbo.StreamActions.click = function() {
  this.targetElements.forEach((e) => { e.click() })
}
*/
