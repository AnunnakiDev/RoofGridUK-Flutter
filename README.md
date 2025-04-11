# RoofGridUK

A professional roofing calculator application for UK roofing contractors and specialists.

## Project Overview

RoofGridUK is a Flutter-based mobile and desktop application designed to help roofing professionals calculate precise measurements for roof tiling. The app provides tools for both vertical (batten gauge) and horizontal (rafter gauge) calculations, with support for a variety of tile types and roofing scenarios.

## Features

- **Dual Calculator System**
  - Vertical Calculator (Batten Gauge)
  - Horizontal Calculator (Rafter Gauge)

- **Comprehensive Tile Database**
  - Pre-loaded standard UK roofing tiles
  - Custom tile creation and management
  - Community tile submission system

- **User Account System**
  - Free tier with basic functionality
  - Pro tier with advanced features
  - Admin access for system management

- **Results Management**
  - Save and organize calculation results
  - Visual representations of roof layouts
  - Export options for reports

- **Cross-Platform Support**
  - Mobile (Android/iOS)
  - Desktop (Windows)

## Project Structure

```
lib/
  ├── app/                    # Core application functionality
  │   ├── app.dart            # Main app entry point
  │   ├── auth/               # Authentication system
  │   ├── calculator/         # Calculator business logic
  │   ├── results/            # Results handling
  │   ├── theme/              # App theming
  │   └── tiles/              # Tile models and services
  ├── models/                 # Data models
  ├── providers/              # State management
  ├── routing/                # App navigation
  ├── screens/                # UI screens
  │   ├── admin/              # Admin screens
  │   ├── auth/               # Login/registration
  │   ├── calculator/         # Calculator UI
  │   ├── home/               # Home screen
  │   ├── results/            # Results viewing
  │   ├── splash/             # Launch screen
  │   ├── support/            # Support pages
  │   └── tiles/              # Tile management UI
  ├── services/               # Business logic services
  ├── utils/                  # Utility functions
  └── widgets/                # Reusable UI components
```

## Technology Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Backend**: Firebase (Firestore, Authentication)
- **Local Storage**: SharedPreferences

## User Tiers

### Free User Features
- Basic vertical and horizontal calculations
- NO Access to standard tile database
- Manual Input only

### Pro User Features
- Advanced calculation options
- Multiple rafter and width calculations
- Export results in multiple formats
- Unlimited saved results
- Complete tile database access
- Create unlimited custom tiles
- Submit tiles to admin

### Admin Features
- Approve user tile submissions
- Manage public tile database
- View analytics and user data

## To-Do List

### Critical
- [x] Create tile model structure
- [x] Implement tile management screen
- [x] Set up tile submission system
- [ ] Complete Firebase backend integration
- [ ] Finalize calculation algorithms

### High Priority
- [ ] Implement result export functionality
- [ ] Add comprehensive error handling
- [ ] Set up user account management
- [ ] Create analytics dashboard for admins

### Medium Priority
- [ ] Optimize app performance
- [ ] Create tutorial guides for new users
- [ ] Implement dark mode
- [ ] Add multi-language support

### Low Priority
- [ ] Design marketing graphics
- [ ] Set up CI/CD pipeline
- [ ] Create automated testing
- [ ] Implement feedback collection system

## Development Roadmap

### Phase 1: Core Functionality (Current)
- Basic calculator implementation
- User authentication
- Tile database structure

### Phase 2: Enhanced Features
- Advanced calculation options
- Result visualization improvements
- Export capabilities

### Phase 3: Platform Expansion
- iOS release
- Desktop optimization
- Web version consideration

### Phase 4: Community Features
- User forums
- Knowledge base
- Shared projects

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase using the provided `firebase_options.dart`
4. Run the app using `flutter run`

## Contribution Guidelines

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

Proprietary - All rights reserved
