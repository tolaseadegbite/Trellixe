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
  // NEW: This method runs when the controller is first connected to the page.
  connect() {
    // 1. Check if the browser supports push notifications at all.
    if (!("serviceWorker" in navigator && "PushManager" in window)) {
      console.warn("Push notifications are not supported.");
      this.element.style.display = 'none'; // Hide the button if not supported
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
        this.element.style.display = 'none'; // Hide the whole <div>
      } else {
        // 4. If no subscription, make sure the button is visible.
        console.log("User is not subscribed.");
        this.element.style.display = 'block';
      }
    } catch (error) {
      console.error("Error checking push subscription status:", error);
    }
  }

  // Your existing subscribe method (no changes needed)
  async subscribe(event) {
    event.preventDefault();

    const permission = await Notification.requestPermission();
    if (permission !== "granted") {
      alert("Permission denied.");
      return;
    }

    try {
      const registration = await navigator.serviceWorker.ready;
      const vapidKey = document.querySelector("meta[name='vapid_key']").content;
      const applicationServerKey = urlBase64ToUint8Array(vapidKey);

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
        alert("Successfully subscribed!");
        // We can now hide the button immediately after successful subscription
        this.element.style.display = "none";
      } else {
        alert("Subscription failed.");
      }
    } catch (error) {
      console.error("Push subscription error: ", error);
    }
  }
}