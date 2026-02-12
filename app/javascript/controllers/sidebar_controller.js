import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["layout"]

  toggle() {
    this.layoutTarget.classList.toggle("sidebar-collapsed")
    const isCollapsed = this.layoutTarget.classList.contains("sidebar-collapsed")
    localStorage.setItem("sidebar_collapsed", isCollapsed)
  }

  connect() {
    if (localStorage.getItem("sidebar_collapsed") === "true") {
      this.layoutTarget.classList.add("sidebar-collapsed")
    }
  }
}