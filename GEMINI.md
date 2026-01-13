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
# To update:
brew update && brew upgrade --cask blink-reminder
```

### Manual Build
1.  **Build:**
    ```bash
    ./build.sh [version] # e.g., ./build.sh 1.0.2
    ```
2.  **Install:**
    Move the app to the Applications folder to ensure notifications work correctly:
    ```bash
    mv BlinkReminder.app /Applications/
    ```

## Release Protocol & Versioning
**Agent Instruction:** When the user requests a new app version (e.g., "Update to 1.0.3"), you must update the version in the following files:
1.  **`build.sh`**: Update the default `VERSION` variable.
    ```bash
    VERSION="${1:-1.0.3}"
    ```
2.  **`Casks/blink-reminder.rb`**: Update the `version` field.
    ```ruby
    version "1.0.3"
    ```
3.  **Docs**: Check if `README.md` or `GEMINI.md` references the specific version and update if necessary.

**Note:** The GitHub Action `release.yml` automatically extracts the version from the git tag (e.g., `v1.0.3` -> `1.0.3`) and passes it to `build.sh`.

## Recent Changes
- Updated menu bar to display app version (e.g., "Blink Reminder v1.0.2").
- Updated `build.sh` to accept version number as an argument.
- Updated GitHub Actions to pass tag version to build script.
- Added GitHub Actions workflow for automated releases and SHA256 calculation.
- Added Homebrew Cask template for easy installation.
- Added Pause/Resume functionality.
- Implemented "👀" emoji-based icon generation.
- Added ad-hoc code signing and Bundle ID updates for better notification support.
