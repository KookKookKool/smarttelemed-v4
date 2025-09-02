# Smart Telemed V4 - Multi-Application Architecture

This directory contains the reorganized Flutter application structure designed to support multiple applications within a single codebase.

## Directory Structure

```
lib/
├── apps/                    # Application-specific modules
│   ├── vhv_app/            # Village Health Volunteer application
│   ├── patient_app/        # Patient application
│   └── doctor_app/         # Doctor application
├── shared/                 # Shared components and services
│   ├── api/               # API communication layer
│   ├── models/            # Data models and entities
│   ├── services/          # Business logic and services
│   ├── storage/           # Data persistence
│   ├── themes/            # UI themes and styling
│   ├── utils/             # Utility functions
│   └── widgets/           # Reusable UI components
├── main.dart              # Main application entry point
├── index.dart             # Library export index
└── routes.dart            # Centralized routing
```

## Applications

### VHV App (`apps/vhv_app/`)
Village Health Volunteer application containing:
- Dashboard and profile management
- Device connectivity and management
- ID card authentication
- Token-based and QR code login

### Patient App (`apps/patient_app/`)
Patient-focused application containing:
- Patient profile management
- Main patient interface
- ID card integration
- Medical record access

### Doctor App (`apps/doctor_app/`)
Doctor interface application containing:
- Doctor workflow screens
- Appointment management
- Patient consultation tools
- Medical result reporting

## Shared Components

### Services (`shared/services/`)
- **Authentication**: User login and session management
- **Appointments**: Scheduling and management
- **Device Management**: Medical device connectivity
- **Video Calling**: Telemedicine video sessions
- **Vital Signs**: Health data collection
- **Notes**: Medical record management
- **Settings**: Application configuration

### Widgets (`shared/widgets/`)
- Navigation components (manubar)
- Time displays and formatting
- PDPA compliance components
- Reusable UI elements

### Utilities (`shared/utils/`)
- Responsive design helpers
- Common utility functions

### Storage (`shared/storage/`)
- Data persistence layer
- API data management

### Themes (`shared/themes/`)
- Application styling
- Color schemes
- Background components

## Usage

### Importing Components

```dart
// Using the main index for easy imports
import 'package:smarttelemed_v4/index.dart';

// Or import specific modules
import 'package:smarttelemed_v4/apps/vhv_app/index.dart';
import 'package:smarttelemed_v4/shared/widgets/index.dart';
import 'package:smarttelemed_v4/shared/services/index.dart';
```

### Navigation

All routes are centrally managed in `shared/routes.dart` and can be accessed via:

```dart
import 'package:smarttelemed_v4/shared/routes.dart';

// In your MaterialApp
routes: AppRoutes.getAllRoutes(),
```

## Benefits

1. **Separation of Concerns**: Each application has its own dedicated space
2. **Code Reusability**: Shared components eliminate duplication
3. **Maintainability**: Clear organization makes updates easier
4. **Scalability**: Easy to add new applications or features
5. **Team Collaboration**: Different teams can work on different apps independently

## Migration Notes

This structure was migrated from the previous monolithic structure where all components were mixed in the `core/` directory. All import paths have been updated to reflect the new organization.

## Development Guidelines

1. **App-specific code** should go in the appropriate `apps/` directory
2. **Reusable components** should be placed in `shared/`
3. **New applications** should follow the same pattern as existing apps
4. **Import statements** should use the new path structure
5. **Documentation** should be updated when adding new components