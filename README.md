# PoultryVision (Kandangku) 🐔📱
### Next-Gen IoT Smart Poultry Farming System

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![ESP32](https://img.shields.io/badge/ESP32-E7352C?style=for-the-badge&logo=espressif&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![C++](https://img.shields.io/badge/C++-00599C?style=for-the-badge&logo=c%2B%2B&logoColor=white)

**PoultryVision** is a comprehensive, full-stack Smart Poultry Farming System designed to automate coop maintenance and provide real-time monitoring through a robust IoT architecture. It combines industrial-grade sensors, Cloud automation, and a "Dark Industrial" mobile interface to ensure optimal conditions for livestock 24/7.

---

## 🚀 Key Features

### 📊 Real-time Monitoring
- **Climate Integration**: Precisions temperature & humidity tracking using **SHT31**.
- **Air Quality**: Ammonia levels (ppm) monitoring via **MQ135** to prevent toxic environments.
- **Logistics**: Real-time **Feed Weight** (Load Cell) and **Water Level** status.

### 🧠 Smart Automation (Cloud Brain)
- **Hysteresis Logic**: Advanced control algorithms with buffers (`2.0°C/ppm`) to prevent relay chattering and extend hardware life.
- **Auto-Dispense**: Intelligent servo control triggers feed/water dispensing only when thresholds are breached.
- **Scheduled Maintenance**: Automated daily stats aggregation and telemetry cleanup.

### 🛡️ Secure Architecture
- **IoT Security**: Telemetry endpoints protected by **API Key Validation** (`x-api-key`).
- **User Access**: Full authentication flow for App users via Firebase Auth.
- **Rate Limiting**: Built-in protection against DDoS or spamming from sensors.

### 🏭 Industrial UI
- **Design Language**: "Dark Industrial Green" theme optimized for low-light coop environments.
- **UX**: Pulse animations for active status, offline banners for stale data, and haptic feedback.

---

## 🏗️ System Architecture

The system follows a "Dual-Node" concept where the **Sensor Node** handles physical I/O and the **Vision Node** (planned) handles visual AI.

```mermaid
graph LR
    subgraph "Hardware Layer"
        ESP32[ESP32 Controller]
        Sensors[Sensors: SHT31, MQ135, LoadCell]
        Actuators[Relays & Servos]
    end

    subgraph "Cloud Layer (Firebase)"
        CloudFunc[Cloud Functions\n(Node.js)]
        Firestore[(Firestore DB)]
        Auth[Firebase Auth]
    end

    subgraph "User Layer"
        App[Flutter Mobile App]
    end

    Sensors --> ESP32
    ESP32 --> Actuators
    ESP32 -- "HTTPS Post (API Key)" --> CloudFunc
    CloudFunc --> Firestore
    Firestore <--> App
    App --> Auth
```

---

## 🔌 Hardware Pinout

The **ESP32 DevKit V4** serves as the central brain. Below is the exact wiring configuration.

| Component | Type | ESP32 Pin | Notes |
| :--- | :--- | :--- | :--- |
| **SHT31 SDA** | I2C | `GPIO 21` | Temperature & Humidity |
| **SHT31 SCL** | I2C | `GPIO 22` | |
| **MQ135** | Analog In | `GPIO 34` | Ammonia Sensor |
| **Water Sensor** | Analog In | `GPIO 35` | Liquid Level Probe |
| **Load Cell (DT)** | Digital In | `GPIO 18` | HX711 Data |
| **Load Cell (SCK)** | Output | `GPIO 19` | HX711 Clock |
| **Relay Fan** | Output | `GPIO 25` | Cooling System |
| **Relay Heater** | Output | `GPIO 26` | Heating System |
| **Servo Pakan** | PWM | `GPIO 27` | Feed Dispenser |
| **Servo Air** | PWM | `GPIO 14` | Water Valve |

### Required Firmware Libraries
*   `HX711` (Bogdan Necula)
*   `Adafruit SHT31`
*   `ArduinoJson` (Benoit Blanchon)
*   `ESP32Servo` (Kevin Harrington)

---

## 📱 App Interface

*Placeholders for screenshots*

| **Login Screen** | **Dashboard (Monitoring)** | **Settings (Thresholds)** |
| :---: | :---: | :---: |
| ![Login](https://placehold.co/200x400/1B2E24/4CAF50?text=Login) | ![Dashboard](https://placehold.co/200x400/1B2E24/4CAF50?text=Dashboard) | ![Settings](https://placehold.co/200x400/1B2E24/4CAF50?text=Settings) |

---

## ⚙️ Installation & Setup

### 1. Firmware (ESP32)
1.  Open `esp32/esp32_servo_dispenser.ino` in Arduino IDE.
2.  Create `secrets.h` in the same folder:
    ```cpp
    #define WIFI_SSID "Your_SSID"
    #define WIFI_PASSWORD "Your_Pass"
    #define API_KEY "your-secure-firebase-api-key"
    #define PROJECT_ID "your-project-id"
    ```
3.  Select Board: **DOIT ESP32 DEVKIT V1**.
4.  Upload to board.

### 2. Backend (Firebase)
1.  Install tools: `npm install -g firebase-tools`.
2.  Login: `firebase login`.
3.  Set Environment Variable for Security:
    ```bash
    firebase functions:config:set iot.api_key="your-secure-firebase-api-key"
    ```
4.  Deploy Functions:
    ```bash
    firebase deploy --only functions
    ```

### 3. Mobile App (Flutter)
1.  Navigate to root: `cd kandangku`.
2.  Install dependencies: `flutter pub get`.
3.  Run on device:
    ```bash
    flutter run
    ```

---

## 🛡️ Security Note

This project uses a hybrid security model:
*   **Hardware-to-Cloud**: Does **not** use Client SDKs on ESP32 to save memory. Instead, it uses raw HTTPS POST requests authenticated via `IOT_API_KEY` stored in Cloud Functions environment variables.
*   **App-to-Cloud**: Uses standard Firebase Authentication & Firestore Security Rules.
