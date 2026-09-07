import { Controller } from "@hotwired/stimulus";
import { post } from "@rails/request.js";

// Utility to convert VAPID key (keep this function)
function urlBase64ToUint8Array(base64String) {
  // ... (no changes needed here)
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");
  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);
  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

export default class extends Controller {
  static targets = [ "subscribeButton", "label" ];

  connect() {
    // Read the server key up front so a missing key shows an explanatory
    // disabled state instead of silently vanishing on click.
    this.vapidKey = (document.querySelector("meta[name='vapid_key']")?.content || "").trim();

    // 1. Check if the browser supports push notifications at all.
    if (!("serviceWorker" in navigator && "PushManager" in window)) {
      console.warn("Push notifications are not supported.");
      this.element.style.display = 'none'; // Hide the button if not supported
      return;
    }

    if (!this.vapidKey) {
      this.#setUnavailable();
      return;
    }

    // 2. Check the current subscription status.
    this.checkSubscriptionStatus();
  }

  async checkSubscriptionStatus() {
    try {
      const registration = await navigator.serviceWorker.ready;
      const subscription = await registration.pushManager.getSubscription();

      // 3. If a subscription exists, the user is already subscribed.
      if (subscription) {
        console.log("User is already subscribed.");
        this.#setLabel("Alerts on");
        this.subscribeButtonTarget.disabled = true;
        this.subscribeButtonTarget.title = "Push notifications are enabled on this device.";
      } else {
        // 4. If no subscription, make sure the button is visible.
        console.log("User is not subscribed.");
        this.element.style.display = 'block';
      }
    } catch (error) {
      console.error("Error checking push subscription status:", error);
    }
  }

  async subscribe(event) {
    event.preventDefault();

    const permission = await Notification.requestPermission();
    if (permission !== "granted") {
      this.#setLabel("Blocked — allow in browser");
      this.subscribeButtonTarget.title = "Notifications are blocked. Allow them in your browser site settings, then try again.";
      return;
    }

    if (!this.vapidKey) {
      this.#setUnavailable();
      return;
    }

    try {
      const registration = await navigator.serviceWorker.ready;
      const applicationServerKey = urlBase64ToUint8Array(this.vapidKey);

      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: applicationServerKey,
      });

      const response = await post("/web_push_subscriptions", {
        body: JSON.stringify({ subscription: subscription.toJSON() }),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      });

      if (response.ok) {
        this.#setLabel("Alerts on");
        this.subscribeButtonTarget.disabled = true;
        this.subscribeButtonTarget.title = "Push notifications are enabled on this device.";
      } else {
        this.#setLabel("Failed — tap to retry");
      }
    } catch (error) {
      console.error("Push subscription error: ", error);
      this.#setLabel("Failed — tap to retry");
    }
  }

  #setUnavailable() {
    this.#setLabel("Push unavailable");
    this.subscribeButtonTarget.disabled = true;
    this.subscribeButtonTarget.title = "Push notifications aren't configured on this server (missing VAPID key).";
  }

  #setLabel(text) {
    if (this.hasLabelTarget) this.labelTarget.textContent = text;
  }
}
