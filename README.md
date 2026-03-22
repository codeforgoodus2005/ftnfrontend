# FTN Frontend - For The Need Foundation

A Flutter-based volunteer management and event coordination mobile and web application for the For The Need Foundation.

## 📋 Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Technologies & Dependencies](#technologies--dependencies)
- [Supported Platforms](#supported-platforms)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Key Features Details](#key-features-details)

## 🎯 Overview

FTN Frontend is a cross-platform application that enables volunteers and administrators to manage events, track volunteer participation, and coordinate activities for the For The Need Foundation. The app provides separate interfaces for volunteers and administrators with distinct workflows for each user type.

## ✨ Features

### For Volunteers
- **User Authentication** - Secure login system with session management
- **Event Discovery & Signup** - Browse available volunteer events and sign up
- **Event Participation Tracking** - View personal event history and participation status
- **Check-in System** - Digital check-in functionality for events
- **Location Services** - GPS-based location tracking and geolocation features
- **Documentation** - Access to volunteer documentation and resources

### For Administrators
- **Dashboard** - Centralized admin control panel
- **Event Management** - Create and manage volunteer events
- **Volunteer Management** - Track volunteer information and activity
- **Reporting & Analytics** - Generate reports on event participation and volunteer data
- **Check-in Monitoring** - Track volunteer check-ins for events
- **Documentation Management** - Manage volunteer documentation

### General Features
- **Session Management** - Persistent session handling with secure token storage
- **Responsive UI** - Works seamlessly on mobile, tablet, and web platforms
- **Event Calendar** - Calendar-based event viewing with detailed information
- **File Management** - File picker for document uploads

## 📁 Project Structure
## 🛠 Technologies & Dependencies

### Core Framework
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language (3.4.4+)

### Key Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| `http` | ^1.2.2 | HTTP client for API communication |
| `shared_preferences` | ^2.0.10 | Local session and preference storage |
| `geolocator` | ^14.0.2 | Location services and GPS tracking |
| `table_calendar` | ^3.0.2 | Calendar widget for event scheduling |
| `file_picker` | ^10.3.10 | File selection and upload |
| `intl` | ^0.20.2 | Internationalization and date formatting |
| `flutter_dotenv` | ^6.0.0 | Environment variable management |
| `url_launcher` | ^6.1.14 | External URL opening |
| `path_provider` | ^2.1.5 | File system path access |
| `open_file` | ^3.5.10 | File opening functionality |
| `googleapis` & `googleapis_auth` | any | Google APIs integration |
| `cupertino_icons` | ^1.0.6 | iOS-style icons |
| `wifi_ip_details` | ^1.0.0 | Network information |
| `flutter_session_manager` | ^1.0.3 | Session management utilities |
| `http_parser` | ^4.0.0 | HTTP parsing utilities |

### Dev Dependencies
- `flutter_test` - Testing framework
- `flutter_lints` - Code quality and lint rules

## 🖥 Supported Platforms

- ✅ **Android** - Mobile app support
- ✅ **iOS** - Mobile app support
- ✅ **Web** - Browser-based access
- ✅ **Windows** - Desktop application
- ✅ **Linux** - Desktop application
- ✅ **macOS** - Desktop application

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.4.4 or higher)
- Dart SDK (included with Flutter)
- Android Studio or Xcode (for mobile development)
- Backend API server running (see Configuration)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ftnfrontend
   flutter pub get
   
2. **Configure Environment Variables**
3.    # For development
   flutter upgrade //upgrade flutter sdk and dart 
   flutter run

   # For specific platform
   flutter run -d <device-id>    # Mobile
   flutter run -d chrome         # Web
   flutter run -d windows        # Windows
   flutter run -d linux          # Linux
4.   # Android
   flutter build apk

   # iOS
   flutter build ios

   # Web
   flutter build web

   # Windows/Linux
   flutter build windows
   flutter build linux