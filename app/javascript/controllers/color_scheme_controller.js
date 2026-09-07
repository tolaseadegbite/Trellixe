import { Controller } from "@hotwired/stimulus"

// Drives the `dark` Tailwind variant, which matches
// `[data-color-scheme="dark"]`. The stored "system" value is resolved
// against the OS preference (and follows live changes).
export default class extends Controller {
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
  }
}
