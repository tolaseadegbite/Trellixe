import { Controller } from "@hotwired/stimulus"

// Owns a page's search card (search input + collapsible filter panel) and
// every control that clears filters without a page reload. Works when
// placed on a wrapper containing both the search card and the list:
// targets resolve within it, while closeOnClickOutside scopes dismissal
// to the card itself (falls back to the whole element where no card
// target exists, e.g. embedded search forms).
export default class extends Controller {
  static targets = [ "filters", "card" ]

  // Action to be called on button click
  toggle() {
    // The controller outlives its panel on pages that render no search
    // card (e.g. the events calendar view) — a toggle with nothing to
    // toggle is a no-op, never an exception.
    if (!this.hasFiltersTarget) return
    // Toggles visibility on the filters target div (Tailwind `hidden`;
    // the legacy css-zero `hide` class no longer exists on these panels)
    this.filtersTarget.classList.toggle("hidden")
  }

  /**
   * Handles clicks outside the component.
   * Triggered by the `click@window` action.
   */
  closeOnClickOutside(event) {
    // Pages like the events calendar carry this controller without a
    // panel — without this guard every click on them throws
    // "Missing target element".
    if (!this.hasFiltersTarget) return
    // Flatpickr renders its calendar at document.body level, outside the
    // panel — navigating months/years must not collapse the filters.
    if (event.target.closest(".flatpickr-calendar")) return

    // Check two conditions:
    // 1. Was the click outside of the search card?
    // 2. Is the filter panel currently visible?
    const scope = this.hasCardTarget ? this.cardTarget : this.element
    const isOutside = !scope.contains(event.target)
    const isVisible = !this.filtersTarget.classList.contains("hidden")

    if (isOutside && isVisible) {
      // If both are true, hide the filters.
      this.filtersTarget.classList.add("hidden")
    }
  }

  // Clears the search input plus every filter field (widget-aware), then
  // submits the search form once so the list refreshes in place. Lives
  // inside the panel, so the window click-outside handler ignores the
  // click and the panel stays exactly as it was.
  resetAll(event) {
    event.preventDefault()
    this.#fieldRoots().forEach((root) => {
      root.querySelectorAll("input, select, textarea").forEach((el) => this.#clearField(el))
    })
    this.#submitSearch()
  }

  // Clears the filter(s) named in `names` (space-separated input names),
  // then submits once. Readout pills live outside the panel, so the
  // window handler collapses it first — the desired end state is a
  // cleared, closed filter UI with a restored list.
  removeFilter(event) {
    event.preventDefault()
    const names = (event.params.names || "").split(" ").filter(Boolean)
    names.forEach((name) => {
      this.element.querySelectorAll(`[name="${CSS.escape(name)}"]`).forEach((el) => this.#clearField(el))
    })
    this.#submitSearch()
  }

  #fieldRoots() {
    // The search form plus the filter panel. Bulk checkboxes elsewhere on
    // the page are deliberately untouched.
    const roots = this.hasFiltersTarget ? [ this.filtersTarget ] : []
    const searchForm = this.#searchForm()
    if (searchForm) roots.push(searchForm)
    return roots
  }

  #submitSearch() {
    const form = this.#searchForm()
    if (form) form.requestSubmit()
  }

  #searchForm() {
    const card = this.hasCardTarget ? this.cardTarget : this.element
    return card.querySelector("form")
  }

  #clearField(el) {
    if (el.tomselect) {
      el.tomselect.clear()
      return
    }
    if (el._flatpickr) {
      el._flatpickr.clear()
      return
    }
    if (el.type === "checkbox" || el.type === "radio") {
      el.checked = false
      return
    }
    el.value = ""
  }
}
