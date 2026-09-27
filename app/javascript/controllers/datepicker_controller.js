import { Controller } from "@hotwired/stimulus"
import flatpickr from "https://esm.sh/flatpickr@4.6.13?standalone"

export default class extends Controller {
  static values  = {
    type: String, disable: Array,
    mode: { type: String, default: "single" },
    showMonths: { type: Number, default: 1 },
    dateFormat: { type: String, default: "F d, Y" },
    dateTimeFormat: { type: String, default: "F d, Y H:i" }
  }

  connect() {
    // Guard: flatpickr's static mode wraps the input (removing + re-inserting
    // it), which Stimulus observes as disconnect + reconnect. Without this,
    // every reconnect re-inits, every re-init mutates, and the cycle never
    // ends — the tab locks. A reconnect with a live instance is a move, not
    // a birth: the factory stamps it on the element, so return quietly.
    if (this.element._flatpickr) return

    if (this.typeValue == "time") {
      this.flatpickr = flatpickr(this.element, this.#timeOptions)
    } else if (this.typeValue == "datetime") {
      this.flatpickr = flatpickr(this.element, this.#dateTimeOptions)
    } else {
      this.flatpickr = flatpickr(this.element, this.#basicOptions)
    }
  }

  disconnect() {
    // The wrap's transient removal must not trigger teardown, or destroy +
    // recreate feed each other forever. Defer a microtask: by then a mere
    // move has settled (element connected — do nothing), while a genuine
    // removal (frame replaced, navigation) still destroys, so nothing leaks.
    // The optional chain also covers init never running (CDN failure).
    queueMicrotask(() => {
      if (!this.element.isConnected && this.flatpickr) {
        this.flatpickr.destroy()
        this.flatpickr = undefined
      }
    })
  }

  get #timeOptions() {
    return { dateFormat: "H:i", enableTime: true, noCalendar: true }
  }

  get #dateTimeOptions() {
    return { ...this.#baseOptions, altFormat: this.dateTimeFormatValue, dateFormat: "Y-m-d H:i", enableTime: true }
  }

  get #basicOptions() {
    return { ...this.#baseOptions, altFormat: this.dateFormatValue, dateFormat: "Y-m-d" }
  }

  get #baseOptions() {
    // Inside a native <dialog> (e.g. the new/edit modals) flatpickr's
    // default body-appended calendar paints under the dialog's top-layer
    // ::backdrop (invisible), and dialog-space breaks its viewport-based
    // absolute positioning (lands bottom-right). So dialog pickers render
    // statically: flatpickr wraps the input and inlines the calendar right
    // beneath it — in the top layer, with no coordinate math at all.
    // Full-page pickers have no ancestor dialog, so they keep the default
    // body behavior untouched.
    return { altInput: true, disable: this.disableValue, mode: this.modeValue, showMonths: this.showMonthsValue, static: this.element.closest("dialog") !== null }
  }
}
