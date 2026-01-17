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
const SERVO_TIMEOUT_MS = 60 * 1000; // 60 seconds - auto-reset if ESP32 doesn't respond
const SERVO_COOLDOWN_MS = 10 * 60 * 1000; // 10 minutes - prevent rapid re-trigger

exports.checkConditionsAndAutomate = onDocumentUpdated("coops/kandang_01", async (event) => {
  if (!event.data) return null;

  const newData = event.data.after.data();
  const previousData = event.data.before.data();

  // Ensure data integrity
  if (!newData) return null;

  // --- FETCH DYNAMIC THRESHOLDS FROM FIRESTORE ---
  let maxTemp = 30.0;  // Default
  let maxAmmonia = 20.0;  // Default
  let minFeedThreshold = 500.0;  // Default feed threshold in grams

  try {
    const configDoc = await admin.firestore().collection('config').doc('thresholds').get();
    if (configDoc.exists) {
      const configData = configDoc.data();
      maxTemp = configData.max_temperature || 30.0;
      maxAmmonia = configData.max_ammonia || 20.0;
      minFeedThreshold = configData.min_feed_threshold || 500.0;
    }
  } catch (e) {
    console.error("Error fetching thresholds config:", e);
    // Continue with defaults
  }

  const ammonia = newData.ammonia || 0;
  const temp = newData.temperature || 0;
  const visionScore = newData.vision_score || 0;
  const feedWeight = newData.feed_weight || 0;  // Assumed to be in grams
  const waterLevel = newData.water_level || "Unknown";

  // Explicit check for is_auto_mode boolean
  const isAutoMode = newData.is_auto_mode === true;

  // Current servo trigger states
  const currentServoPakan = newData.servo_pakan_trigger === true;
  const currentServoAir = newData.servo_air_trigger === true;

  const updates = {};
  let stateChanged = false;
  const now = Date.now();

  // --- SERVO TIMEOUT LOGIC (P1 Fix) ---
  // Auto-reset stuck servo triggers if ESP32 fails to respond
  const servoPakanTimestamp = newData.servo_pakan_timestamp?.toDate()?.getTime() || 0;
  const servoAirTimestamp = newData.servo_air_timestamp?.toDate()?.getTime() || 0;

  if (currentServoPakan && servoPakanTimestamp > 0 && (now - servoPakanTimestamp) > SERVO_TIMEOUT_MS) {
    updates.servo_pakan_trigger = false;
    updates.servo_pakan_timeout = true; // Flag for alerting
    stateChanged = true;
    console.warn('Servo pakan trigger timeout - auto-reset after 60s');
  }

  if (currentServoAir && servoAirTimestamp > 0 && (now - servoAirTimestamp) > SERVO_TIMEOUT_MS) {
    updates.servo_air_trigger = false;
    updates.servo_air_timeout = true; // Flag for alerting
    stateChanged = true;
    console.warn('Servo air trigger timeout - auto-reset after 60s');
  }

  // --- SERVO AUTOMATION LOGIC ---
  if (isAutoMode) {
    // Check cooldown timestamps
    const lastServoPakanDispense = newData.last_servo_pakan_dispense?.toDate()?.getTime() || 0;
    const lastServoAirDispense = newData.last_servo_air_dispense?.toDate()?.getTime() || 0;
    const pakanCooldownPassed = (now - lastServoPakanDispense) > SERVO_COOLDOWN_MS;
    const airCooldownPassed = (now - lastServoAirDispense) > SERVO_COOLDOWN_MS;

    // Servo Pakan: Trigger when feed is below threshold, not triggered, and cooldown passed
    if (feedWeight < minFeedThreshold && !currentServoPakan && pakanCooldownPassed) {
      updates.servo_pakan_trigger = true;
      updates.servo_pakan_timestamp = admin.firestore.Timestamp.now();
      updates.last_servo_pakan_dispense = admin.firestore.Timestamp.now();
      stateChanged = true;
      console.log(JSON.stringify({
        event: "servo_trigger",
        actuator: "servo_pakan",
        reason: "Low Feed",
        feedWeight: feedWeight,
        threshold: minFeedThreshold,
        timestamp: new Date().toISOString()
      }));
    }

    // Servo Air: Trigger when water level is "Habis", not triggered, and cooldown passed
    if (waterLevel === 'Habis' && !currentServoAir && airCooldownPassed) {
      updates.servo_air_trigger = true;
      updates.servo_air_timestamp = admin.firestore.Timestamp.now();
      updates.last_servo_air_dispense = admin.firestore.Timestamp.now();
      stateChanged = true;
      console.log(JSON.stringify({
        event: "servo_trigger",
        actuator: "servo_air",
        reason: "Water Empty",
        waterLevel: waterLevel,
        timestamp: new Date().toISOString()
      }));
    }
  }

  // --- AUTOMATION LOGIC (Using Dynamic Thresholds) ---
  if (isAutoMode) {
    const currentFanState = newData.is_fan_on || false;
    const currentHeaterState = newData.is_heater_on || false;

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
      updates.is_fan_on = newFanState;
      updates.last_fan_toggle_timestamp = admin.firestore.Timestamp.now();
      stateChanged = true;
      console.log(JSON.stringify({
        event: "actuator_toggle",
        actuator: "fan",
        newState: newFanState ? "ON" : "OFF",
        reason: needsFan ? "Threshold Exceeded" : "Safe/Manual",
        ammonia: ammonia,
        temp: temp,
        timestamp: new Date().toISOString()
      }));
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
      updates.is_heater_on = newHeaterState;
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

  // Alert logic using dynamic thresholds (Bahasa Indonesia)
  if (ammonia > maxAmmonia && prevAmmonia <= maxAmmonia) sendAlerts.push(`Amonia Tinggi: ${ammonia} ppm`);
  if (temp > maxTemp && prevTemp <= maxTemp) sendAlerts.push(`Suhu Tinggi: ${temp}°C`);
  if (feedWeight < 100 && prevFeed >= 100) sendAlerts.push(`Pakan Hampir Habis: ${feedWeight}g`);
  if (waterLevel === 'Habis' && prevWater !== 'Habis') sendAlerts.push(`Air Habis!`);

  if (sendAlerts.length > 0) {
    const body = sendAlerts.join("\n");

    // FCM v1 Message format (proper structure)
    const message = {
      notification: {
        title: "PoultryVision Alert",
        body: body,
      },
      android: {
        notification: {
          sound: "default",
          priority: "high",
          channelId: "alerts"
        }
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1
          }
        }
      },
      topic: "alerts"
    };

    try {
      await admin.messaging().send(message);
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

// Rate Limiting Map (Global scope persists across warm invocations)
const rateLimit = new Map();
const RATE_LIMIT_WINDOW_MS = 1000; // 1 second

// HTTP Function to check system health
exports.healthCheck = onRequest({ cors: true }, async (request, response) => {
  try {
    const timestamp = admin.firestore.Timestamp.now();
    const coopDoc = await admin.firestore().collection('coops').doc('kandang_01').get();

    let lastTelemetry = "Never";
    let isHealthy = true;

    if (coopDoc.exists) {
      const data = coopDoc.data();
      if (data.last_update) {
        lastTelemetry = data.last_update.toDate().toISOString();

        // System is "unhealthy" if no data for > 30 mins
        const diff = Date.now() - data.last_update.toDate().getTime();
        if (diff > 30 * 60 * 1000) {
          isHealthy = false;
        }
      }
    }

    response.status(200).json({
      status: isHealthy ? 'healthy' : 'degraded',
      timestamp: timestamp.toDate().toISOString(),
      last_telemetry: lastTelemetry,
      uptime: process.uptime(),
      version: '1.0.0'
    });
  } catch (error) {
    console.error('Health check failed:', error);
    response.status(500).json({ status: 'error', message: error.message });
  }
});

// HTTP Function to receive telemetry from IoT device
// Secured with API Key validation and Rate Limiting
exports.updateTelemetry = onRequest({ cors: true }, async (request, response) => {
  // Check for POST method
  if (request.method !== 'POST') {
    response.status(405).send('Method Not Allowed');
    return;
  }

  // --- RATE LIMITING ---
  const ip = request.ip;
  const now = Date.now();
  if (rateLimit.has(ip)) {
    const lastRequest = rateLimit.get(ip);
    if (now - lastRequest < RATE_LIMIT_WINDOW_MS) {
      console.warn(`Rate limit exceeded for IP: ${ip}`);
      response.status(429).json({ status: 'error', message: 'Too Many Requests' });
      return;
    }
  }
  rateLimit.set(ip, now);

  // Cleanup old rate limit entries periodically (optional, simple safeguard for memory)
  if (rateLimit.size > 1000) {
    rateLimit.clear();
  }

  // --- API KEY VALIDATION ---
  // The API key MUST be set via environment variable (no fallback for security)
  // Set via: firebase functions:config:set iot.api_key="your-secret-key"
  // Then access via: process.env.IOT_API_KEY
  const apiKey = request.headers['x-api-key'];
  const EXPECTED_API_KEY = process.env.IOT_API_KEY;

  // CRITICAL: API key must be configured, no fallback allowed
  if (!EXPECTED_API_KEY) {
    console.error('SECURITY: IOT_API_KEY environment variable not configured!');
    response.status(500).json({
      status: 'error',
      message: 'Server misconfigured - contact administrator'
    });
    return;
  }

  if (!apiKey || apiKey !== EXPECTED_API_KEY) {
    console.warn('Unauthorized telemetry attempt from:', request.ip);
    response.status(401).json({
      status: 'error',
      message: 'Unauthorized: Invalid or missing API Key'
    });
    return;
  }

  const { temperature, humidity, ammonia, feed_weight, water_level, servo_pakan_trigger, servo_air_trigger } = request.body;

  // ============ ENHANCED INPUT VALIDATION ============
  // Helper function to validate numeric values
  const validateNumber = (val, name, min, max) => {
    const num = Number(val);
    if (isNaN(num)) {
      throw new Error(`${name} must be a valid number`);
    }
    if (num < min || num > max) {
      throw new Error(`${name} out of valid range (${min}-${max})`);
    }
    return num;
  };

  // Basic presence check
  if (temperature === undefined || humidity === undefined || ammonia === undefined) {
    response.status(400).json({
      status: 'error',
      message: 'Missing required fields: temperature, humidity, ammonia'
    });
    return;
  }

  // Type and range validation
  let validatedData;
  try {
    validatedData = {
      temperature: validateNumber(temperature, 'temperature', -10, 60),
      humidity: validateNumber(humidity, 'humidity', 0, 100),
      ammonia: validateNumber(ammonia, 'ammonia', 0, 500),
      feed_weight: feed_weight !== undefined ? validateNumber(feed_weight, 'feed_weight', 0, 10000) : 0,
      water_level: water_level !== undefined ? String(water_level).substring(0, 50) : 'Unknown',
    };
  } catch (validationError) {
    console.warn('Validation failed:', validationError.message, 'from:', request.ip);
    response.status(400).json({
      status: 'error',
      message: validationError.message
    });
    return;
  }

  try {
    const timestamp = admin.firestore.Timestamp.now();
    const batch = admin.firestore().batch();

    // 1. Update Current State (using validated data)
    const coopRef = admin.firestore().collection('coops').doc('kandang_01');
    const updateData = {
      temperature: validatedData.temperature,
      humidity: validatedData.humidity,
      ammonia: validatedData.ammonia,
      feed_weight: validatedData.feed_weight,
      water_level: validatedData.water_level,
      last_update: timestamp
    };

    // Handle servo trigger resets from ESP32 (after completing dispense action)
    if (servo_pakan_trigger !== undefined) {
      updateData.servo_pakan_trigger = Boolean(servo_pakan_trigger);
    }
    if (servo_air_trigger !== undefined) {
      updateData.servo_air_trigger = Boolean(servo_air_trigger);
    }

    batch.set(coopRef, updateData, { merge: true });

    // 2. Add History Entry (using validated data)
    const historyRef = admin.firestore().collection('telemetry_history').doc();
    batch.set(historyRef, {
      temperature: validatedData.temperature,
      humidity: validatedData.humidity,
      ammonia: validatedData.ammonia,
      feed_weight: validatedData.feed_weight,
      water_level: validatedData.water_level,
      last_update: timestamp
    });

    await batch.commit();

    // 3. Fetch current trigger states to return to ESP32
    // This allows ESP32 to receive commands without polling Firestore directly
    const currentDoc = await admin.firestore().collection('coops').doc('kandang_01').get();
    const currentData = currentDoc.data() || {};

    response.status(200).json({
      status: 'success',
      message: 'Telemetry updated',
      // Return trigger states for ESP32 servo control
      triggers: {
        servo_pakan_trigger: currentData.servo_pakan_trigger || false,
        servo_air_trigger: currentData.servo_air_trigger || false
      },
      // Return actuator states for ESP32 relay control (fan & heater)
      actuators: {
        fan: currentData.is_fan_on === true,
        heater: currentData.is_heater_on === true
      }
    });
  } catch (error) {
    console.error('Error updating telemetry:', error);
    response.status(500).send('Internal Server Error');
  }
});

// ============ P1 FIX: TELEMETRY CLEANUP ============
// Scheduled Function: Clean up old telemetry data
// Runs daily at 2 AM Jakarta time, deletes records older than 30 days
exports.cleanupOldTelemetry = onSchedule({
  schedule: '0 2 * * *', // 2 AM daily
  timeZone: 'Asia/Jakarta'
}, async (event) => {
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 30); // Keep last 30 days
  const cutoffTimestamp = admin.firestore.Timestamp.fromDate(cutoff);

  console.log(`Cleaning up telemetry older than: ${cutoff.toISOString()}`);

  const historyRef = admin.firestore().collection('telemetry_history');

  try {
    // Process in batches to avoid timeout
    let totalDeleted = 0;
    let hasMore = true;

    while (hasMore) {
      const snapshot = await historyRef
        .where('last_update', '<', cutoffTimestamp)
        .limit(500) // Batch size
        .get();

      if (snapshot.empty) {
        hasMore = false;
        break;
      }

      const batch = admin.firestore().batch();
      snapshot.docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();

      totalDeleted += snapshot.size;
      console.log(`Deleted batch of ${snapshot.size} records`);

      // If we got less than limit, we're done
      if (snapshot.size < 500) {
        hasMore = false;
      }
    }

    console.log(`Telemetry cleanup complete. Total deleted: ${totalDeleted}`);
    return null;
  } catch (error) {
    console.error('Error in cleanupOldTelemetry:', error);
    return null;
  }
});
