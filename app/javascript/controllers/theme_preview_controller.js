import { Controller } from "@hotwired/stimulus"
import { writeScheme } from "controllers/scheme_storage"

// Live theme preview for the workspace settings Appearance card. Picking a
// radio applies the palette to <body> immediately, before saving — the
// saved value (server-rendered data-theme) is the truth on next load.
// Only mutates the data-theme attribute (inert to Stimulus observers — no
// DOM moves, so no connect/disconnect churn).
//
// Stale previews never reach Turbo's snapshot cache: on
// turbo:before-cache-save the saved value is restored into the outgoing
// document. That event fires pre-swap on the OLD tree, so unlike a
// disconnect() restore it can never clobber an incoming page — a teardown
// restore wrote the outgoing page's saved value onto the new body and
// forced every sidebar palette pick on this page to need two clicks.
export default class extends Controller {
  static values = { current: { type: String, default: "stock" } }

  connect() {
    this.onCacheSave = () => this.#apply(this.currentValue)
    document.addEventListener("turbo:before-cache-save", this.onCacheSave)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache-save", this.onCacheSave)
  }

  preview(event) {
    this.#apply(event.target.value)
  }

  // Saving a non-stock palette is meaningless in light mode (themes are
  // dark-only), so flip the personal scheme to dark on submit — mirrors
  // color-scheme#setDark without coupling the controllers.
  ensureDark() {
    const picked = this.element.querySelector('input[type="radio"]:checked')
    if (picked && picked.value !== "stock") {
      writeScheme(document.body.dataset.accountId || null, "dark")
      document.body.dataset.colorScheme = "dark"
      document.body.style.colorScheme = "dark"
    }
  }

  #apply(theme) {
    if (!theme || theme === "stock") {
      delete document.body.dataset.theme
    } else {
      document.body.dataset.theme = theme
    }
  }
}
