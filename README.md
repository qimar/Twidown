<div align="center">

# TwiDown

### One Tap Media Downloader for X and Twitter

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![Material 3](https://img.shields.io/badge/Material_3-757575?style=for-the-badge&logo=materialdesign&logoColor=white)](https://m3.material.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

<br/>

<a href="https://play.google.com/store/apps/details?id=com.xvideo.twitterdownloader">
  <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" height="70" alt="Get it on Google Play"/>
</a>

</div>

---

## Overview

TwiDown is a native Android utility that delivers fast, one tap downloading of high definition videos and animated GIFs from X (Twitter) directly into the user device gallery. It features real time clipboard listeners that auto detect copied links on launch, multi bitrate resolution selection, and background download persistence.

---

## Key Features

* **Instant Clipboard Detection:** Automatically detects and pastes copied tweet URLs when opening the app, eliminating repetitive typing.
* **Multi Quality Selection:** Choose between multiple available video bitrates (1080p, 720p, 360p) before starting the download.
* **Direct Gallery Synchronization:** Media files are saved directly into the public Android Movies and Gallery collections using MediaStore.
* **Nested Thread Parsing:** Resolves complex JSON payloads across quote tweets and multi media threads without requiring official paid API tokens.
* **Material 3 Interface:** Dynamic color theming, clean dark mode layout, and responsive screen sizing.

---

## Tech Stack

| Component | Technology |
|---|---|
| **Framework** | Flutter 3.x (Android) |
| **Language** | Dart |
| **UI Design** | Material 3, Sizer |
| **State Management** | Provider |
| **Networking** | Dio, HTTP, Custom Scrapers |
| **Storage API** | MediaStore Plus (Android Scoped Storage) |
| **Media Player** | Video Player with Gesture Controls |

---

## Architecture

```text
lib/
├── core/                  # Color tokens, constants, and helper utilities
├── providers/             # State providers for downloads, theme, and media list
├── screens/               # Modular screens (Home, Downloads, Video Player)
├── services/              # Twitter media extraction services and platform channels
└── main.dart              # Service locator setup and application routes
```

---

## Engineering Highlights

### Scraped Payload Resolution Without Paid APIs
Due to changes in platform API pricing, TwiDown implements a resilient scraping pipeline that parses public guest endpoints, extracts direct `.mp4` and `.gif` video streams, and handles nested quote tweet hierarchies.

### Zero Stutter Memory Cleanups
Web extraction engines can cause memory spikes on budget devices. TwiDown enforces explicit controller teardowns and cleans temporary scrape buffers immediately after resolving video URLs, preventing out of memory crashes.

---

## Getting Started

### Prerequisites
* Flutter SDK (3.24+)
* Android Studio with Android SDK API 34+
* Java 17

### Installation

```bash
# Clone the repository
git clone https://github.com/qimar/twidown.git

# Navigate to the folder
cd twidown

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

---

## License

Distributed under the MIT License. See `LICENSE` for details.
