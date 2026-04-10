# Resonance — Agent Instructions

## Project Overview
Resonance is an iOS app that matches people based on their music taste. Users authenticate, listen to music (in-app or via Apple Music), and get matched with others who share similar listening habits — either in real-time or based on historical taste.

## Tech Stack
- **Language:** Swift 6 (strict concurrency)
- **UI Framework:** SwiftUI only — no UIKit. Zero UIKit imports.
- **Minimum Deployment Target:** iOS 18.0
- **Architecture:** MVVM
- **Music:** MusicKit framework + Apple Music API (developer token is auto-generated)
- **Auth:** Sign in with Apple (primary), Google Sign-In (secondary) via OAuth2
- **Database:** Firebase Firestore
- **Push Notifications:** APNs (no Firebase Cloud Messaging)
- **Location:** Not used. Do not add CoreLocation or any location-related code.

## Architecture Rules

### MVVM Pattern
- **Models** are plain Swift structs conforming to `Codable`, `Sendable`, and `Identifiable` where appropriate.
- **ViewModels** are `@Observable` classes (iOS 17+ Observation framework). Do NOT use `ObservableObject` / `@Published` / `@StateObject` / `@ObservedObject` — these are legacy patterns.
- **Views** are SwiftUI structs. They reference ViewModels via `@State` for owned instances or environment for shared ones.
- Views should be thin — no business logic, no network calls, no Firestore access. All logic goes through ViewModels.
- ViewModels talk to **Services** (see below). ViewModels never import Firebase or MusicKit directly — they call service layer methods.

### Service Layer
- Create dedicated service classes/actors for each domain:
  - `AuthService` — handles Sign in with Apple, Google Sign-In, session management
  - `MusicService` — wraps MusicKit authorization, playback, now-playing detection, listening history
  - `MatchService` — matching logic, both real-time and historical
  - `ChatService` — real-time messaging between matched users
  - `UserService` — profile CRUD, Firestore user document management
  - `NotificationService` — APNs registration, handling incoming notifications
- Services should be `actor` or `final class` with `@MainActor` isolation where needed for UI updates.
- Use Swift 6 structured concurrency (`async/await`, `TaskGroup`, `AsyncStream`) throughout. No Combine unless wrapping a legacy API that requires it.

### Dependency Injection
- Use environment values or a lightweight DI container to inject services into ViewModels.
- Do NOT use singletons (e.g., `shared` instances) except where Apple frameworks require it.

## Swift 6 Concurrency Rules
- All types must be `Sendable`-safe. Enable strict concurrency checking.
- Use `actor` for mutable shared state.
- Use `@MainActor` on ViewModels and any code that updates UI state.
- Prefer `AsyncStream` over Combine publishers for reactive data flows.
- Never use `DispatchQueue` directly — use structured concurrency instead.

## SwiftUI Guidelines
- Use the latest iOS 18 APIs when available (e.g., `@Entry` macro for environment values, mesh gradients, new ScrollView APIs).
- Use `NavigationStack` with path-based navigation. Never use the deprecated `NavigationView`.
- Prefer `.task {}` and `.task(id:)` for async work in views over `onAppear`.
- Use `@Environment` for shared dependencies passed down the view hierarchy.
- Respect Dynamic Type, Dark Mode, and accessibility by default. Always use system colors and semantic fonts unless overridden by design.
- Follow Apple Human Interface Guidelines for layout, spacing, and controls.

## MusicKit Guidelines
- Request MusicKit authorization early in onboarding.
- Use `ApplicationMusicPlayer.shared` for in-app playback.
- Use `SystemMusicPlayer.shared` or `MusicKit`'s now-playing APIs to detect what's playing externally on Apple Music.
- Store listening history snapshots to Firestore for historical matching.
- The developer token is auto-generated — do NOT hardcode tokens.

## Firebase / Firestore Guidelines
- Use the Swift Firebase SDK (v11+).
- Structure Firestore documents for efficient reads — denormalize where appropriate.
- Use Firestore listeners (`addSnapshotListener`) for real-time data (chat messages, match notifications).
- Use Firestore security rules — never trust the client.
- Batch writes when updating multiple documents atomically.
- Keep Firestore document sizes small. Avoid storing large arrays that grow unbounded.

## Authentication Flow
1. Show Sign in with Apple button prominently, Google Sign-In as secondary option.
2. On successful auth, create or update user document in Firestore `users` collection.
3. Store minimal auth state locally (e.g., `@AppStorage` for signed-in flag, keychain for tokens).
4. Handle token refresh and session expiry gracefully.

## Matching Logic
- **Real-time matching:** When a user is listening to a song, query Firestore for other users currently listening to the same song or artist. Notify both users of the match.
- **Historical matching:** Periodically compare listening history between users. Calculate a similarity score based on overlapping artists, genres, and songs. Surface high-similarity users in the match feed.
- Store matches in a `matches` collection with references to both user IDs and the song/artist that triggered the match.

