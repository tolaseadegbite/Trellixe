import { Controller } from "@hotwired/stimulus"
import { patch } from "@rails/request.js"

export default class extends Controller {
  static targets = ["input"]
  static values = { current: String }

  connect() {
    const browserTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone
    
    if (this.hasInputTarget) {
      this.inputTarget.value = browserTimeZone
    }

    if (this.hasCurrentValue && this.currentValue !== browserTimeZone) {
      // request.js will handle the headers and CSRF token correctly
      patch("/identity/time_zone", {
        body: { time_zone: browserTimeZone },
        responseKind: "json"
      })
    }
  }
}