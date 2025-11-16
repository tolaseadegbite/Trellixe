import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  connect() {
    // On page load, find the link that matches the initial frame source and make it active.
    const initialSrc = document.getElementById("settings_content").src
    const activeLink = this.linkTargets.find(link => link.href === initialSrc)
    if (activeLink) {
      this.activate(activeLink)
    }
  }

  select(event) {
    // When any link is clicked, activate it.
    this.activate(event.currentTarget)
  }

  activate(element) {
    // Go through all links...
    this.linkTargets.forEach((link) => {
      // ...and remove the aria-current attribute from them.
      link.removeAttribute("aria-current")
    })

    // And add the aria-current="page" attribute to the one that was clicked.
    element.setAttribute("aria-current", "page")
  }
}