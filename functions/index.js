const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { setGlobalOptions } = require('firebase-functions/v2');
const { onRequest } = require('firebase-functions/v2/https');
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

  // --- FETCH DYNAMIC THRESHOLDS FROM FIRESTORE ---
  let maxTemp = 30.0;  // Default
  let maxAmmonia = 20.0;  // Default

  try {
    const configDoc = await admin.firestore().collection('config').doc('thresholds').get();
    if (configDoc.exists) {
      const configData = configDoc.data();
      maxTemp = configData.max_temperature || 30.0;
      maxAmmonia = configData.max_ammonia || 20.0;
    }
  } catch (e) {
    console.error("Error fetching thresholds config:", e);
    // Continue with defaults
  }

  const ammonia = newData.ammonia || 0;
  const temp = newData.temperature || 0;
  const visionScore = newData.vision_score || 0;
  const feedWeight = newData.feed_weight || 0;
  const waterLevel = newData.water_level || "Unknown";

  // Explicit check for is_auto_mode boolean
  const isAutoMode = newData.is_auto_mode === true;

  const updates = {};
  let stateChanged = false;

  // --- AUTOMATION LOGIC (Using Dynamic Thresholds) ---
  if (isAutoMode) {
    const currentFanState = newData.fan_status || false;
    const currentHeaterState = newData.heater_status || false;

    // Fan Logic - Using dynamic thresholds
    const needsFan = ammonia > maxAmmonia || temp > maxTemp;
    let newFanState = currentFanState;

    const lastFanToggle = newData.last_fan_toggle_timestamp ? newData.last_fan_toggle_timestamp.toDate().getTime() : 0;
    const now = Date.now();
    const fanTimePassed = (now - lastFanToggle) >= MIN_RUN_TIME_MS;

    if (currentFanState) {
      const safeToTurnOff = ammonia < (maxAmmonia - HYSTERESIS_BUFFER_AMMONIA) && temp < (maxTemp - HYSTERESIS_BUFFER_TEMP);
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

  // --- ALERT LOGIC (Using Dynamic Thresholds) ---
  const prevAmmonia = previousData ? (previousData.ammonia || 0) : 0;
  const prevTemp = previousData ? (previousData.temperature || 0) : 0;
  const prevFeed = previousData ? (previousData.feed_weight || 0) : 0;
  const prevWater = previousData ? (previousData.water_level || "Unknown") : "Unknown";

  const sendAlerts = [];

  // Alert logic using dynamic thresholds
  if (ammonia > maxAmmonia && prevAmmonia <= maxAmmonia) sendAlerts.push(`High Ammonia: ${ammonia} ppm`);
  if (temp > maxTemp && prevTemp <= maxTemp) sendAlerts.push(`High Temperature: ${temp}°C`);
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
      .where('last_update', '>=', startOfYesterday)
      .where('last_update', '<=', endOfYesterday)
      .get();

    if (snapshot.empty) {
      console.log('No data found for yesterday.');
      return null;
    }

    let totalTemp = 0;
    let totalAmmonia = 0;
    let totalHumidity = 0;
    let count = 0;

    snapshot.forEach(doc => {
      const data = doc.data();
      totalTemp += (data.temperature || 0);
      totalAmmonia += (data.ammonia || 0);
      totalHumidity += (data.humidity || 0);
      count++;
    });

    const avgTemp = totalTemp / count;
    const avgAmmonia = totalAmmonia / count;
    const avgHumidity = totalHumidity / count;

    await admin.firestore().collection('daily_stats').add({
      date: startOfYesterday,
      avg_temperature: avgTemp,
      avg_ammonia: avgAmmonia,
      avg_humidity: avgHumidity,
      reading_count: count,
      created_at: now
    });

    console.log(`Daily stats verified: Temp ${avgTemp}, Ammonia ${avgAmmonia}, Humidity ${avgHumidity}`);
    return null;
  } catch (error) {
    console.error('Error in dailyStats:', error);
    return null;
  }
});

// HTTP Function to receive telemetry from IoT device
// Secured with API Key validation
exports.updateTelemetry = onRequest({ cors: true }, async (request, response) => {
  // Check for POST method
  if (request.method !== 'POST') {
    response.status(405).send('Method Not Allowed');
    return;
  }

  // --- API KEY VALIDATION ---
  // The API key should be set via: firebase functions:config:set iot.api_key="your-secret-key"
  // Or use defineSecret() for better security in production
  const apiKey = request.headers['x-api-key'];
  const EXPECTED_API_KEY = process.env.IOT_API_KEY || 'kandangku-iot-secret-2026';

  if (!apiKey || apiKey !== EXPECTED_API_KEY) {
    console.warn('Unauthorized telemetry attempt from:', request.ip);
    response.status(401).json({
      status: 'error',
      message: 'Unauthorized: Invalid or missing API Key'
    });
    return;
  }

  const { temperature, humidity, ammonia, feed_weight, water_level } = request.body;

  // Basic validation
  if (temperature === undefined || humidity === undefined || ammonia === undefined) {
    response.status(400).send('Missing required fields: temperature, humidity, ammonia');
    return;
  }

  try {
    const timestamp = admin.firestore.Timestamp.now();
    const batch = admin.firestore().batch();

    // 1. Update Current State
    const coopRef = admin.firestore().collection('coops').doc('kandang_01');
    batch.set(coopRef, {
      temperature: Number(temperature),
      humidity: Number(humidity),
      ammonia: Number(ammonia),
      feed_weight: feed_weight !== undefined ? Number(feed_weight) : 0,
      water_level: water_level !== undefined ? String(water_level) : 'Unknown',
      last_update: timestamp
    }, { merge: true });

    // 2. Add History Entry
    const historyRef = admin.firestore().collection('telemetry_history').doc();
    batch.set(historyRef, {
      temperature: Number(temperature),
      humidity: Number(humidity),
      ammonia: Number(ammonia),
      feed_weight: feed_weight !== undefined ? Number(feed_weight) : 0,
      water_level: water_level !== undefined ? String(water_level) : 'Unknown',
      last_update: timestamp
    });

    await batch.commit();

    response.status(200).json({ status: 'success', message: 'Telemetry updated' });
  } catch (error) {
    console.error('Error updating telemetry:', error);
    response.status(500).send('Internal Server Error');
  }
});
