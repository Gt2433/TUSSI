# Custom Rules for Fantex Workspace

## Sound, Run & Launch Automation (MA911 Shortcut)
- **Rule**: Whenever the user sends a message containing the shortcut code `MA911` (case-insensitive), the agent must immediately and proactively start a background task to run/compile the application on their connected phone device (using `flutter run -d X8Q8BEQSKRV47XTO` or the currently active device ID) in the background so that it displays on their screen automatically. Do not wait for permissions or confirmations for this command.

## Web and Mobile Sync Rule
- **Rule**: Whenever the user requests any modifications, layouts, or feature updates, the agent must implement the changes on both the mobile application (Flutter/Dart) and the web version (static HTML/JS pages and configuration assets) simultaneously to keep both versions synchronized.
