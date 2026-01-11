const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();

// Set global options for region
setGlobalOptions({ region: 'asia-southeast2' });

const HYSTERESIS_BUFFER_TEMP = 2.0;
const HYSTERESIS_BUFFER_AMMONIA = 2.0;
const MIN_RUN_TIME_MS = 5 * 60 * 1000; // 5 minutes

exports.checkConditionsAndAutomate = onDocumentUpdated("coops/kandang_01", async (event) => {
  if (!event.data) return null;

  const newData = event.data.after.data();
  const previousData = event.data.before.data();

  // Ensure data integrity
  if (!newData) return null;

  const ammonia = newData.ammonia || 0;
  const temp = newData.temperature || 0;
  const visionScore = newData.vision_score || 0;
  const feedWeight = newData.feed_weight || 0;
  const waterLevel = newData.water_level || "Unknown";

  // Explicit check for is_auto_mode boolean
  const isAutoMode = newData.is_auto_mode === true;

  const updates = {};
  let stateChanged = false;

  // --- AUTOMATION LOGIC ---
  if (isAutoMode) {
    const currentFanState = newData.fan_status || false;
    const currentHeaterState = newData.heater_status || false;

    // Fan Logic
    const needsFan = ammonia > 20 || temp > 30;
    let newFanState = currentFanState;

    const lastFanToggle = newData.last_fan_toggle_timestamp ? newData.last_fan_toggle_timestamp.toDate().getTime() : 0;
    const now = Date.now();
    const fanTimePassed = (now - lastFanToggle) >= MIN_RUN_TIME_MS;

    if (currentFanState) {
      const safeToTurnOff = ammonia < (20 - HYSTERESIS_BUFFER_AMMONIA) && temp < (30 - HYSTERESIS_BUFFER_TEMP);
      if (safeToTurnOff && fanTimePassed) {
        newFanState = false;
      }
    } else {
      if (needsFan && fanTimePassed) {
        newFanState = true;
      }
    }

    if (newFanState !== currentFanState) {
      updates.fan_status = newFanState;
      updates.last_fan_toggle_timestamp = admin.firestore.Timestamp.now();
      stateChanged = true;
    }

    // Heater Logic
    const needsHeater = temp < 24 || visionScore < 40;
    let newHeaterState = currentHeaterState;

    const lastHeaterToggle = newData.last_heater_toggle_timestamp ? newData.last_heater_toggle_timestamp.toDate().getTime() : 0;
    const heaterTimePassed = (now - lastHeaterToggle) >= MIN_RUN_TIME_MS;

    if (currentHeaterState) {
      const safeToTurnOff = temp > (24 + HYSTERESIS_BUFFER_TEMP) && visionScore >= 40;
      if (safeToTurnOff && heaterTimePassed) {
        newHeaterState = false;
      }
    } else {
      if (needsHeater && heaterTimePassed) {
        newHeaterState = true;
      }
    }

    if (newHeaterState !== currentHeaterState) {
      updates.heater_status = newHeaterState;
      updates.last_heater_toggle_timestamp = admin.firestore.Timestamp.now();
      stateChanged = true;
    }
  }

  // --- ALERT LOGIC ---
  const prevAmmonia = previousData ? (previousData.ammonia || 0) : 0;
  const prevTemp = previousData ? (previousData.temperature || 0) : 0;
  const prevFeed = previousData ? (previousData.feed_weight || 0) : 0;
  const prevWater = previousData ? (previousData.water_level || "Unknown") : "Unknown";

  const sendAlerts = [];

  // Alert logic as requested: Temp > 30, Ammonia > 20, Feed < 1.0, Water Empty
  if (ammonia > 20 && prevAmmonia <= 20) sendAlerts.push(`High Ammonia: ${ammonia} ppm`);
  if (temp > 30 && prevTemp <= 30) sendAlerts.push(`High Temperature: ${temp}°C`);
  if (feedWeight < 1.0 && prevFeed >= 1.0) sendAlerts.push(`Low Feed: ${feedWeight} kg`);
  if (waterLevel === 'Empty' && prevWater !== 'Empty') sendAlerts.push(`Water Level Empty!`);

  if (sendAlerts.length > 0) {
    const body = sendAlerts.join("\n");
    const payload = {
      notification: {
        title: "PoultryVision Alert",
        body: body,
        sound: "default"
      },
      topic: "alerts"
    };
    try {
      await admin.messaging().send(payload);
      console.log("Alert sent:", body);
    } catch (e) {
      console.error("Error sending alert:", e);
    }
  }

  if (stateChanged) {
    return event.data.after.ref.update(updates);
  }
  return null;
});

// Scheduled Function: Daily Aggregation at Midnight
// Requires Blaze Plan
exports.dailyStats = onSchedule({
  schedule: '0 0 * * *',
  timeZone: 'Asia/Jakarta'
}, async (event) => {
  const now = admin.firestore.Timestamp.now();
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const startOfYesterday = admin.firestore.Timestamp.fromDate(new Date(yesterday.setHours(0, 0, 0, 0)));
  const endOfYesterday = admin.firestore.Timestamp.fromDate(new Date(yesterday.setHours(23, 59, 59, 999)));

  const historyRef = admin.firestore().collection('telemetry_history');

  try {
    const snapshot = await historyRef
      .where('timestamp', '>=', startOfYesterday)
      .where('timestamp', '<=', endOfYesterday)
      .get();

    if (snapshot.empty) {
      console.log('No data found for yesterday.');
      return null;
    }

    let totalTemp = 0;
    let totalAmmonia = 0;
    let count = 0;

    snapshot.forEach(doc => {
      const data = doc.data();
      totalTemp += (data.temperature || 0);
      totalAmmonia += (data.ammonia || 0);
      count++;
    });

    const avgTemp = totalTemp / count;
    const avgAmmonia = totalAmmonia / count;

    await admin.firestore().collection('daily_stats').add({
      date: startOfYesterday,
      avg_temperature: avgTemp,
      avg_ammonia: avgAmmonia,
      reading_count: count,
      created_at: now
    });

    console.log(`Daily stats verified: Temp ${avgTemp}, Ammonia ${avgAmmonia}`);
    return null;
  } catch (error) {
    console.error('Error in dailyStats:', error);
    return null;
  }
});
