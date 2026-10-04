import { Controller } from "@hotwired/stimulus"
import { writeScheme } from "controllers/scheme_storage"

// Live theme preview for the workspace settings Appearance card. Picking a
// radio applies the palette to <body> immediately, before saving — the
// saved value (server-rendered data-theme) is the truth on next load.
// Only mutates the data-theme attribute (inert to Stimulus observers — no
// DOM moves, so no connect/disconnect churn); disconnect restores the
// saved value so Turbo-cache restores never show a stale preview.
export default class extends Controller {
  static values = { current: { type: String, default: "stock" } }

  preview(event) {
    this.#apply(event.target.value)
  }

  // Saving a non-stock palette is meaningless in light mode (themes are
  // dark-only), so flip the personal scheme to dark on submit — mirrors
  // color-scheme#setDark without coupling the controllers. Sets a flag so
  // disconnect (below) doesn't wipe the incoming server truth while the
  // old tree tears down around the redirect response.
  ensureDark() {
    const picked = this.element.querySelector('input[type="radio"]:checked')
    if (picked && picked.value !== "stock") {
      writeScheme(document.body.dataset.accountId || null, "dark")
      document.body.dataset.colorScheme = "dark"
      document.body.style.colorScheme = "dark"
      this.committed = true
    }
  }

  disconnect() {
    if (!this.committed) this.#apply(this.currentValue)
  }

  #apply(theme) {
    if (!theme || theme === "stock") {
      delete document.body.dataset.theme
    } else {
      document.body.dataset.theme = theme
    }
  }
}
