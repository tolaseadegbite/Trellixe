import { Controller } from "@hotwired/stimulus"

// Disables dependent fields until a source field has a value, so filters
// that only make sense together (e.g. invitation Status needs an Event)
// can't be set alone. Clearing the source clears and disables dependents;
// disabled fields are excluded from submission by the browser.
// Usage: wrapper carries data-controller="dependent"; the source gets
// data-dependent-target="source" data-action="change->dependent#sync";
// each dependent gets data-dependent-target="field".
export default class extends Controller {
  static targets = [ "source", "field" ]

  connect() {
    this.sync()
  }

  sync() {
    const active = this.sourceTarget.value !== ""
    this.fieldTargets.forEach((field) => {
      field.disabled = !active
      if (!active) field.value = ""
    })
  }
}
