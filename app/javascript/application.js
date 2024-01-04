// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
Turbo.session.drive = false

function showPage(event) {
  document.documentElement.style.visibility="visible";
}
document.addEventListener('turbo:load', showPage);
