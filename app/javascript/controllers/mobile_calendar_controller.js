import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["day", "list"]
  static classes = ["active"]

  connect() {
    // Optional: Select "today" or the first day with events by default
    const today = this.dayTargets.find(day => day.dataset.isToday === "true")
    if (today) {
      this.select({ currentTarget: today })
    }
  }

  select(event) {
    const selectedDay = event.currentTarget.dataset.date
    
    // 1. Visual Feedback: Remove active class from all days, add to clicked
    this.dayTargets.forEach(el => {
      el.classList.remove(...this.activeClasses)
    })
    event.currentTarget.classList.add(...this.activeClasses)

    // 2. Filter List: Hide all lists, show the one matching the date
    let foundEvents = false
    this.listTargets.forEach(list => {
      if (list.dataset.date === selectedDay) {
        list.classList.remove("hide@sm", "hide@md", "hidden") // Ensure it's visible
        list.style.display = "block"
        foundEvents = true
        
        // Smooth scroll to the list so the user knows something changed
        list.scrollIntoView({ behavior: "smooth", block: "center" })
      } else {
        list.style.display = "none"
      }
    })

    // Handle "No events" state if needed (optional logic could go here)
  }
}