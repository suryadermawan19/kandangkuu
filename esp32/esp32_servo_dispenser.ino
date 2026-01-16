/*
 * ESP32 Automatic Feed & Water Dispenser
 * Using Servo SG90 with ESP32Servo Library
 *
 * Hardware:
 * - ESP32 DevKit
 * - SG90 Servo for Feed (GPIO 13)
 * - SG90 Servo for Water (GPIO 14)
 * - WiFi connection to Firebase
 *
 * Libraries required:
 * - ESP32Servo (https://github.com/madhephaestus/ESP32Servo)
 * - WiFi (built-in)
 * - HTTPClient (built-in)
 * - ArduinoJson (https://arduinojson.org/)
 */

#include "secrets.h"
#include <ArduinoJson.h>
#include <ESP32Servo.h>
#include <HTTPClient.h>
#include <WiFi.h>

// ============ CONFIGURATION ============
// Credentials moved to secrets.h

// Firebase Cloud Function endpoint
// Note: PROJECT_ID is defined in secrets.h if you want to make the URL dynamic
// too, but for simplicity we keep the full URL construction here or hardcode
// the structure. Let's use string concatenation/formatting dynamically if
// possible, or just string.

String telemetryUrl = String("https://asia-southeast2-") + PROJECT_ID +
                      ".cloudfunctions.net/updateTelemetry";
// const char* API_KEY is defined in secrets.h

// Servo GPIO pins
const int SERVO_PAKAN_PIN = 13;
const int SERVO_AIR_PIN = 14;

// Servo angles
const int SERVO_CLOSED = 0;
const int SERVO_OPEN = 90;

// Timing constants
const unsigned long DISPENSE_TIME_MS = 5000;       // 5 seconds to dispense
const unsigned long RETURN_DELAY_MS = 500;         // Delay before returning
const unsigned long TELEMETRY_INTERVAL_MS = 10000; // Report every 10 seconds
const unsigned long FIREBASE_CHECK_INTERVAL_MS =
    2000; // Check triggers every 2 seconds

// ============ GLOBAL OBJECTS ============
Servo servoPakan;
Servo servoAir;

// State machine for non-blocking servo control
enum ServoState { IDLE, OPENING, WAITING, CLOSING, REPORTING };

// Servo Pakan state
ServoState servoPakanState = IDLE;
unsigned long servoPakanStartTime = 0;
bool servoPakanTrigger = false;

// Servo Air state
ServoState servoAirState = IDLE;
unsigned long servoAirStartTime = 0;
bool servoAirTrigger = false;

// Timing
unsigned long lastTelemetryTime = 0;
unsigned long lastFirebaseCheck = 0;

// Mock sensor data (replace with actual sensors)
float temperature = 28.5;
float humidity = 65.0;
float ammonia = 15.0;
float feedWeight = 800.0;
String waterLevel = "Cukup";

// ============ SETUP ============
void setup() {
  Serial.begin(115200);
  Serial.println("ESP32 Feed & Water Dispenser Starting...");

  // Initialize servos
  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);

  servoPakan.setPeriodHertz(50); // Standard 50Hz servo
  servoAir.setPeriodHertz(50);

  servoPakan.attach(SERVO_PAKAN_PIN, 500, 2400);
  servoAir.attach(SERVO_AIR_PIN, 500, 2400);

  // Set initial position (closed)
  servoPakan.write(SERVO_CLOSED);
  servoAir.write(SERVO_CLOSED);

  Serial.println("Servos initialized");

  // Connect to WiFi
  connectWiFi();
}

// ============ MAIN LOOP ============
void loop() {
  // Maintain WiFi connection
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
  }

  // Non-blocking servo control
  handleServoPakan();
  handleServoAir();

  // DEPRECATED: Direct Firestore polling removed for security
  // Triggers are now received in the telemetry response from Cloud Functions
  // The checkFirebaseTriggers() function is kept for reference but not called
  // if (millis() - lastFirebaseCheck >= FIREBASE_CHECK_INTERVAL_MS) {
  //   lastFirebaseCheck = millis();
  //   checkFirebaseTriggers();
  // }

  // Send telemetry periodically - triggers received in response
  if (millis() - lastTelemetryTime >= TELEMETRY_INTERVAL_MS) {
    lastTelemetryTime = millis();
    sendTelemetry(); // Response contains trigger states
  }
}

// ============ WIFI CONNECTION ============
void connectWiFi() {
  Serial.print("Connecting to WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi Connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nWiFi Connection Failed!");
  }
}

