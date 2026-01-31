// Configure your import map in config/importmap.rb. Read more:
// https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"


/* Hide page before loaded for testing purposes */
function showPage(event) {
  document.documentElement.style.visibility="visible"
}
document.addEventListener('turbo:load', showPage)

function detailsChange(event) {
  var target = event.currentTarget
  var count = target.querySelectorAll('input:checked:not([disabled])').length
  var span = target.querySelector('summary > span')
  var button = target.querySelector('button')
  if (count > 0) {
    span.textContent = count + ' selected';
    Turbo.StreamElement.prototype.enableElement(button)
  } else {
    span.textContent = span.getAttribute('data-prompt')
    Turbo.StreamElement.prototype.disableElement(button)
  }
}
window.detailsChange = detailsChange

/* Close open <details> when focus lost */
function detailsClose(event) {
  if (!event.relatedTarget ||
      event.relatedTarget.closest("details") != event.currentTarget) {
    event.currentTarget.removeAttribute("open")
  }
}
window.detailsClose = detailsClose

window.detailsObserver = new MutationObserver((mutations) => {
  mutations[0].target.dispatchEvent(new Event('change', {bubbles: true}))
});


/* Turbo stream actions */
Turbo.StreamElement.prototype.disableElement = function(element) {
    element.setAttribute("disabled", "disabled")
    element.setAttribute("aria-disabled", "true")
    element.setAttribute("tabindex", "-1")
}
Turbo.StreamActions.disable = function() {
  this.targetElements.forEach((e) => { this.disableElement(e) })
}

Turbo.StreamElement.prototype.enableElement = function(element) {
    element.removeAttribute("disabled")
    element.removeAttribute("aria-disabled")
    // Assume 'tabindex' is not used explicitly, so removing it is safe
    element.removeAttribute("tabindex")
}
Turbo.StreamActions.enable = function() {
  this.targetElements.forEach((e) => { this.enableElement(e) })
}

/* TODO: change to visibility = collapse to avoid width change? */
Turbo.StreamActions.hide = function() {
  this.targetElements.forEach((e) => { e.style.display = "none" })
}

Turbo.StreamActions.show = function() {
  this.targetElements.forEach((e) => { e.style.removeProperty("display") })
}

/*
Turbo.StreamActions.collapse = function() {
  this.targetElements.forEach((e) => { e.style.visibility = "collapse" })
}
*/

Turbo.StreamActions.close_form = function() {
  this.targetElements.forEach((e) => {
    /* Move focus if there's no focus or focus inside form being closed */
    const focused = document.activeElement
    if (!focused || (focused == document.body) || e.contains(focused)) {
      let nextForm = e.parentElement.querySelector(`#${e.id} ~ tr:has([autofocus])`)
      nextForm ??= e.parentElement.querySelector("tr:has([autofocus])")
      nextForm?.querySelector("[autofocus]").focus()
    }
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

Turbo.StreamActions.unselect = function() {
  this.targetElements.forEach((e) => {
    e.checked = false
    this.enableElement(e)
  })
}

function formProcessKey(event) {
  switch (event.key) {
    case "Escape":
      event.currentTarget.querySelector("a[name=cancel]").click()
      break
    case "Enter":
      event.currentTarget.querySelector("button[name=button]").click()
      event.preventDefault()
      break
  }
}
window.formProcessKey = formProcessKey

function detailsProcessKey(event) {
  switch (event.key) {
    case "Escape":
      if (event.currentTarget.hasAttribute("open")) {
        event.currentTarget.removeAttribute("open")
        event.stopPropagation()
      }
      break
    case "Enter":
      var button = event.currentTarget.querySelector("button:not([disabled])")
      if (button) {
        button.click()
        // Autofocus won't be respected unless target is blurred
        event.target.blur()
        event.preventDefault()
        event.stopPropagation()
      }
      break
  }
}
window.detailsProcessKey = detailsProcessKey;

/* Items table drag and drop support */
var lastEnterTime
function dragStart(event) {
  lastEnterTime = event.timeStamp
  var row = event.currentTarget
  row.closest("table").querySelectorAll("thead tr").forEach((tr) => {
    tr.toggleAttribute("hidden")
  })
  event.dataTransfer.setData("text/plain", row.getAttribute("data-drag-path"))
  var rowRectangle = row.getBoundingClientRect()
  event.dataTransfer.setDragImage(row, event.x - rowRectangle.left, event.y - rowRectangle.top)
  event.dataTransfer.dropEffect = "move"
}
window.dragStart = dragStart

/*
* Drag tracking assumptions (based on FF 122.0 experience):
*   * Enter/Leave events at the same timeStamp may not be logically ordered
*     (e.g. E -> E -> L, not E -> L -> E),
*   * not every Enter event has corresponding Leave event, especially during
*     rapid pointer moves
* NOTE: sometimes Leave is not emitted when pointer goes fast over table
* and outside. This should probably be fixed in browser, than patched here.
*/
function dragEnter(event) {
  //console.log(event.timeStamp + " " + event.type + ": " + event.currentTarget.id)
  dragLeave(event)
  lastEnterTime = event.timeStamp
  const id = event.currentTarget.getAttribute("data-drop-id")
  document.getElementById(id).classList.add("dropzone")
}
window.dragEnter = dragEnter

function dragOver(event) {
  event.preventDefault()
}
window.dragOver = dragOver

function dragLeave(event) {
  //console.log(event.timeStamp + " " + event.type + ": " + event.currentTarget.id)
  // Leave has been accounted for by Enter at the same timestamp, processed earlier
  if (event.timeStamp <= lastEnterTime) return
  event.currentTarget.closest("table").querySelectorAll(".dropzone").forEach((tr) => {
    tr.classList.remove("dropzone")
  })
}
window.dragLeave = dragLeave

function dragEnd(event) {
  dragLeave(event)
  event.currentTarget.closest("table").querySelectorAll("thead tr").forEach((tr) => {
    tr.toggleAttribute("hidden")
  })
}
window.dragEnd = dragEnd

function drop(event) {
  event.preventDefault()

  var params = new URLSearchParams()
  var id_param = event.currentTarget.getAttribute("data-drop-id-param")
  var id = event.currentTarget.getAttribute("data-drop-id").split("_").pop()
  params.append(id_param, id)

  fetch(event.dataTransfer.getData("text/plain"), {
    body: params,
    headers: {
      "Accept": "text/vnd.turbo-stream.html",
      "X-CSRF-Token": document.head.querySelector("meta[name=csrf-token]").content,
      "X-Requested-With": "XMLHttpRequest"
    },
    method: "POST"
  })
  .then(response => response.text())
  .then(html => Turbo.renderStreamMessage(html))
}
window.drop = drop
