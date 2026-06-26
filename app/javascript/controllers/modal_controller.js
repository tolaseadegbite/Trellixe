import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { dirty: Boolean }

  connect() {
    this.element.showModal()
    this._inputHandler = () => (this.dirtyValue = true)
    this.element.addEventListener("input", this._inputHandler)
  }

  disconnect() {
    this.element.removeEventListener("input", this._inputHandler)
  }

  submitEnd(e) {
    if (e.detail.success) {
      this.dirtyValue = false
      this.close()
    }
  }

  close() {
    if (this.dirtyValue && !confirm("You have unsaved changes. Close anyway?")) {
      return
    }
    this.element.close()
    const frame = document.getElementById("modal")
    frame.removeAttribute("src")
    frame.innerHTML = ""
  }

  clickOutside(event) {
    if (event.target === this.element) {
      this.close()
    }
  }
}
