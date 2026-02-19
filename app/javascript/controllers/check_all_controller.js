import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // This is the line that was breaking. It needs the strings inside the array.
  static targets = ["dependee", "dependant", "actionBar", "count"]

  connect() {
    this.#checkDependees()
    this.#toggleActionBar()
  }

  check({ target }) {
    // Check if the clicked element is one of the "Select All" boxes
    if (this.dependeeTargets.includes(target)) {
      this.#checkDependants(target.checked)
    } else {
      this.#checkDependees()
    }
    
    this.#toggleActionBar()
  }

  #checkDependants(isChecked) {
    this.dependantTargets.forEach(it => it.checked = isChecked)
  }

  #checkDependees() {
    // Update both Desktop and Mobile 'Select All' checkboxes
    this.dependeeTargets.forEach(it => {
      it.checked = this.#allChecked
      it.indeterminate = this.#indeterminate
    })
  }

  #toggleActionBar() {
    if (!this.hasActionBarTarget) return

    // Calculate uniquely selected items
    const selectedCheckboxes = this.dependantTargets.filter(it => it.checked)
    
    if (selectedCheckboxes.length > 0) {
      this.actionBarTarget.style.display = "flex"
      if (this.hasCountTarget) {
        // Use Set to ensure we don't double count if a contact is rendered in both table and mobile view
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