# BlinkReminder

## Overview
BlinkReminder is a native macOS menu bar application designed to reduce eye strain by reminding users to blink and look away from their screens periodically.

## Features
- **Menu Bar Utility:** Runs quietly in the background with a menu bar icon.
- **Adjustable Intervals:** Choose from preset intervals (e.g., 20 mins, 10 mins).
- **Smart Pause:** Pause reminders during meetings or movies.
- **Two Modes:**
  - **Screen Overlay:** A full-screen overlay with a breathing animation and timer (default).
  - **Notifications:** Standard system notifications (fallback).
- **Custom Icon:** Script-generated application icon using emoji.

## Tech Stack
- **Language:** Swift
- **Frameworks:** SwiftUI, AppKit, UserNotifications
- **Build System:** Shell script (`build.sh`) using `swiftc`.

## Build & Run

### Homebrew (Primary)
```bash
brew tap ntn0de/blink-reminder https://github.com/ntn0de/blink-reminder
brew install --cask blink-reminder
```

### Manual Build
1.  **Build:**
    ```bash
    ./build.sh
    ```
2.  **Install:**
    Move the app to the Applications folder to ensure notifications work correctly:
    ```bash
    mv BlinkReminder.app /Applications/
    ```

## Recent Changes
- Added GitHub Actions workflow for automated releases and SHA256 calculation.
- Added Homebrew Cask template for easy installation.
- Added Pause/Resume functionality.
- Implemented "👀" emoji-based icon generation.
- Added ad-hoc code signing and Bundle ID updates for better notification support.
