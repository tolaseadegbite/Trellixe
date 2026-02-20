import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dependee", "dependant", "actionBar", "count"]

  connect() {
    this.#checkDependees()
    this.#toggleActionBar()
  }

  // --- Actions ---

  check({ target }) {
    if (this.dependeeTargets.includes(target)) {
      this.#checkDependants(target.checked)
    } else {
      this.#checkDependees()
    }
    this.#toggleActionBar()
  }

  // NEW: Call this from Turbo Stream to reset UI
  deselectAll() {
    // 1. Uncheck everything
    this.dependeeTargets.forEach(el => el.checked = false)
    this.dependantTargets.forEach(el => el.checked = false)
    
    // 2. Hide UI
    this.#toggleActionBar()

    // 3. Reset the form (clears the dropdown)
    this.element.reset()
  }

  // --- Private Helpers ---

  #checkDependants(isChecked) {
    this.dependantTargets.forEach(it => it.checked = isChecked)
  }

  #checkDependees() {
    this.dependeeTargets.forEach(it => {
      it.checked = this.#allChecked
      it.indeterminate = this.#indeterminate
    })
  }

  #toggleActionBar() {
    if (!this.hasActionBarTarget) return

    const selectedCheckboxes = this.dependantTargets.filter(it => it.checked)
    
    if (selectedCheckboxes.length > 0) {
      this.actionBarTarget.style.display = "flex"
      if (this.hasCountTarget) {
        const uniqueValues = new Set(selectedCheckboxes.map(it => it.value))
        this.countTarget.textContent = `${uniqueValues.size} selected`
      }
    } else {
      this.actionBarTarget.style.display = "none"
    }
  }

  get #indeterminate() {
    return this.#atLeastOneChecked && !this.#allChecked
  }

  get #atLeastOneChecked() {
    return this.hasDependantTarget && this.dependantTargets.some(it => it.checked)
  }

  get #allChecked() {
    return this.hasDependantTarget && this.dependantTargets.length > 0 && this.dependantTargets.every(it => it.checked)
  }
}