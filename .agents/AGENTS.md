# Custom Rules for Fantex Workspace

## Active Device ID
- The currently active Flutter device is **9859c1eb** (CPH2473, Android 14).
- Flutter is located at: `C:\src\flutter\bin\flutter.bat`
- Always use `C:\src\flutter\bin\flutter.bat run -d 9859c1eb` to run the app.

## Sound, Run & Launch Automation (MA911 Shortcut)
- **Rule**: Whenever the user sends a message containing the shortcut code `MA911` (case-insensitive), the agent must immediately and proactively start a background task to run/compile the application using `C:\src\flutter\bin\flutter.bat run -d 9859c1eb` in the background. Do not wait for permissions or confirmations for this command.

## Auto-Run After Every Modification
- **Rule**: After completing ANY code modification or feature implementation (Flutter/Dart files), the agent MUST automatically run `C:\src\flutter\bin\flutter.bat run -d 9859c1eb` in the background as a background task WITHOUT asking for permission or confirmation. This ensures every change is immediately visible on the user's phone. Do not skip this step for any reason.

## Web and Mobile Sync Rule
- **Rule**: Whenever the user requests any modifications, layouts, or feature updates, the agent must implement the changes on both the mobile application (Flutter/Dart) and the web version (static HTML/JS pages and configuration assets) simultaneously to keep both versions synchronized.
