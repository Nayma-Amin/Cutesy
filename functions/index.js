const {setGlobalOptions} = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({maxInstances: 10});

exports.sendOrderNotification = onDocumentCreated(
    "notifications_queue/{id}",
    async (event) => {
      try {
        const data = event.data.data();
        if (!data) return;

        const {orderId, status} = data;

        const orderSnap = await admin
            .firestore()
            .collection("orders")
            .doc(orderId)
            .get();

        if (!orderSnap.exists) {
          logger.warn("Order not found", {orderId});
          return;
        }

        const order = orderSnap.data();
        const userId = order.userId;

        const userSnap = await admin
            .firestore()
            .collection("users")
            .doc(userId)
            .get();

        if (!userSnap.exists) {
          logger.warn("User not found", {userId});
          return;
        }

        const token = userSnap.data().fcmToken;
        if (!token) {
          logger.warn("No FCM token", {userId});
          return;
        }

        await admin.messaging().send({
          token,
          notification: {
            title: "Order Update",
            body: `Your order is now ${status}`,
          },
          data: {
            orderId,
            status,
          },
        });

        await event.data.ref.delete();

        logger.info("Notification sent", {orderId, status});
      } catch (error) {
        logger.error("Notification failed", error);
      }
    },
);
