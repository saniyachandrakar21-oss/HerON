# HerON — Discreet Personal Safety App

HerON is a personal safety application designed to help users access safety features discreetly. It uses a calculator-style interface to conceal the safety app and provides journey check-ins, trusted contact management, and emergency alerts through Telegram.

The project is built using Flutter for the user interface and Python FastAPI for the backend.

## Features

### 1. Calculator Disguise
- Opens with a calculator-style interface.
- Enter the configured PIN (`2580`) and press `=` to access HerON.
- Provides a discreet way to access the safety interface.

### 2. Journey Tracking and Safety Check-ins
- Start a journey and configure the check-in interval.
- Display an **"Are You OK?"** dialog when a check-in is due.
- Confirm safety using the **"I'm OK"** option.
- Select **"I feel unsafe"** to initiate the SOS flow.
- Display journey status and activity updates.

**Note:** Automatic check-ins depend on the application process remaining active. Background execution and missed-check-in escalation require further testing and implementation.

### 3. SOS Emergency Alerts
- Initiate an SOS alert when the user reports feeling unsafe.
- Send an emergency request from the Flutter app to the FastAPI backend.
- Use the Telegram Bot API to deliver messages to configured trusted contacts.
- Display a status indicating whether the request succeeded or failed.

Telegram delivery requires a valid bot configuration and recipient Chat IDs. Each recipient must start the Telegram bot before receiving messages.

### 4. Trusted Contacts and Profile
- Add and edit trusted contacts.
- Store contact names, phone numbers, and Telegram Chat IDs.
- Save profile information and trusted contacts locally using SharedPreferences.

### 5. Evidence Section
- Select an image from the device.
- Add a note describing the evidence.
- Demonstrate basic classification based on the note's text.

**Current limitation:** Evidence classification is a demonstration feature, not a production AI image-recognition or forensic analysis system.

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Application interface and navigation |
| Dart | Application logic |
| Python | Backend implementation |
| FastAPI | HTTP API for emergency alerts |
| Uvicorn | Backend server |
| Telegram Bot API | Emergency message delivery |
| SharedPreferences | Local profile and trusted-contact storage |

## Project Structure

```text
HerON/
├── lib/
│   ├── main.dart
│   ├── heron_api_service.dart
│   └── notification_service.dart
├── backend/
│   ├── main.py
│   └── .env
├── pubspec.yaml
└── README.md
```

The structure above illustrates the main application and backend files. Your actual repository may contain additional files and folders.

## Prerequisites

Install the following before running the project:

- Flutter SDK
- Dart SDK (included with Flutter)
- Python 3
- pip
- Google Chrome, if running the web interface in Chrome
- A Telegram bot and valid recipient Chat IDs, if testing SOS delivery

## Installation and Setup

### 1. Clone the Repository

```bash
git clone <YOUR_REPOSITORY_URL>
cd <YOUR_PROJECT_DIRECTORY>
```

Replace the placeholders with your repository URL and directory name.

### 2. Install Flutter Dependencies

From the Flutter project root, run:

```bash
flutter pub get
```

### 3. Configure the Backend

Open a terminal and navigate to the backend directory:

```bash
cd backend
```

Install the required Python packages:

```bash
pip install fastapi uvicorn requests python-dotenv
```

Ensure these packages match the imports used by your actual backend implementation.

Create a `.env` file in the backend directory and configure the required secrets:

```env
BOT_TOKEN=your_telegram_bot_token
HERON_API_KEY=your_api_key
```

Replace the placeholder values with your own credentials.

**Security:** Never commit your actual bot token or API key to GitHub. Add `.env` to `.gitignore`.

### 4. Start the Backend

From the backend directory, run:

```bash
python -m uvicorn main:app --reload --port 8000
```

The local backend should be available at:

- **API base:** `http://127.0.0.1:8000`
- **API documentation:** `http://127.0.0.1:8000/docs`

The root endpoint (`GET /`) can be used to check whether the backend is running.

### 5. Run the Web Interface

Open a second terminal at the Flutter project root:

```bash
flutter run -d chrome
```

Flutter will launch the application in Chrome and display the local web address.

Keep the backend terminal running when testing features that require the backend.

### 6. Configure Web API Connectivity

When running the application in Chrome, configure the API service to use the reachable backend address, for example:

```dart
http://127.0.0.1:8000
```

The Android emulator address `http://10.0.2.2:8000` is intended for emulator-to-host communication and should not be used as the browser's local backend address.

If browser requests fail, check the API base URL, backend CORS configuration, API key, and browser console. For remote access, use a properly configured HTTPS backend.

## Backend API

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/` | Check backend status |
| `POST` | `/alert` | Submit an emergency alert |
| `POST` | `/telegram-webhook` | Receive Telegram webhook updates, if configured |

The `/alert` endpoint requires valid API authentication and recipient Chat IDs. The precise request fields and response format should match the backend implementation.

## Configuring Trusted Contacts

1. Open HerON.
2. Navigate to Profile & Settings.
3. Add a trusted contact.
4. Enter the contact's name and phone number.
5. Enter the recipient's Telegram Chat ID.
6. Save the contact information.

The Telegram Chat ID is required for the SOS flow to identify the recipient.

## Testing Checklist

- [ ] Launch the Flutter web interface.
- [ ] Verify calculator PIN entry.
- [ ] Navigate to the Travel and Evidence sections.
- [ ] Start a journey and verify the check-in dialog.
- [ ] Confirm that the safety confirmation updates the journey status.
- [ ] Save and retrieve trusted contact information.
- [ ] Verify that the backend starts successfully.
- [ ] Test the `/alert` endpoint with valid authentication.
- [ ] Verify actual Telegram delivery to a configured recipient.
- [ ] Verify failure handling for invalid credentials or unavailable services.
- [ ] Test notification behavior in the intended deployment environment.

## Security and Limitations

- HerON is a prototype and should not be treated as a guaranteed emergency service.
- Keep API keys and Telegram bot tokens on the backend.
- Use HTTPS for deployed backend communication.
- Protect trusted contact information and obtain consent before sharing sensitive information.
- Browser and operating-system restrictions may affect notifications and background execution.
- Telegram delivery depends on backend availability, valid credentials, and recipient configuration.
- The evidence classification feature is currently a demonstration rather than a production AI system.

## Future Improvements

- Integrate genuine AI-based image analysis through a secure backend.
- Improve background check-in reliability and missed-check-in escalation.
- Add clearer delivery logs and per-recipient alert status.
- Deploy the backend to a stable HTTPS service.
- Improve location-sharing permissions and emergency location handling.
- Test the application across Android devices and supported browsers.

## Disclaimer

HerON is a personal safety prototype developed to demonstrate discreet access, journey check-ins, trusted contact management, and emergency alert integration. Its functionality must be thoroughly tested before any real-world safety reliance.

---

**Project:** HerON  
**Frontend:** Flutter  
**Backend:** Python + FastAPI  
**Messaging:** Telegram Bot API