# Anza — Your Verified Hub for ALU Campus Life

> Anza is a mobile-first Flutter platform that strengthens student engagement and collaboration within the African Leadership University ecosystem. It connects students with events, hackathons, workshops, startup initiatives, internships, and community spaces — all posted by verified clubs, academic teams, and founders.

---

## Table of Contents

- [Overview](#overview)
- [Why Anza? — ALU Context](#why-anza--alu-context)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Team](#team)
- [AI Usage Statement](#ai-usage-statement)

---

## Overview

Anza (meaning "start" in Swahili) is designed to solve a real problem at ALU: **how do students discover what's happening on campus, trust that it's legitimate, and build a record of their participation?**

Unlike generic event apps, Anza introduces a **Verified Hub** model — only recognized clubs, academic teams, and founders can post opportunities. This keeps the feed high-signal and low-noise, so students can trust every post they see.

---

## Why Anza? — ALU Context

ALU students face unique challenges:
- **Information fragmentation** — events are scattered across WhatsApp groups, emails, and posters
- **Trust & legitimacy** — anyone can post anything, making it hard to know what's real
- **Participation recognition** — no central record of campus involvement

Anza addresses all three:
1. **Verified posting** — only authorized organizers can publish, keeping the feed trustworthy
2. **Real-time discovery** — searchable, filterable feed of everything happening on campus
3. **Participation Passport** — a gamified record of every event you've attended, with badges and streaks

---

## Features

### Authentication & Onboarding
- Sign in with your ALU student email (mock auth with seeded accounts)
- Sign up as a new student with interests to personalize your feed
- Onboarding flow explains the platform's core value
- Persisted sessions — return users skip straight to the feed

### Dynamic Feed
- Search events by title, location, or organizer
- Filter by category (Event, Hackathon, Internship, Workshop, Leadership, Startup)
- Cards show banner, category tag, title, poster with verification badge, date, and location
- "New event" FAB — only visible to verified users

### RSVP & Event Details
- RSVP to any event with one tap
- Cancel RSVP at any time
- View full event details: description, date/time, location, attendee count
- Persistent RSVPs survive app restarts via SharedPreferences

### Check-in & Participation Passport
- **QR check-in codes** — organizers display a QR, attendees type the 6-character code
- Validation: correct code, event must be today, no duplicate check-ins
- Every check-in adds an entry to your **Participation Passport**
- **Badges** — earn achievements (First Hackathon, 5 Events Attended, Active in 3 Communities, On a Roll)
- **Streak tracking** — longest run of consecutive days with check-ins
- All passport data persisted across restarts

### Chat & Community Spaces
- Per-event chat rooms for attendees and organizers
- Topic-based community spaces (Robotics Club, Founders Hub, etc.)
- Send and receive messages with auto-scroll
- Chat bubbles distinguish your messages from others'

### Profile
- Avatar with initials and color coding
- Role indicator (Student / Verified with organization name)
- Interest tags from onboarding
- Attendance stats (events attended, day streak, badges earned)
- Badge grid showing earned and locked achievements
- Attendance history timeline
- Sign out with confirmation dialog

### Navigation
- Bottom navigation bar with 4 tabs: Feed, My Events, Communities, Profile
- IndexedStack preserves scroll position and state across tab switches
- Push navigation for detail screens
- "My Events" has sub-tabs: Going and Attended

---

## Tech Stack

| Technology | Purpose |
|---|---|
| **Flutter** (Dart 3.11+) | Cross-platform mobile framework |
| **Provider** | State management (ChangeNotifier pattern) |
| **SharedPreferences** | Local persistence (user, RSVPs, passport, onboarding) |
| **google_fonts** | Space Grotesk (headings) + Inter (body) typography |
| **intl** | Date formatting and localization |
| **qr_flutter** | QR code generation for check-in codes |
| **uuid** | Unique ID generation for users, events, messages |

---

## Architecture

```
lib/
├── app.dart              # Root widget, provider wiring, start screen logic
├── main.dart             # Entry point
├── data/
│   └── seed_data.dart    # All mock data (users, events, communities, messages)
├── models/
│   ├── community.dart    # Community data model
│   ├── event.dart        # Event data model with RSVP/attendance logic
│   ├── message.dart      # Chat message model
│   ├── passport_entry.dart # Check-in record model
│   └── user.dart         # User model with role system
├── providers/
│   ├── auth_provider.dart      # Auth state, sign in/out, session persistence
│   ├── chat_provider.dart      # Message storage and sending
│   ├── events_provider.dart    # Event catalog, filtering, RSVP logic
│   └── passport_provider.dart  # Check-in validation, badges, streaks
├── screens/
│   ├── auth/             # Sign in / sign up screen
│   ├── chat/             # Chat surface (shared by events and communities)
│   ├── checkin/          # QR code entry for event attendance
│   ├── communities/      # Topic-based community list
│   ├── create_post/      # Event creation form (verified users only)
│   ├── event_detail/     # Full event view with actions
│   ├── feed/             # Searchable, filterable event feed
│   ├── my_events/        # RSVP'd and attended event lists
│   ├── onboarding/       # First-launch intro screen
│   ├── profile/          # Profile + Participation Passport
│   └── root_screen.dart  # App shell with bottom navigation
├── services/
│   └── storage_service.dart  # SharedPreferences wrapper
├── theme/
│   ├── app_colors.dart       # Color palette
│   ├── app_text_styles.dart  # Typography scale
│   └── app_theme.dart        # Material 3 ThemeData
└── widgets/
    ├── app_text_field.dart   # Reusable form input
    ├── badge_tile.dart       # Badge display card
    ├── category_chip.dart    # Filter chip
    ├── chat_bubble.dart      # Message bubble
    ├── empty_state.dart      # Empty list placeholder
    ├── event_card.dart       # Event list card
    ├── primary_button.dart   # Styled action button
    ├── profile_stat_tile.dart # Stats counter
    ├── user_avatar.dart      # Initials avatar
    ├── verified_badge.dart   # Verified organization badge
    └── badge_tile.dart       # Badge grid tile
```

### State Management

Anza uses the **Provider** pattern with `ChangeNotifier`:

- **AuthProvider** — single source of truth for the current user
- **EventsProvider** — event catalogue + filtering + RSVP logic
- **ChatProvider** — per-space messages
- **PassportProvider** — check-in validation + badges + streaks

`ChangeNotifierProxyProvider` connects PassportProvider to EventsProvider so check-ins update both simultaneously.

### Persistence

SharedPreferences stores:
- Current user session (JSON-encoded)
- RSVP'd event IDs (string list)
- Passport entries (JSON-encoded list)
- Onboarding completion flag (boolean)

---

## Getting Started

### Prerequisites

- Flutter SDK 3.11+ ([install guide](https://docs.flutter.dev/get-started/install))
- A connected device or emulator

### Setup

```bash
# Clone the repo
git clone https://github.com/davidmuo/anza.git
cd anza

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### Seeded Test Accounts

| Email | Role | Organization |
|---|---|---|
| amara.chen@alustudent.com | Student | — |
| david.okafor@alustudent.com | Verified | Robotics Club |
| grace.mwangi@alustudent.com | Student | — |
| samuel.diallo@alustudent.com | Verified | Academic Success Team |
| fatima.yusuf@alustudent.com | Verified | Founders Hub |
| brian.tumusiime@alustudent.com | Student | — |

---

## Team

| Member | Role | Branch |
|---|---|---|
| David Muo | Developer | `master` |
| Qevin | Developer | `feature/readme-update` |

*Add your team members here.*

---

## AI Usage Statement

AI tools (opencode) were used for:
- **Brainstorming** feature ideas and product decisions
- **Debugging** state management issues and widget overflow
- **Code review** — evaluating code quality and suggesting improvements

All code is the original work of the team. Every team member understands and can explain all submitted code.

---

## Assignment Deliverables

- [x] Mobile application (Flutter)
- [x] Authentication & onboarding
- [x] Dynamic feed with search & filters
- [x] RSVP & participation management
- [x] Chat & communication interfaces
- [x] Profile & identity representation
- [x] Navigation & state handling
- [x] Lightweight persistence (SharedPreferences)
- [ ] PDF report (3 pages max)
- [ ] Demo video (10-15 minutes)
- [ ] Contribution tracker

---

*Built with Flutter for African Leadership University*