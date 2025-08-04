# Swift UI to Dart/Flutter Conversion

This directory contains the Dart/Flutter equivalents of the Swift UI components from the SimplePush sample app.

## Conversion Overview

The following Swift UI components have been converted to Dart/Flutter:

### Models

- `User` - User model with id and deviceName
- `CallState` - Enum for call states (disconnected, connecting, connected, disconnecting)
- `UserAvailability` - Enum for user availability (available, unavailable)
- `TextMessage` - Message model with sender, receiver, and message content
- `Settings` - Settings model with push manager configuration
- `PushManagerSettings` - Push manager specific settings

### View Models

- `AppManager` - Main app manager that handles initialization and lifecycle
- `UserViewModel` - Manages user-specific state and call actions
- `DirectoryViewModel` - Manages the directory of users and connection state
- `MessagingViewModel` - Manages messaging functionality
- `SettingsViewModel` - Manages app settings

### Views

- `DirectoryView` - Main view showing list of users
- `UserView` - Individual user view with call and message buttons
- `MessagingView` - Message composition and reply interface
- `SettingsView` - App settings configuration
- `MessageBubbleView` - Individual message bubble display

### Utilities

- `Logger` - Logging utility with subsystems
- `Presenter` - Interface for view dismissal

## Key Differences from Swift Version

1. **State Management**: Uses Flutter's `ChangeNotifier` instead of Swift's `@Published` properties
2. **Navigation**: Uses Flutter's `Navigator` instead of SwiftUI's navigation
3. **UI Components**: Uses Flutter's Material Design widgets instead of SwiftUI views
4. **Async Operations**: Uses Dart's `async/await` instead of Swift's Combine publishers
5. **Simplified Implementation**: Some complex networking and background processing is simplified for demonstration

## Usage

The converted app provides the same core functionality as the Swift version:

- Viewing a directory of connected users
- Making calls to users
- Sending messages to users
- Configuring app settings
- Managing connection states

## Architecture

The conversion maintains the MVVM (Model-View-ViewModel) pattern from the Swift version:

- **Models**: Data structures and enums
- **ViewModels**: Business logic and state management
- **Views**: UI components and user interaction
- **Utils**: Helper classes and interfaces

## Notes

This is a demonstration conversion and may need additional implementation details for production use, particularly around:

- Real networking and connectivity
- Background processing
- Push notifications
- Platform-specific features
- Error handling
- Data persistence
