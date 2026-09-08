import { Controller } from "@hotwired/stimulus"

// Drives the `dark` Tailwind variant, which matches
// `[data-color-scheme="dark"]`. The stored "system" value is resolved
// against the OS preference (and follows live changes).
export default class extends Controller {
  static targets = [ "moonIcon", "sunIcon" ]

  #media;
  #onSystemChange;

  connect() {
    this.#media = window.matchMedia("(prefers-color-scheme: dark)")
    this.#onSystemChange = () => {
      if (this.#stored === "system") this.#apply("dark", true)
    }
    this.#media.addEventListener?.("change", this.#onSystemChange)
    this.#apply(this.#stored, this.#stored === "system")
  }

  disconnect() {
    this.#media?.removeEventListener?.("change", this.#onSystemChange)
  }

  setLight() {
    localStorage.setItem("color_scheme", "light")
    this.#apply("light", false)
  }

  setDark() {
    localStorage.setItem("color_scheme", "dark")
    this.#apply("dark", false)
  }

  setSystem() {
    localStorage.setItem("color_scheme", "system")
    this.#apply("dark", true)
  }

  // Binary header toggle: flips the resolved scheme and pins it as an
  // explicit preference (a system-follower who taps leaves system mode).
  // The icon always previews the destination, synced in #apply.
  toggle() {
    const resolved = this.element.dataset.colorScheme
    if (resolved === "dark") {
      localStorage.setItem("color_scheme", "light")
      this.#apply("light", false)
    } else {
      localStorage.setItem("color_scheme", "dark")
      this.#apply("dark", false)
    }
  }

  get #stored() {
    return localStorage.getItem("color_scheme") || "system"
  }

  // Sets the dataset the `dark` variant keys off, always to the resolved
  // value ("light" or "dark"). The stored preference ("light"/"dark"/"system")
  // is mirrored on data-color-scheme-preference for debugging.
  #apply(value, followSystem) {
    const resolved = followSystem ? (this.#media.matches ? "dark" : "light") : value
    this.element.dataset.colorScheme = resolved
    this.element.style.colorScheme = resolved
    this.element.dataset.colorSchemePreference = followSystem ? "system" : value
    // Header toggle icons (mobile only; absent on desktop — skip silently).
    if (this.hasMoonIconTarget) this.moonIconTarget.classList.toggle("hidden", resolved === "dark")
    if (this.hasSunIconTarget) this.sunIconTarget.classList.toggle("hidden", resolved !== "dark")
  }
}
