---
title: Tasks
description: A Flutter productivity app for managing daily tasks, focused sessions, and reminders
author: Muhammad Huzaifa
version: 1.0.0
license: MIT
---

# Tasks

![Tasks Logo](assets/tasks_logo.jpg)

**Tasks** is a productivity app that helps you Create tasks, organize them into categories, make custom lists, set reminders so you never miss a deadline, and run focused work sessions with built-in timers. It's built entirely in Flutter with a glassmorphic UI design, and it's completely free, no ads, no hidden catches.

---

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Download](#download)
- [Author](#author)
- [License](#license)

## List of Tables

| Table | Description |
|-------|-------------|
| [Tech Stack](#tech-stack) | Technologies and libraries used |
| [Project Structure](#project-structure) | Folder and file overview |
| [Features](#features) | Full feature breakdown |

---

## Introduction

We all have busy lives — work deadlines, study sessions, errands to run, and a hundred things to keep track of. **Tasks** was built to make that a little easier. It's a simple, good-looking app where you can jot down your tasks, give them due dates and times, mark them as important, and organize them into your own custom lists. You'll get reminded before things are due, so nothing slips through the cracks.

But Tasks isn't just a to-do list. It also has **focused sessions** — think of them as Pomodoro-style work blocks where you pick the tasks you want to tackle, set how long each one takes, and the app keeps you on track with a timer. When you're done, you get a notification saying "Great work!" — which honestly feels pretty satisfying.

Everything syncs to the cloud using Firebase, so your data is always safe and available across sessions. You can sign up with your email or just use Google Sign-In. The whole thing is wrapped in a soft, glassmorphic design with a handwritten font that makes it feel personal, not corporate. And the best part? It's completely free. No ads, no subscriptions, no data selling. Just a tool that works.

---

## Features

| Feature | Description |
|---------|-------------|
| **Task Management** | Create, edit, delete, and toggle tasks with due dates, times, and importance flags |
| **Categories** | Sort tasks by Study, Work, or Home — plus create your own custom lists with icons and colors |
| **Smart Reminders** | Get notified 12 hours before, 2 hours before, and when a task is missed |
| **Focused Sessions** | Build work sessions with multiple tasks and breaks, run them with a live timer |
| **Profile & Stats** | Choose an avatar, edit your name, and track tasks completed and sessions finished |
| **Custom Lists** | Create your own task categories with custom icons and colors |
| **Authentication** | Sign up with email/password or Google Sign-In, with email verification |
| **Account Management** | Update your email, change your password, or delete your account |
| **Legal Pages** | Privacy Policy, Terms & Conditions, and EULA accessible in-app |

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Framework** | Flutter (Dart SDK ^3.11.1) |
| **Backend** | Firebase (Auth, Firestore, Cloud Functions) |
| **Authentication** | Email/Password + Google Sign-In |
| **State Management** | Flutter Riverpod |
| **Notifications** | awesome_notifications |
| **Navigation** | curved_navigation_bar |
| **Icons** | font_awesome_flutter |
| **Launcher Icons** | flutter_launcher_icons |
| **Database** | Cloud Firestore |
| **Design** | Glassmorphic UI, PatrickHand font |

---

## Project Structure

```
flutter_frontend/
├── lib/
│   ├── main.dart              — App entry, Firebase init, AuthGate
│   ├── constants.dart         — Design system (colors, text, spacing)
│   ├── models/                — Task, Session, SessionItem
│   ├── providers/             — auth, services, session providers
│   ├── screens/               — 20 screens (home, login, profile, etc.)
│   ├── services/              — auth, task, session, notification services
│   └── widgets/               — reusable UI components
├── android/                   — Android project
├── assets/                    — logos, avatars, fonts
├── functions/                 — Cloud Functions (TypeScript)
├── test/                      — Unit tests
├── pubspec.yaml               — Dependencies
└── LICENSE                    — MIT License
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (^3.11.1)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- A Firebase project (or use the existing `todo-app-6828d`)

### Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/glasneph/tasks.git
   cd tasks/flutter_frontend
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   - Place your `google-services.json` in `android/app/`
   - Or run `flutterfire configure` to auto-generate it

4. **Run the app**

   ```bash
   flutter run
   ```

### Build Release

```bash
# Android (AAB for Play Store)
flutter build appbundle --release --no-tree-shake-icons

# Android (APK for direct install)
flutter build apk --release --no-tree-shake-icons
```

> **Note:** The `--no-tree-shake-icons` flag is required because some screens use non-constant `IconData` instances with custom colors (e.g., colorful list icons on the Home and My Lists screens), this inconsitency is not an problem, its intentional by the developer, so simply add the flag, without it, Flutter's icon tree-shaking optimization will fail during the release build.

---

## Download

> Download the latest APK from [GitHub Releases](https://github.com/huzaifa4khtar/Tasks-by-Glasneph/releases/tag/v1.0.0).

---

## Author

**Muhammad Huzaifa**
- GitHub: [glasneph](https://github.com/glasneph)
- Instagram: [@huzaifa4khtar](https://www.instagram.com/huzaifa4khtar/)

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

```
MIT License — Copyright (c) 2026 Muhammad Huzaifa
```
