# SmartTeleMed V4 - Libs Architecture

This document describes the new `libs` folder structure designed to support multiple applications and shared components in the SmartTeleMed V4 project.

## Overview

The `libs` directory is organized into three main sections:

- **shared/** - Common components, widgets, utilities, and styles
- **apps/** - Individual Flutter applications
- **packages/** - Reusable packages for specific functionality

## Directory Structure

```
libs/
├── shared/
│   ├── core/           # Core business logic and services
│   ├── widgets/        # Reusable UI components
│   ├── utils/          # Common utilities and helpers
│   └── style/          # Shared themes, colors, and styling
├── apps/
│   ├── main_app/       # Main SmartTeleMed application
│   ├── doctor_app/     # Future: Doctor-specific application
│   └── patient_app/    # Future: Patient-specific application
└── packages/
    ├── common_models/   # Shared data models
    ├── api_client/      # API communication layer
    └── device_drivers/  # Medical device drivers
```

## Shared Components

### shared/core
Contains core business logic, authentication, device management, vital signs, and API services.

**Key modules:**
- `auth/` - Authentication and ID card reading
- `device/` - Device connection and management
- `vitalsign/` - Vital signs processing
- `api/` - Backend API communication
- `storage/` - Data storage and persistence

### shared/widgets
Reusable UI components that can be used across multiple applications.

**Key modules:**
- `common/` - General-purpose widgets
- `forms/` - Form components
- `pdpa/` - PDPA consent widgets
- `navigation/` - Navigation components

### shared/utils
Common utilities and helper functions.

**Key modules:**
- `responsive/` - Responsive design utilities
- `helpers/` - General helper functions
- `formatters/` - Data formatting utilities

### shared/style
Shared styling, themes, and design system components.

**Key modules:**
- `themes/` - Application themes
- `colors/` - Color palettes
- `backgrounds/` - Background styles

## Applications

### apps/main_app
The main SmartTeleMed application containing patient-specific functionality.

### Future Applications
- **doctor_app** - Doctor-specific interface and functionality
- **patient_app** - Patient-focused mobile application

## Packages

### common_models
Shared data models used across all applications.

**Examples:**
- `Patient` - Patient information model
- `Device` - Medical device model
- `VitalSign` - Vital sign measurements
- `Appointment` - Appointment scheduling

### api_client
Centralized API communication layer.

**Features:**
- Backend API client
- Patient data API
- Device management API
- Configuration management

### device_drivers
Medical device drivers and communication protocols.

**Supported devices:**
- A&D Medical devices
- Beurer devices
- Jumper devices
- Mi (Xiaomi) devices
- Yuwell devices

## Usage

### Importing Shared Components

```dart
// Import shared core functionality
import 'package:shared_core/shared_core.dart';

// Import shared widgets
import 'package:shared_widgets/shared_widgets.dart';

// Import shared utilities
import 'package:shared_utils/shared_utils.dart';

// Import shared styling
import 'package:shared_style/shared_style.dart';
```

### Using Packages

```dart
// Import common models
import 'package:common_models/common_models.dart';

// Import API client
import 'package:api_client/api_client.dart';

// Import device drivers
import 'package:device_drivers/device_drivers.dart';
```

## Development Guidelines

### Adding New Shared Components

1. Place shared business logic in `shared/core/`
2. Place reusable UI components in `shared/widgets/`
3. Place utilities in `shared/utils/`
4. Place styling in `shared/style/`

### Creating New Applications

1. Create a new directory under `libs/apps/`
2. Add dependencies to shared packages in `pubspec.yaml`
3. Import shared components as needed

### Creating New Packages

1. Create a new directory under `libs/packages/`
2. Add `pubspec.yaml` with appropriate dependencies
3. Export main functionality through a barrel file
4. Document the package purpose and API

## Benefits

- **Code Reusability** - Shared components can be used across multiple applications
- **Modularity** - Clear separation of concerns and responsibilities
- **Scalability** - Easy to add new applications and functionality
- **Maintainability** - Centralized shared code reduces duplication
- **Team Collaboration** - Clear structure for multiple teams working on different apps

## Migration from Original Structure

The original `lib/` folder content has been reorganized as follows:

- `lib/core/` → `libs/shared/core/`
- `lib/widget/` → `libs/shared/widgets/`
- `lib/utils/` → `libs/shared/utils/`
- `lib/style/` → `libs/shared/style/`
- `lib/api/` → `libs/shared/core/api/`
- `lib/storage/` → `libs/shared/core/storage/`
- `lib/pt/` → `libs/apps/main_app/lib/pt/`
- `lib/main.dart` → `libs/apps/main_app/lib/main.dart`