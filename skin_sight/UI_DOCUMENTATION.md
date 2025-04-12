# SkinSight UI Documentation

This document provides an overview of the UI components in the SkinSight application, a dermatological AI assistant for psoriasis tracking and management.

## Table of Contents

1. [Theme and Styling](#theme-and-styling)
2. [App Structure](#app-structure)
3. [Screens](#screens)
    - [Authentication Screens](#authentication-screens)
    - [Welcome Screen](#welcome-screen)
    - [Role-Specific Screens](#role-specific-screens)
    - [Shared Screens](#shared-screens)
4. [Reusable Widgets](#reusable-widgets)
5. [Navigation Flow](#navigation-flow)
6. [UI Improvements](#ui-improvements)
7. [UI Consolidation Plan](#ui-consolidation-plan)

## Theme and Styling

The application uses a consistent color scheme defined in `main.dart`:

- **Primary Color**: `Color(0xFF0A8754)` (Green)
- **Secondary Color**: `Color(0xFF2D8CFF)` (Blue)
- **Error Color**: `Color(0xFFDC3545)` (Red)
- **Surface Color**: `Color(0xFFF8F9FA)` (Light Gray)

The theme includes custom styling for:
- AppBar with centered titles and no elevation
- Cards with rounded corners (12px radius)
- Elevated buttons with padding and rounded corners
- Input fields with custom borders and focus states

## App Structure

The application follows a structured organization:

- `lib/screens/` - Contains all the application screens
  - `auth/` - Authentication screens (login/register)
  - `patient/` - Patient-specific screens
  - `doctor/` - Doctor-specific screens
  - `common/` - Screens shared between different user types (to be expanded)
- `lib/widgets/` - Reusable UI components
- `lib/models/` - Data models
- `lib/services/` - Business logic and services
- `lib/utils/` - Utility functions and helpers

## Screens

### Authentication Screens

#### Login Screen (`screens/auth/login_screen.dart`)
- User login interface with:
  - Email and password fields
  - Login button
  - Register account link
  - Toggle for patient/doctor mode

#### Register Screen (`screens/auth/register_screen.dart`)
- User registration interface with:
  - Name, email, and password fields
  - Additional fields based on user type (patient/doctor)
  - Register button
  - Login link for existing users

### Welcome Screen

#### Welcome Screen (`screens/welcome_screen.dart`)
- Entry point for new users
- Features:
  - App logo and branding
  - User type selection (Patient/Doctor)
  - Information about the application
  - Navigation to appropriate login screens

### Role-Specific Screens

#### Dashboard Screen
- **Current Implementation**: 
  - Separate dashboards for patients (`patient_dashboard.dart`) and doctors (`doctor_dashboard.dart`)
- **Features**:
  - Header with user information
  - Role-specific content (patient reports vs. patient list)
  - Empty state handling
  - Action buttons appropriate for role
  - Logout functionality

#### Add Patient Screen (`screens/doctor/add_patient_screen.dart`)
- Doctor-only screen
- Features:
  - Form fields for patient information
  - Submit button

### Shared Screens

#### Report Management Screen
- **Proposed Unified Screen**: Combine functionality from:
  - `add_patient_report_screen.dart` 
  - `add_report_screen.dart`
  - `review_patient_report_screen.dart`
- **Features**:
  - Role-adaptive UI based on user type
  - Image upload with camera and gallery options
  - Form fields for symptoms/diagnosis and notes
  - Severity selection
  - Body region selection
  - Submit button
  - Additional doctor-specific fields when applicable

#### Report Details Screen
- **Proposed Unified Screen**: Replace:
  - Dialog-based report details in `patient_details_screen.dart`
  - Report view functionality in patient dashboard
- **Features**:
  - Full-screen report viewing experience
  - Image viewer with zoom capability
  - Report metadata display
  - Role-specific actions (review for doctors, view-only for patients)
  - AI analysis access
  - Timeline of changes (if applicable)

#### Patient Details Screen
- **Current Implementation**: `screens/doctor/patient_details_screen.dart`
- Features:
  - Patient information
  - List of patient reports
  - Add report button
  - Navigation to report details

#### AI Analysis Screen (`screens/common/ai_analysis_screen.dart`)
- AI-based analysis of psoriasis images
- Features:
  - Image viewer
  - PASI score calculation
  - Severity assessment
  - Treatment recommendations
  - History tracking

## Reusable Widgets

#### Report Card (`widgets/report_card.dart`)
- Card component to display report information
- Features:
  - Date and severity indicator
  - Optional patient/doctor information
  - Diagnosis and notes display
  - Image preview
  - AI analysis button

#### AI Analysis Button (`widgets/ai_analysis_button.dart`)
- Button component to trigger AI analysis
- Features:
  - Visual indicator of analysis status
  - Navigation to analysis screen
  - Support for existing analysis data

## Navigation Flow

The application uses a combination of named routes and direct navigation:

- **Initial Route**: `/` → `AuthWrapper` (checks authentication status)
- **Unauthenticated Flow**:
  - Welcome Screen → Login/Register Screen (based on user type)
- **Authenticated Flow**:
  - Patient: Dashboard → Report Management/Details → AI Analysis
  - Doctor: Dashboard → Patient List → Patient Details → Report Management/Details → AI Analysis

## UI Improvements

### Planned UI Enhancements

#### 1. Enhanced Image Upload for All Users
- **Add camera option in the Report Management Screen**
  - Current implementation only supports gallery selection
  - Add a direct camera capture button next to the gallery button
  - Implement image cropping functionality after capture
  - Add live preview of camera feed for better framing
  - Current implementation in `add_report_screen.dart`:
  ```dart
  Future<void> _pickImage() async {
    try {
      final XFile? image = await StorageService.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _imageUrl = null; // Clear previous URL since we have a new image
        });
      }
    } catch (e) {
      // Error handling
    }
  }
  ```
  - Needs to be updated to handle both gallery and camera sources

#### 2. Full-Screen Report Details
- **Redesign report viewing to use full screen instead of dialog**
  - Current implementation uses a dialog popup for report details
  - Create a new dedicated screen for viewing report details
  - Implement navigation to this screen when a report is selected
  - Add pinch-to-zoom image viewing capability
  - Include swipe gestures to navigate between images if multiple
  - Add history of changes timeline
  - Current implementation in `patient_details_screen.dart`:
  ```dart
  void _showReportDetails(ReportModel report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        // Dialog implementation
      ),
    );
  }
  ```
  - Should be replaced with navigation to a dedicated screen:
  ```dart
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ReportDetailsScreen(
        report: report,
        patient: widget.patient,
      ),
    ),
  );
  ```

## UI Consolidation Plan

### Current UI Structure Issues
- **Duplicate Functionality**: Similar screens for patients and doctors performing the same core operations
- **Excessive Navigation**: Too many separate screens leads to complex navigation
- **Maintenance Challenges**: Changes to shared functionality require updates in multiple files
- **Inconsistent User Experience**: Different UI patterns for similar actions across user roles

### Proposed Consolidation

#### 1. Unified Report Management Screen
- **Consolidate**:
  - `screens/patient/add_patient_report_screen.dart`
  - `screens/doctor/add_report_screen.dart`
  - `screens/doctor/review_patient_report_screen.dart`
- **Implementation**:
  ```dart
  class ReportManagementScreen extends StatefulWidget {
    final UserModel user;
    final UserModel? patient; // Null for patients, populated for doctors
    final ReportModel? reportToEdit;
    final bool isViewOnly;
    
    const ReportManagementScreen({
      Key? key,
      required this.user,
      this.patient,
      this.reportToEdit,
      this.isViewOnly = false,
    }) : super(key: key);
    
    @override
    State<ReportManagementScreen> createState() => _ReportManagementScreenState();
  }
  ```
- **Benefits**:
  - Single screen for creating, editing, and reviewing reports
  - Conditional rendering based on user role and context
  - Simpler navigation and state management
  - Consistent UI patterns across roles

#### 2. Unified Report Details Screen
- **Consolidate**:
  - Report detail dialogs from `patient_details_screen.dart`
  - Report viewing functionality from patient dashboard
- **Implementation**:
  ```dart
  class ReportDetailsScreen extends StatelessWidget {
    final ReportModel report;
    final UserModel viewer; // The current user viewing the report
    final UserModel patient; // The patient the report belongs to
    
    const ReportDetailsScreen({
      Key? key,
      required this.report,
      required this.viewer,
      required this.patient,
    }) : super(key: key);
  }
  ```
- **Benefits**:
  - Full-screen dedicated view for report details
  - Role-appropriate actions based on viewer type
  - Consistent experience across the application
  - Better image viewing capabilities

#### 3. Role-Adaptive Dashboard
- **Maintain separate dashboards but standardize patterns**:
  - Extract common UI patterns to shared components
  - Ensure consistent layout and interaction patterns
  - Simplify navigation to shared screens

### Implementation Timeline
1. Create the unified Report Details Screen
2. Develop the unified Report Management Screen
3. Update navigation throughout the app to use these consolidated screens
4. Refactor dashboards to use shared components and patterns
5. Add role-specific customizations through conditional rendering

---

This documentation is intended to provide an overview of the UI components in the SkinSight application. Refer to the individual files for more detailed implementation. 