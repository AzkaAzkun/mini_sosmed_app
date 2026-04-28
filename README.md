# Mini Instagram

Clone from instagram with flutter and firebase


## Author

Name: Azka Rizqullah Ramadhani

NRP: 5025231148


## Project Demonstration

Check out the full video demonstration of the app here:
[**Watch Demo Video**](https://drive.google.com/file/d/1ryvmOWOFAmt43lyBRKITee801zGk9w7w/view?usp=sharing)

---

## Features

- **Authentication**: Secure login and registration using Firebase Auth.
- **News Feed**: Dynamic feed to view posts from other users.
- **Story Sharing**: Share temporary updates with your followers.
- **Post Upload**: Easily upload images and captions.
- **Profile Management**: Customize your profile and view your own posts.
- **Location Services**: Share your location with your posts.
- **Search**: Find other users on the platform.
- **Notifications**: Stay updated with interactions on your posts.
- **Home Dashboard**: Clean and intuitive navigation.

---

## Tech Stack

- **Frontend**: [Flutter](https://flutter.dev/) (Dart)
- **Backend**: [Firebase](https://firebase.google.com/)
  - Authentication
  - Firestore (Database)
  - Firebase Storage (Media)
- **State Management**: Provider (or whichever is used, assuming standard)

---

## Getting Started

### Prerequisites
- Flutter SDK installed
- Android Studio / VS Code with Flutter extension
- Firebase Project configured

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/AzkaAzkun/mini_sosmed_app.git
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

---

## Project Structure

```text
lib/
├── models/      # Data models
├── screens/     # UI Screens (Auth, Feed, Profile, etc.)
├── services/    # Firebase & API services
├── widgets/     # Reusable UI components
└── main.dart    # App entry point
```

---
