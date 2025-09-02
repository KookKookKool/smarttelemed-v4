# Shared Directory

This directory contains shared code, utilities, and resources used across all applications in the Smart Telemed V4 project.

## Structure

- **api/** - API communication and data fetching logic
- **models/** - Data models and entities  
- **services/** - Shared business logic and services
  - `auth/` - Authentication services
  - `splash/` - Splash screen services
  - `appoint/` - Appointment management services
  - `device/` - Device management and connectivity
  - `video/` - Video calling services
  - `notes/` - Note-taking services
  - `settings/` - Application settings
  - `vitalsign/` - Vital signs management
- **storage/** - Data storage and persistence logic
- **themes/** - Styling, themes, and UI constants
- **utils/** - Utility functions and helpers
- **widgets/** - Reusable UI components

## Usage

All modules in this directory can be imported and used by any of the applications in the `apps/` directory. This promotes code reuse and maintainability.