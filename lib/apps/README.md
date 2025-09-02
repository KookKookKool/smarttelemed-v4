# Apps Directory

This directory contains separate applications within the Smart Telemed V4 project.

## Structure

- **vhv_app/** - Village Health Volunteer application
  - Contains screens and functionality specific to VHV users
  - Includes dashboard, profile, device management, and ID card features
  - Main entry point: `main_vhv.dart`

- **patient_app/** - Patient application  
  - Contains screens and functionality specific to patients
  - Includes patient profile, main screens, and ID card features
  - Main entry point: `main_patient.dart`

- **doctor_app/** - Doctor application
  - Contains screens and functionality specific to doctors
  - Includes doctor screens, pending appointments, and results
  - Main entry point: `main_doctor.dart`

## Usage

Each app has its own routes and can be used independently or as part of the main application. The apps share common services and widgets from the `shared/` directory.