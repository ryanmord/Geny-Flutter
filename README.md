# Geny Flutter

Cross-platform desktop client for Geny, built with Flutter for macOS and Windows.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.11+)
- [Node.js](https://nodejs.org/) (18+) — required to run the backend
- Xcode (macOS development)
- Visual Studio 2022 with C++ workload (Windows development)

## Setup

```bash
# Install dependencies
flutter pub get

# Generate JSON serialization code
dart run build_runner build --delete-conflicting-outputs

# Run on macOS
flutter run -d macos

# Run on Windows
flutter run -d windows
```

## Project Structure

```
lib/
├── main.dart               # Entry point, window configuration
├── app.dart                # Root widget, service initialization
├── models/                 # Data models with JSON serialization
│   ├── agent.dart
│   ├── conversation.dart
│   ├── integration.dart
│   ├── message.dart
│   └── stream_event.dart
├── view_models/            # MVVM view models
├── services/               # Backend communication layer
│   ├── backend_service.dart          # REST API client
│   ├── backend_process_manager.dart  # Node.js process lifecycle
│   ├── platform_utils.dart           # OS-specific path resolution
│   └── websocket_service.dart        # WebSocket streaming client
├── views/                  # UI screens
│   ├── chat/
│   ├── sidebar/
│   ├── agents/
│   ├── settings/
│   └── widgets/            # Shared/reusable components
├── theme/
└── utils/
```

## Build for Production

```bash
# macOS
./scripts/build_macos.sh

# Windows (PowerShell)
.\scripts\build_windows.ps1
```

Build scripts compile the Node.js backend and bundle it into the application package.

## Architecture

- **MVVM pattern** with Provider for state management
- **BackendProcessManager** spawns and manages the Node.js backend process
- **BackendService** provides typed REST API access to all backend endpoints
- **WebSocketService** handles real-time streaming events during AI conversations
- Models use `json_serializable` for wire-compatible JSON serialization with the backend
