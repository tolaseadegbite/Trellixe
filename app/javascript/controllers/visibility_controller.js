import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggleable", "input"]
  static values = { show: String }

  connect() {
    this.toggle()
  }

  toggle() {
    const value = this.inputTarget.value
    this.toggleableTargets.forEach(el => {
      el.hidden = value !== this.showValue
    })
  }
}
