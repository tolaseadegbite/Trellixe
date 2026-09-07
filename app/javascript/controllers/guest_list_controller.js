import { Controller } from "@hotwired/stimulus"

// Client-side filter + live count for the guest checklist on event forms.
// Rows carry their searchable text in data-search; no server round-trips.
export default class extends Controller {
  static targets = [ "filter", "row", "count", "emptyHint" ]

  connect() {
    this.updateCount()
  }

  filter() {
    const query = this.filterTarget.value.trim().toLowerCase()
    let visible = 0
    this.rowTargets.forEach((row) => {
      const hit = row.dataset.search.includes(query)
      row.classList.toggle("hidden", !hit)
      if (hit) visible += 1
    })
    if (this.hasEmptyHintTarget) {
      this.emptyHintTarget.classList.toggle("hidden", visible > 0)
    }
  }

  updateCount() {
    if (!this.hasCountTarget) return
    const selected = this.element.querySelectorAll('input[type="checkbox"]:checked').length
    this.countTarget.textContent = `${selected} selected`
  }
}