// ============ NON-BLOCKING SERVO PAKAN CONTROL ============
void handleServoPakan() {
  switch (servoPakanState) {
  case IDLE:
    if (servoPakanTrigger) {
      Serial.println("[Pakan] Starting dispense...");
      servoPakan.write(SERVO_OPEN);
      servoPakanStartTime = millis();
      servoPakanState = WAITING;
    }
    break;

  case WAITING:
    if (millis() - servoPakanStartTime >= DISPENSE_TIME_MS) {
      Serial.println("[Pakan] Dispense complete, closing...");
      servoPakan.write(SERVO_CLOSED);
      servoPakanStartTime = millis();
      servoPakanState = CLOSING;
    }
    break;

  case CLOSING:
    if (millis() - servoPakanStartTime >= RETURN_DELAY_MS) {
      Serial.println("[Pakan] Reporting completion to Firebase...");
      servoPakanTrigger = false;
      reportServoComplete("servo_pakan_trigger");
      servoPakanState = IDLE;
    }
    break;

  default:
    servoPakanState = IDLE;
    break;
  }
}

// ============ NON-BLOCKING SERVO AIR CONTROL ============
void handleServoAir() {
  switch (servoAirState) {
  case IDLE:
    if (servoAirTrigger) {
      Serial.println("[Air] Starting dispense...");
      servoAir.write(SERVO_OPEN);
      servoAirStartTime = millis();
      servoAirState = WAITING;
    }
    break;

  case WAITING:
    if (millis() - servoAirStartTime >= DISPENSE_TIME_MS) {
      Serial.println("[Air] Dispense complete, closing...");
      servoAir.write(SERVO_CLOSED);
      servoAirStartTime = millis();
      servoAirState = CLOSING;
    }
    break;

  case CLOSING:
    if (millis() - servoAirStartTime >= RETURN_DELAY_MS) {
      Serial.println("[Air] Reporting completion to Firebase...");
      servoAirTrigger = false;
      reportServoComplete("servo_air_trigger");
      servoAirState = IDLE;
    }
    break;

  default:
    servoAirState = IDLE;
    break;
  }
}

// ============ CHECK FIREBASE TRIGGERS ============
// Polls Firestore REST API to check for trigger changes
void checkFirebaseTriggers() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[Poll] WiFi not connected");
    return;
  }

  HTTPClient http;

  // Firestore REST API endpoint for the coop document
  // Format:
  // https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{collection}/{docId}
  String firestoreUrl =
      String("https://firestore.googleapis.com/v1/projects/") + PROJECT_ID +
      "/databases/(default)/documents/coops/kandang_01";

  http.begin(firestoreUrl);
  http.addHeader("Content-Type", "application/json");

  int httpCode = http.GET();

  if (httpCode == 200) {
    String response = http.getString();

    // Parse the Firestore REST API response
    StaticJsonDocument<2048> doc;
    DeserializationError error = deserializeJson(doc, response);

    if (!error) {
      // Firestore REST API returns values in a specific format
      // { "fields": { "servo_pakan_trigger": { "booleanValue": true } } }

      JsonObject fields = doc["fields"];

      // Check servo_pakan_trigger
      if (fields.containsKey("servo_pakan_trigger")) {
        bool newPakanTrigger =
            fields["servo_pakan_trigger"]["booleanValue"] | false;
        if (newPakanTrigger && !servoPakanTrigger && servoPakanState == IDLE) {
          Serial.println("[Poll] Feed trigger received!");
          servoPakanTrigger = true;
        }
      }

      // Check servo_air_trigger
      if (fields.containsKey("servo_air_trigger")) {
        bool newAirTrigger =
            fields["servo_air_trigger"]["booleanValue"] | false;
        if (newAirTrigger && !servoAirTrigger && servoAirState == IDLE) {
          Serial.println("[Poll] Water trigger received!");
          servoAirTrigger = true;
        }
      }
    } else {
      Serial.print("[Poll] JSON parse error: ");
      Serial.println(error.c_str());
    }
  } else if (httpCode == 401 || httpCode == 403) {
    Serial.println("[Poll] Auth error - Firestore may require authentication");
  } else {
    Serial.print("[Poll] HTTP Error: ");
    Serial.println(httpCode);
  }

  http.end();
}

