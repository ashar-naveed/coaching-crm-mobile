# CoachingCRM — Mobile App

A mobile coaching management platform built with Flutter and Firebase, developed for **Mumkin**, a real life-coaching business.

🎥 **[Watch the demo video](https://youtu.be/n90GmZYTxSs)**

---

## Tech Stack

- **Flutter** — cross-platform UI
- **Firebase Auth** — email/password authentication
- **Cloud Firestore** — real-time NoSQL database
- **Riverpod** — state management
- **GoRouter** — declarative navigation
- **flutter_localizations** — English / Arabic support

---

## Features

### Coach

- Dashboard with real-time stats (clients, sessions, pending actions, announcements)
- Client management with live search
- Goal creation with progress tracking
- Action item assignment (pending / completed / delayed)
- Session scheduling with notes
- Real-time chat with unread badges
- Announcements (broadcast to all clients)
- Profile editing

### Client

- Personalized dashboard
- Goal and action item tracking with undo support
- Session reflections
- Direct chat with coach
- Announcement read tracking
- Profile editing

---

## Database

Cloud Firestore with 6 root collections: `users`, `goals`, `actionItems`, `sessions`, `chats`, `announcements`.
See the full schema in the project report.

---

## Getting Started

\`\`\`bash
flutter pub get
flutterfire configure
flutter run
\`\`\`

---

## Author

**Muhammad Ashar Naveed**
Alfaisal University — SE 328, Mobile Application Design and Development
