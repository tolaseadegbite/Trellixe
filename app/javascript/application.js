// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("turbo:load", () => {
  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("/serviceworker.js")
      .then(reg => console.log("Service Worker registered!"))
      .catch(err => console.error("Service Worker registration failed:", err));
  }
});
