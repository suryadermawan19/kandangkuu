/*
 * POULTRY VISION - FULL FIRMWARE
 * Board: ESP32 DevKitC V4
 * * Update: Integrasi Servo, Sensor SHT31, MQ135, LoadCell, dan Relay.
 */

#include "HX711.h"
#include "secrets.h" // Pastikan file secrets.h ada (isi SSID, Pass, API Key)
#include <Adafruit_SHT31.h>
#include <ArduinoJson.h>
#include <ESP32Servo.h>
#include <HTTPClient.h>
#include <WiFi.h>
#include <Wire.h>


// ============ KONFIGURASI PIN (WIRING DEVKIT V4) ============
// I2C Sensor (SHT31)
#define PIN_SDA 21
#define PIN_SCL 22

// Analog Sensors
#define PIN_MQ135 34       // Input Only
#define PIN_WATER_LEVEL 35 // Input Only

// Load Cell (HX711)
#define PIN_LOADCELL_DT 18
#define PIN_LOADCELL_SCK 19

// Actuators (Output)
#define PIN_RELAY_FAN 25
#define PIN_RELAY_HEATER 26
#define PIN_SERVO_PAKAN 27
#define PIN_SERVO_AIR 14

// ============ KONSTANTA KALIBRASI ============
// Ganti nilai ini dengan hasil kalibrasi Load Cell kamu
const float LOADCELL_CALIBRATION_FACTOR = 420.0;
// Ambang batas level air (0-4095)
const int WATER_LEVEL_THRESHOLD = 1500;

// ============ OBJEK GLOBAL ============
Adafruit_SHT31 sht31 = Adafruit_SHT31();
HX711 scale;
Servo servoPakan;
Servo servoAir;

// ============ VARIABEL STATE ============
// Servo State Machine
enum ServoState { IDLE, OPENING, WAITING, CLOSING, DONE };
ServoState pakanState = IDLE;
ServoState airState = IDLE;
unsigned long pakanTimer = 0;
unsigned long airTimer = 0;
bool triggerPakan = false;
bool triggerAir = false;

// Konstanta Servo
const int SERVO_CLOSE_ANGLE = 0;
const int SERVO_OPEN_ANGLE = 90;
const unsigned long DISPENSE_DURATION = 5000; // 5 Detik buka

// Timer Telemetry
unsigned long lastTelemetryTime = 0;
const unsigned long TELEMETRY_INTERVAL = 5000; // Kirim data tiap 5 detik

// URL Cloud Functions (Diambil dari secrets.h atau hardcode)
String telemetryUrl = String("https://asia-southeast2-") + PROJECT_ID +
                      ".cloudfunctions.net/updateTelemetry";

void setup() {
  Serial.begin(115200);
  Serial.println("\n🚀 PoultryVision Starting...");

  // 1. Setup Pin Output
  pinMode(PIN_RELAY_FAN, OUTPUT);
  pinMode(PIN_RELAY_HEATER, OUTPUT);
  // Matikan relay saat start (Active LOW/HIGH tergantung modul, asumsi HIGH=ON)
  digitalWrite(PIN_RELAY_FAN, LOW);
  digitalWrite(PIN_RELAY_HEATER, LOW);

  // 2. Setup Servo
  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  servoPakan.setPeriodHertz(50);
  servoAir.setPeriodHertz(50);
  servoPakan.attach(PIN_SERVO_PAKAN, 500, 2400);
  servoAir.attach(PIN_SERVO_AIR, 500, 2400);

  // Posisi awal tertutup
  servoPakan.write(SERVO_CLOSE_ANGLE);
  servoAir.write(SERVO_CLOSE_ANGLE);

  // 3. Setup Sensors
  Wire.begin(PIN_SDA, PIN_SCL);
  if (!sht31.begin(0x44)) {
    Serial.println("⚠️ Warning: SHT31 tidak ditemukan!");
  }

  scale.begin(PIN_LOADCELL_DT, PIN_LOADCELL_SCK);
  scale.set_scale(LOADCELL_CALIBRATION_FACTOR);
  scale.tare(); // Reset berat ke 0 saat nyala (pastikan wadah kosong saat
                // boot/atau sesuaikan logika)

  // 4. Koneksi WiFi
  connectWiFi();
}

void loop() {
  // Reconnect WiFi jika putus
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
  }

  // Handle Logic Servo (Non-blocking)
  handleServoPakanLogic();
  handleServoAirLogic();

  // Kirim Telemetry + Terima Perintah (Relay & Servo)
  if (millis() - lastTelemetryTime >= TELEMETRY_INTERVAL) {
    lastTelemetryTime = millis();
    sendTelemetryAndGetTriggers();
  }
}