## Chat
- Use a Firestore subcollection under each match document for messages.
- Messages are real-time via snapshot listeners.
- Support text messages at minimum.
- Messages must include timestamp, sender ID, and read status.

## User Profile
- Display name, profile photo (stored in Firebase Storage), bio, favorite genres, top artists.
- Auto-populate top artists and genres from MusicKit listening history.
- Users can manually edit their profile.

## Push Notifications (APNs)
- Register for remote notifications on app launch.
- Store the device token in the user's Firestore document.
- Use a server-side function (Firebase Cloud Functions or similar) to send APNs when a match is found.
- Handle notification taps to deep-link into the match or chat.

## Folder Structure
```
Resonance/
├── App/
│   ├── ResonanceApp.swift
│   └── AppDelegate.swift              # APNs registration
├── Models/
│   ├── User.swift
│   ├── Match.swift
│   ├── Message.swift
│   ├── ListeningSession.swift
│   └── MusicItem.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── HomeViewModel.swift
│   ├── PlayerViewModel.swift
│   ├── MatchViewModel.swift
│   ├── ChatViewModel.swift
│   └── ProfileViewModel.swift
├── Views/
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   └── OnboardingView.swift
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── NowPlayingBar.swift
│   ├── Player/
│   │   ├── PlayerView.swift
│   │   └── MiniPlayerView.swift
│   ├── Match/
│   │   ├── MatchFeedView.swift
│   │   ├── MatchDetailView.swift
│   │   └── MatchNotificationView.swift
│   ├── Chat/
│   │   ├── ChatListView.swift
│   │   └── ChatView.swift
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   └── EditProfileView.swift
│   └── Components/
│       ├── ArtistCard.swift
│       ├── SongRow.swift
│       └── MatchScoreBadge.swift
├── Services/
│   ├── AuthService.swift
│   ├── MusicService.swift
│   ├── MatchService.swift
│   ├── ChatService.swift
│   ├── UserService.swift
│   └── NotificationService.swift
├── Utilities/
│   ├── Extensions/
│   ├── Modifiers/
│   └── Constants.swift
└── Resources/
    └── Assets.xcassets
```

## Firestore Data Model

### `users/{userId}`
```
{
  id: String,
  displayName: String,
  email: String,
  photoURL: String?,
  bio: String?,
  authProvider: "apple" | "google",
  favoriteGenres: [String],
  topArtists: [{ id: String, name: String }],
  currentlyListening: {
    songId: String?,
    songName: String?,
    artistName: String?,
    startedAt: Timestamp?
  } | null,
  deviceToken: String?,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### `matches/{matchId}`
```
{
  id: String,
  userIds: [String, String],
  matchType: "realtime" | "historical",
  triggerSong: { id: String, name: String, artistName: String }?,
  triggerArtist: { id: String, name: String }?,
  similarityScore: Double?,
  createdAt: Timestamp
}
```

### `matches/{matchId}/messages/{messageId}`
```
{
  id: String,
  senderId: String,
  text: String,
  isRead: Bool,
  createdAt: Timestamp
}
```

### `listeningHistory/{userId}/sessions/{sessionId}`
```
{
  id: String,
  songId: String,
  songName: String,
  artistId: String,
  artistName: String,
  genre: String?,
  listenedAt: Timestamp,
  durationSeconds: Int
}
```

## Code Style
- Use Swift naming conventions (camelCase for variables/functions, PascalCase for types).
- Prefer `let` over `var` wherever possible.
- Keep files under 200 lines. Split large views into subviews.
- Add `// MARK: -` comments to organize sections within files.
- No force unwrapping (`!`) unless the value is guaranteed by the system (e.g., `UIApplication.shared`).
- Handle all errors explicitly — no silent `try?` without logging.
- Write doc comments (`///`) for all public service methods.

## Testing
- Write unit tests for ViewModels and Services.
- Use Swift Testing framework (`@Test`, `#expect`) instead of XCTest for new tests.
- Mock services using protocols for testability.

## What NOT to Do
- Do NOT use UIKit. No `UIViewRepresentable`, no `UIViewControllerRepresentable`.
- Do NOT use Combine unless wrapping a legacy callback API.
- Do NOT use `ObservableObject`, `@Published`, `@StateObject`, or `@ObservedObject`.
- Do NOT use `NavigationView` — use `NavigationStack`.
- Do NOT use singletons unless required by Apple frameworks.
- Do NOT hardcode strings — use `String(localized:)` for user-facing text.
- Do NOT store sensitive data in `UserDefaults` — use Keychain.
- Do NOT add third-party dependencies without explicit approval.
