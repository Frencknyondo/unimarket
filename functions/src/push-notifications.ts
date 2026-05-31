/**
 * Firebase Cloud Function for sending FCM push notifications
 * 
 * Deploy this function to Firebase Cloud Functions with:
 * firebase deploy --only functions:sendPushNotification
 * 
 * Make sure to:
 * 1. Have Firebase Admin SDK initialized
 * 2. Grant the Cloud Function appropriate Firestore permissions
 * 3. Enable Cloud Messaging API for your Firebase project
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK (if not already initialized)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function that listens to push_queue collection and sends FCM messages
 */
export const sendPushNotification = functions.firestore
  .document("push_queue/{docId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();

    const {
      userId,
      fcmToken,
      title,
      message,
      data: customData = {},
    } = data;

    // Validate required fields
    if (!fcmToken || !title || !message) {
      console.error("Missing required fields in push_queue document");
      return;
    }

    try {
      // Send the message via FCM
      const response = await messaging.send({
        notification: {
          title: title,
          body: message,
        },
        data: {
          ...customData,
          userId: userId || "",
        },
        token: fcmToken,
      });

      // Mark the push as successfully sent
      await db
        .collection("push_queue")
        .doc(context.params.docId)
        .update({
          sent: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          response: response,
          error: null,
        });

      console.log("Push notification sent successfully:", response);
    } catch (error) {
      console.error("Error sending push notification:", error);

      // Log the error in the push_queue document
      await db
        .collection("push_queue")
        .doc(context.params.docId)
        .update({
          sent: false,
          error: (error as Error).message || "Unknown error",
          errorAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      throw error;
    }
  });

/**
 * Optional: Cleanup old push_queue documents (older than 7 days)
 * Schedule this with a Cloud Scheduler job
 */
export const cleanupOldPushQueue = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async (context) => {
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    const snapshot = await db
      .collection("push_queue")
      .where("createdAt", "<", sevenDaysAgo)
      .get();

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Cleaned up ${snapshot.docs.length} old push_queue documents`);
  });

/**
 * Optional: Retry failed push notifications
 * This function retries sending push notifications that failed
 */
export const retryFailedPushNotifications = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async (context) => {
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

    const snapshot = await db
      .collection("push_queue")
      .where("sent", "==", false)
      .where("errorAt", ">", oneHourAgo)
      .limit(100) // Limit to prevent too many retries
      .get();

    let retryCount = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const { fcmToken, title, message, data: customData = {} } = data;

      try {
        const response = await messaging.send({
          notification: {
            title: title,
            body: message,
          },
          data: customData,
          token: fcmToken,
        });

        await doc.ref.update({
          sent: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          response: response,
          error: null,
          retried: true,
        });

        retryCount++;
        console.log(`Retried push notification for doc: ${doc.id}`);
      } catch (error) {
        console.error(`Failed to retry push for doc ${doc.id}:`, error);
        // Don't update the document to retry again later
      }
    }

    console.log(`Retried ${retryCount} failed push notifications`);
  });