// ============ FUNGSI LOGIKA SERVO ============
void handleServoPakanLogic() {
  switch (pakanState) {
  case IDLE:
    if (triggerPakan) {
      Serial.println("[PAKAN] Membuka katup...");
      servoPakan.write(SERVO_OPEN_ANGLE);
      pakanTimer = millis();
      pakanState = WAITING;
    }
    break;
  case WAITING:
    if (millis() - pakanTimer >= DISPENSE_DURATION) {
      Serial.println("[PAKAN] Menutup katup...");
      servoPakan.write(SERVO_CLOSE_ANGLE);
      pakanState = DONE; // Menandakan selesai, perlu lapor ke server
    }
    break;
  case DONE:
    // Status 'DONE' akan memicu pengiriman laporan 'servo_pakan_trigger: false'
    // di fungsi sendTelemetryAndGetTriggers selanjutnya.
    triggerPakan = false; // Reset trigger lokal
    pakanState = IDLE;
    break;
  }
}

void handleServoAirLogic() {
  switch (airState) {
  case IDLE:
    if (triggerAir) {
      Serial.println("[AIR] Membuka katup...");
      servoAir.write(SERVO_OPEN_ANGLE);
      airTimer = millis();
      airState = WAITING;
    }
    break;
  case WAITING:
    if (millis() - airTimer >= DISPENSE_DURATION) {
      Serial.println("[AIR] Menutup katup...");
      servoAir.write(SERVO_CLOSE_ANGLE);
      airState = DONE;
    }
    break;
  case DONE:
    triggerAir = false;
    airState = IDLE;
    break;
  }
}

// ============ BACA SENSOR & KIRIM DATA ============
void sendTelemetryAndGetTriggers() {
  // 1. Baca Semua Sensor
  float temp = sht31.readTemperature();
  float hum = sht31.readHumidity();

  // Baca MQ135 (Raw Analog -> Map ke PPM kasar)
  int mqRaw = analogRead(PIN_MQ135);
  float ammonia = map(mqRaw, 0, 4095, 0, 100); // Kalibrasi manual nanti

  // Baca Load Cell (Berat dalam Gram)
  float weight = scale.get_units(5);
  if (weight < 0)
    weight = 0;

  // Baca Water Level
  int waterRaw = analogRead(PIN_WATER_LEVEL);
  String waterStatus = (waterRaw > WATER_LEVEL_THRESHOLD) ? "Cukup" : "Habis";

  // Cek validitas SHT31
  if (isnan(temp))
    temp = 0;
  if (isnan(hum))
    hum = 0;

  // 2. Buat JSON Payload
  StaticJsonDocument<512> doc;
  doc["temperature"] = temp;
  doc["humidity"] = hum;
  doc["ammonia"] = ammonia;
  doc["feed_weight"] = weight;
  doc["water_level"] = waterStatus;

  // Jika servo baru saja selesai bekerja, lapor balik untuk mematikan trigger
  // di server
  if (pakanState == DONE)
    doc["servo_pakan_trigger"] = false;
  if (airState == DONE)
    doc["servo_air_trigger"] = false;

  String payload;
  serializeJson(doc, payload);

  // 3. Kirim ke Cloud Functions
  HTTPClient http;
  http.begin(telemetryUrl);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("x-api-key", API_KEY); // Dari secrets.h

  int httpCode = http.POST(payload);

  // 4. Proses Respons (Perintah dari Server)
  if (httpCode == 200) {
    String response = http.getString();
    // Serial.println("Respon Server: " + response); // Debugging

    StaticJsonDocument<1024> respDoc;
    deserializeJson(respDoc, response);

    // Ambil Data Triggers (Servo)
    JsonObject triggers = respDoc["triggers"];
    if (triggers.containsKey("servo_pakan_trigger")) {
      bool serverCmd = triggers["servo_pakan_trigger"];
      if (serverCmd && pakanState == IDLE)
        triggerPakan = true;
    }
    if (triggers.containsKey("servo_air_trigger")) {
      bool serverCmd = triggers["servo_air_trigger"];
      if (serverCmd && airState == IDLE)
        triggerAir = true;
    }

    // Ambil Data Status Aktuator (Kipas & Heater)
    // NOTE: Pastikan backend index.js kamu mengembalikan field ini di response
    // json Jika tidak, tambahkan di index.js: actuators: { fan: x, heater: y }
    if (respDoc.containsKey("actuators")) {
      bool fanState = respDoc["actuators"]["fan"];
      bool heaterState = respDoc["actuators"]["heater"];

      digitalWrite(PIN_RELAY_FAN, fanState ? HIGH : LOW);
      digitalWrite(PIN_RELAY_HEATER, heaterState ? HIGH : LOW);

      Serial.printf("[RELAY] Fan: %d | Heater: %d\n", fanState, heaterState);
    }

  } else {
    Serial.printf("HTTP Error: %d\n", httpCode);
  }

  http.end();
}

void connectWiFi() {
  Serial.print("Menghubungkan WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int attempt = 0;
  while (WiFi.status() != WL_CONNECTED && attempt < 20) {
    delay(500);
    Serial.print(".");
    attempt++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi Connected!");
  } else {
    Serial.println("\n❌ WiFi Gagal!");
  }
}