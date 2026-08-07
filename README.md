# Dairy Manager – Flutter Milk Tracking Application

A Flutter-based dairy management application designed to help farmers track milk production, expenses, and income with offline support and automated cloud backup.

## Features

- **Milk entry tracking**: Keep a daily log of milk yields.
- **Morning and evening milk recording**: Track split yields for accurate reporting.
- **Expense tracking**: Log operational costs like feed, medicine, and labor.
- **Monthly summaries**: Get a snapshot of your monthly performance.
- **Charts and analytics**: Visualize yield and financial trends over time.
- **Offline storage using Hive**: Works completely offline.
- **Google Drive backup**: Safeguard your data to the cloud automatically.
- **CSV import/export**: Download data for spreadsheet analysis or import historical logs.
- **Notification reminders**: Never forget to log your daily yield.

## Screenshots
*(Add screenshots here using standard markdown image tags)*
- `![Home Screen](path/to/screenshot1.png)`
- `![Add entry](path/to/screenshot2.png)`
- `![Analytics](path/to/screenshot3.png)`

## Tech Stack
- **Flutter**: Cross-platform UI toolkit.
- **Dart**: Primary programming language.
- **Hive Database**: Fast, lightweight NoSQL offline database.
- **Google Drive API**: Seamless cloud backups.
- **Provider**: App state management.
- **Material Design**: User interface standards.

## Project Structure

This project follows Clean Architecture principles:
```
lib/
├── core/             # Core setups, theme, utils, app logger
├── data/             # Models and repositories (Hive setup)
├── domain/           # Entities and use cases 
├── presentation/     # UI Layer: Screens, widgets, and Providers
├── services/         # External services: Auth, Drive API, Backup scheduler
└── main.dart         # Entry point
```

## Installation Guide

Follow these steps to set up the project locally:

1. **Clone repository**
   ```bash
   git clone https://github.com/kexrthivasan/dairy-manager.git
   cd dairy-manager
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the App**
   ```bash
   flutter run
   ```

*(Note: ensure you have set up a `.env` file containing required API keys for Google API integration, if applicable).*

## Usage Guide

- **Add milk entries**: Tap the "+" button on the Home Screen to log morning and evening yields.
- **Track expenses**: Navigate to the "Expenses" tab to record any costs incurred.
- **Generate reports**: Open "Analytics" or "Full Report" to see performance metrics, or export them to CSV.
- **Backup data**: Go to "Settings" -> "Backup Settings" to link your Google Drive and set up automatic syncing.

## Contribution Guide
Contributions are welcome!
1. Fork the repo and create a new branch (`git checkout -b feature/MyFeature`).
2. Adhere to **SOLID principles** and maintain the Clean Architecture structure.
3. Commit your changes logically (`git commit -m 'Add my feature'`).
4. Push to the branch (`git push origin feature/MyFeature`).
5. Open a Pull Request!

## License
This project is open-source and licensed under the [MIT License](LICENSE).
