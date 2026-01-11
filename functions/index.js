const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.checkCriticalConditions = functions.firestore
    .document("coops/kandang_01")
    .onUpdate(async (change, context) => {
      const newData = change.after.data();
      const previousData = change.before.data();

      const ammonia = newData.ammonia || 0;
      const temp = newData.temperature || 0;

      // Check thresholds: Ammonia > 20 or Temp > 30
      const isAmmoniaCritical = ammonia > 20;
      const isTempCritical = temp > 30;

      // Optional: Prevent spamming by checking if it was already critical
      // But prompt asks to trigger if condition is met. 
      // A simple check is to send only if it wasn't critical efficiently or just send every update (noisy).
      // Let's implement basic filtering to avoid noise if values barely changed but still critical,
      // OR better, we send the notification. The prompt says "If ammonia > 20... trigger".

      if (isAmmoniaCritical || isTempCritical) {
        let title = "Critical Alert: PoultryVision";
        let body = "";

        if (isAmmoniaCritical && isTempCritical) {
          body = `Warning: High Ammonia (${ammonia} ppm) and Temperature (${temp}°C) detected!`;
        } else if (isAmmoniaCritical) {
          body = `Warning: High Ammonia level detected: ${ammonia} ppm.`;
        } else if (isTempCritical) {
          body = `Warning: High Temperature detected: ${temp}°C.`;
        }

        const payload = {
          notification: {
            title: title,
            body: body,
            sound: "default",
          },
          topic: "alerts",
        };

        try {
          const response = await admin.messaging().send(payload);
          console.log("Successfully sent message:", response);
        } catch (error) {
          console.log("Error sending message:", error);
        }
      }
    });
