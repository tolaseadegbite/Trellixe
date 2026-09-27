import { Controller } from "@hotwired/stimulus"

// Live countdown for due-date labels (todos). The server renders the
// initial snapshot text (first paint + no-JS floor); this controller takes
// the due timestamp and re-renders ticking text: minute-level inside 24
// hours, day-level beyond. Past the line it flips to overdue.
//
// Lifecycle note: one interval per instance, cleared on disconnect. It only
// ever rewrites its label's textContent — no DOM moves, no re-init path,
// so Stimulus has nothing to chase (cf. the datepicker wrapper loop).
export default class extends Controller {
  static targets = [ "label" ]
  static values = { dueAt: String, fallback: { type: String, default: "" } }

  connect() {
    this.tick()
    this.timer = setInterval(() => this.tick(), 30000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const due = new Date(this.dueAtValue).getTime()
    if (Number.isNaN(due)) return

    const diff = due - Date.now()
    this.labelTarget.textContent = diff < 0 ? `Overdue · ${this.#span(-diff)}` : this.#upcoming(diff)
  }

  #upcoming(diff) {
    if (diff < 3600000) {
      const mins = Math.max(1, Math.floor(diff / 60000))
      return `Due in ${mins}m`
    }
    if (diff < 86400000) {
      const hours = Math.floor(diff / 3600000)
      const mins = Math.floor((diff % 3600000) / 60000)
      return mins > 0 ? `Due in ${hours}h ${mins}m` : `Due in ${hours}h`
    }
    return this.fallbackValue
  }

  #span(abs) {
    const days = Math.floor(abs / 86400000)
    if (days > 0) {
      const hours = Math.floor((abs % 86400000) / 3600000)
      return hours > 0 ? `${days}d ${hours}h` : `${days}d`
    }
    const hours = Math.floor(abs / 3600000)
    if (hours > 0) {
      const mins = Math.floor((abs % 3600000) / 60000)
      return mins > 0 ? `${hours}h ${mins}m` : `${hours}h`
    }
    return `${Math.max(1, Math.floor(abs / 60000))}m`
  }
}
