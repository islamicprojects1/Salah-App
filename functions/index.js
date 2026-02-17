/**
 * Cloud Functions for Salah App
 * 
 * Sends FCM push notifications when family pulse events are created.
 * Uses Firebase Admin SDK — no keys in the app, secure.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Triggered when a new document is added to families/{familyId}/pulse
 * Sends FCM notification to topic family_{familyId}
 */
exports.onPulseCreated = functions.firestore
  .document("families/{familyId}/pulse/{pulseId}")
  .onCreate(async (snap, context) => {
    const familyId = context.params.familyId;
    const data = snap.data();

    const title = data.notificationTitle || "Family Pulse";
    const body = data.notificationBody || buildDefaultBody(data);

    const topic = `family_${familyId}`;

    try {
      await admin.messaging().send({
        topic,
        notification: {
          title,
          body,
          sound: "default",
        },
        data: {
          type: "family_activity",
          familyId,
          pulseId: context.params.pulseId,
        },
        android: {
          priority: "high",
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      });
      console.log(`FCM sent to topic ${topic}: ${title} - ${body}`);
    } catch (err) {
      console.error("FCM send failed:", err);
      throw err;
    }
  });

/**
 * Build default notification body from pulse data (fallback)
 */
function buildDefaultBody(data) {
  const { type, userName, prayer } = data;
  if (type === "prayer_logged" && prayer) {
    return `${userName || "Someone"} prayed ${prayer}`;
  }
  if (type === "encouragement") {
    return `${userName || "Someone"} encouraged you to pray! ✨`;
  }
  if (type === "family_celebration") {
    return "🎉 Your family prayed together today!";
  }
  return `${userName || "Someone"} updated the family pulse`;
}
