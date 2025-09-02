# Smart Telemed V4 - Refactored Structure

This document describes the new refactored structure to support multifunction applications for VHV (Volunteer Health Village), Personal/Patient, and Hospital functionalities.

## Directory Structure

```
lib/
├── shared/                 # Shared components across all app types
│   ├── api/               # Backend API services
│   ├── style/             # App styles, colors, backgrounds
│   ├── utils/             # Utility functions and helpers
│   ├── widgets/           # Reusable UI widgets
│   └── screens/           # Common screens (auth, device, settings, etc.)
│
├── apps/                  # App-specific features
│   ├── vhv/              # Volunteer Health Village features
│   │   ├── dashboard_screen.dart
│   │   ├── device_screen.dart
│   │   ├── login_qrcam.dart
│   │   ├── login_token.dart
│   │   ├── profile_screen.dart
│   │   └── idcard/       # VHV ID card functionality
│   │
│   ├── personal/         # Personal/Patient features
│   │   ├── mainpt_screen.dart
│   │   ├── profilept_screen.dart
│   │   ├── idcard/       # Patient ID card functionality
│   │   └── widgets/      # Patient-specific widgets
│   │
│   └── hospital/         # Hospital features
│       ├── appoint/      # Appointment management
│       └── doctor/       # Doctor-related features
│
├── routes/               # Application routing
│   └── app_routes.dart   # Centralized route definitions
│
├── storage/              # Data storage management
└── main.dart             # Application entry point
```

## Key Changes

1. **Modular Structure**: Separated functionality by app type (VHV, Personal, Hospital)
2. **Shared Components**: Common elements moved to `shared/` directory
3. **Route Extraction**: Routes moved from `main.dart` to dedicated `routes/app_routes.dart`
4. **Updated Imports**: All import paths updated to reflect new structure

## App Types

### VHV (Volunteer Health Village)
- Routes: `/general`, `/loginToken`, `/loginQRCam`, `/dashboard`, etc.
- Features: Dashboard, device management, ID card authentication

### Personal/Patient
- Routes: `/addcardpt`, `/profilept`, `/mainpt`, etc.
- Features: Patient profile, medical records, appointment booking

### Hospital
- Routes: `/hospital`, `/doctor`, `/appoint`, etc.
- Features: Doctor management, appointment scheduling, patient management

## Usage

The refactored structure maintains backward compatibility while providing better organization for future development. Each app type can be developed independently while sharing common components and utilities.