// ============ SEND TELEMETRY TO FIREBASE ============
void sendTelemetry() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected, skipping telemetry");
    return;
  }

  HTTPClient http;
  http.begin(telemetryUrl);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("x-api-key", API_KEY);

  // Build JSON payload
  StaticJsonDocument<256> doc;
  doc["temperature"] = temperature;
  doc["humidity"] = humidity;
  doc["ammonia"] = ammonia;
  doc["feed_weight"] = feedWeight;
  doc["water_level"] = waterLevel;

  String payload;
  serializeJson(doc, payload);

  Serial.print("Sending telemetry: ");
  Serial.println(payload);

  int httpCode = http.POST(payload);

  if (httpCode > 0) {
    String response = http.getString();
    Serial.print("Response (");
    Serial.print(httpCode);
    Serial.print("): ");
    Serial.println(response);

    // Parse response for trigger updates (if included)
    parseResponseForTriggers(response);
  } else {
    Serial.print("HTTP Error: ");
    Serial.println(http.errorToString(httpCode));
  }

  http.end();
}

// ============ REPORT SERVO COMPLETION ============
void reportServoComplete(const char *triggerField) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected, cannot report servo completion");
    return;
  }

  HTTPClient http;
  http.begin(telemetryUrl);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("x-api-key", API_KEY);

  // Build JSON payload with servo trigger reset
  StaticJsonDocument<256> doc;
  doc["temperature"] = temperature;
  doc["humidity"] = humidity;
  doc["ammonia"] = ammonia;
  doc["feed_weight"] = feedWeight;
  doc["water_level"] = waterLevel;
  doc[triggerField] = false; // Reset the trigger

  String payload;
  serializeJson(doc, payload);

  Serial.print("Reporting servo complete: ");
  Serial.println(payload);

  int httpCode = http.POST(payload);

  if (httpCode > 0) {
    Serial.print("Servo report response (");
    Serial.print(httpCode);
    Serial.println(")");
  } else {
    Serial.print("HTTP Error: ");
    Serial.println(http.errorToString(httpCode));
  }

  http.end();
}

// ============ PARSE RESPONSE FOR TRIGGERS ============
// PRIMARY trigger source: Parse telemetry response from Cloud Functions
// The updateTelemetry endpoint now returns trigger states in the response
void parseResponseForTriggers(String response) {
  StaticJsonDocument<512> doc;
  DeserializationError error = deserializeJson(doc, response);

  if (!error) {
    // New format: triggers are in a nested "triggers" object
    if (doc.containsKey("triggers")) {
      JsonObject triggers = doc["triggers"];

      // Check servo_pakan_trigger
      if (triggers.containsKey("servo_pakan_trigger")) {
        bool newPakanTrigger = triggers["servo_pakan_trigger"];
        if (newPakanTrigger && !servoPakanTrigger && servoPakanState == IDLE) {
          Serial.println("[Telemetry] Feed trigger received from server!");
          servoPakanTrigger = true;
        }
      }

      // Check servo_air_trigger
      if (triggers.containsKey("servo_air_trigger")) {
        bool newAirTrigger = triggers["servo_air_trigger"];
        if (newAirTrigger && !servoAirTrigger && servoAirState == IDLE) {
          Serial.println("[Telemetry] Water trigger received from server!");
          servoAirTrigger = true;
        }
      }
    }
    // Legacy fallback: check root level (for backwards compatibility)
    else {
      if (doc.containsKey("servo_pakan_trigger")) {
        bool newPakanTrigger = doc["servo_pakan_trigger"];
        if (newPakanTrigger && !servoPakanTrigger && servoPakanState == IDLE) {
          Serial.println("Feed trigger received from server!");
          servoPakanTrigger = true;
        }
      }

      if (doc.containsKey("servo_air_trigger")) {
        bool newAirTrigger = doc["servo_air_trigger"];
        if (newAirTrigger && !servoAirTrigger && servoAirState == IDLE) {
          Serial.println("Water trigger received from server!");
          servoAirTrigger = true;
        }
      }
    }
  } else {
    Serial.print("[Telemetry] JSON parse error: ");
    Serial.println(error.c_str());
  }
}

// ============ HELPER: UPDATE MOCK SENSOR DATA ============
// In real implementation, replace these with actual sensor readings
void updateSensorData() {
  // Read from DHT22 for temperature and humidity
  // Read from MQ-135 for ammonia
  // Read from load cell for feed weight
  // Read from water level sensor for water level

  // Mock: simulate decreasing feed weight
  feedWeight -= 10;
  if (feedWeight < 0)
    feedWeight = 1000;
}
