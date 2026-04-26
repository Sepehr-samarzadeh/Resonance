# Resonance — App Store Submission Tasks

This document is a self-contained brief for an AI coding agent to take Resonance
from its current state to "ready for App Store submission." The agent reading
this has no prior context — read this whole file before starting work.

---

## 0. Project Context (read first)

**What it is:** Resonance is an iOS social app that matches people by music
taste. Users sign in, the app reads their Apple Music listening history, finds
others with similar taste, and lets matched users chat.

**Repo layout** (relative to repo root):

```
.
├── firebase.json
├── firestore.rules
├── storage.rules
├── functions/                       # Firebase Cloud Functions (Node.js)
│   ├── index.js
│   └── package.json
└── Resonance/                       # iOS app
    ├── Resonance.xcodeproj/
    ├── Resonance/                   # ← all Swift source lives here
    │   ├── App/
    │   │   ├── ResonanceApp.swift
    │   │   └── AppDelegate.swift
    │   ├── Models/
    │   ├── Views/
    │   │   ├── Auth/
    │   │   ├── Chat/
    │   │   ├── Connections/
    │   │   ├── Discovery/
    │   │   ├── Profile/
    │   │   └── …
    │   ├── ViewModels/
    │   ├── Services/
    │   ├── Protocols/
    │   ├── Utilities/
    │   ├── Assets.xcassets/
    │   ├── Info.plist
    │   ├── PrivacyInfo.xcprivacy
    │   ├── Resonance.entitlements
    │   └── AGENTS.md                # ← architectural rules (READ THIS)
    └── ResonanceTests/
```

**Tech stack and rules** are defined in `Resonance/Resonance/AGENTS.md`.
**Read it before writing any Swift.** Key rules:

- Swift 6, strict concurrency. SwiftUI only — no UIKit.
- iOS 18 minimum target (currently set to 26.4 — task #4 lowers this).
- MVVM. ViewModels are `@Observable` classes. **Never** use `ObservableObject`,
  `@Published`, `@StateObject`, `@ObservedObject`, or `NavigationView`.
- ViewModels never import Firebase or MusicKit directly — they call services.
- Services are `actor` or `final class` with `@MainActor` where needed.
- Use `String(localized:)` for user-facing strings.
- Files under 200 lines; split large views into subviews.
- No third-party dependencies without approval (Firebase, GoogleSignIn already in).

**App identity:**

- Bundle ID: `com.sep.Resonance`
- Team ID: `J8B37RB4S6`
- Marketing version: `1.0`, build: `1`
- Defined in `Resonance/Resonance.xcodeproj/project.pbxproj`

**Known data model** (Firestore collections used today):

- `users/{userId}` — profile, currently-listening, FCM device token
- `matches/{matchId}` — pair of userIds, trigger song, similarity score
- `matches/{matchId}/messages/{messageId}` — chat messages
- `friendRequests/{requestId}` — discovery / connection requests
- `listeningHistory/{userId}/sessions/{sessionId}` — historical taste data

Security rules live in `firestore.rules` and `storage.rules` at repo root.
Cloud Functions in `functions/index.js`.

---

## How to use this document

Tasks are grouped by category and priority. Within each task you'll find:

- **Why** — the App Store rule or technical reason
- **Type** — `[CODE]` (you write code), `[CONFIG]` (Xcode project / plist),
  `[EXTERNAL]` (web hosting, App Store Connect, Apple Developer portal — you
  cannot fully do these from code, but you should produce the assets and
  document what the human owner needs to click)
- **Files** — exact paths to create or modify
- **Steps** — concrete actions
- **Acceptance criteria** — how to verify it's done

Work top-to-bottom. Submit each completed task as a separate commit with a
clear message (e.g. `RES-XX: add report-and-block UGC moderation flow`). Do
not skip Apple's UGC requirements (Task 1) — without them the app **will** be
rejected.

---

## TASK 1 — Add User Reporting and Blocking (UGC moderation)

**Priority:** P0 — submission blocker. Apple App Review Guideline 1.2 requires
this for any app with user-generated content (chat is UGC, so is the discovery
feed where users browse other profiles).

### 1.1 What Apple requires

For any app where users see other users' content or messages, you MUST provide:

1. **A method for filtering objectionable material** — typically client-side
   profanity filtering on outgoing messages plus server-side abuse detection.
2. **A way to report offensive content and abusive users** — must be reachable
   from chat, from a user's profile, and from any feed showing other users.
3. **A way to block abusive users** — must hide all content and prevent contact
   from a blocked user.
4. **A published mechanism for the developer to act on reports within 24
   hours** — this is committed to in the privacy policy / EULA, not in code.

### 1.2 [CODE] Add a `Report` model and `BlockedUser` storage

Create `Resonance/Resonance/Models/Report.swift`:

```swift
import Foundation

struct Report: Identifiable, Codable, Sendable {
    var id: String?
    var reporterId: String
    var reportedUserId: String
    var contextType: ContextType   // .profile, .chatMessage, .match
    var contextId: String?         // matchId, messageId, etc.
    var reason: Reason
    var details: String?           // optional free-text from reporter
    var createdAt: Date
    var status: Status

    enum ContextType: String, Codable, Sendable {
        case profile, chatMessage, match
    }

    enum Reason: String, Codable, Sendable, CaseIterable, Identifiable {
        case spam
        case harassment
        case inappropriateContent
        case impersonation
        case underage
        case other

        var id: String { rawValue }

        var localizedTitle: String {
            switch self {
            case .spam: return String(localized: "Spam or scam")
            case .harassment: return String(localized: "Harassment or bullying")
            case .inappropriateContent: return String(localized: "Inappropriate content")
            case .impersonation: return String(localized: "Impersonation")
            case .underage: return String(localized: "User appears underage")
            case .other: return String(localized: "Other")
            }
        }
    }

    enum Status: String, Codable, Sendable {
        case open, reviewed, actioned, dismissed
    }
}
```

Add a `blockedUserIds: [String]` field to the user document. In
`Resonance/Resonance/Models/User.swift` add the property and include it in the
`Codable` extension. Default to `[]` when missing on decode.

### 1.3 [CODE] Create `ModerationService`

Create `Resonance/Resonance/Services/ModerationService.swift` and a matching
protocol in `Resonance/Resonance/Protocols/ModerationServiceProtocol.swift`.

Required methods:

- `submitReport(_ report: Report) async throws` — writes to `reports/{auto}`
  in Firestore.
- `blockUser(currentUserId: String, blockedUserId: String) async throws` —
  adds to `users/{currentUserId}.blockedUserIds`.
- `unblockUser(currentUserId: String, blockedUserId: String) async throws`.
- `fetchBlockedUserIds(for userId: String) async throws -> [String]`.

Inject it via the existing `ServiceContainer` / `services` environment used by
other services (look at how `ChatService` is wired in `App/ResonanceApp.swift`
and the `services` `EnvironmentValues` in `Utilities/`).

### 1.4 [CODE] Profanity filter on outgoing messages

In `Resonance/Resonance/Services/ChatService.swift`, before writing the
message in `sendMessage(matchId:senderId:text:)`, run text through a simple
filter. Create `Resonance/Resonance/Utilities/ProfanityFilter.swift` with a
small bundled word list (start with Apple's
[Surge of Bad Words](https://github.com/zacanger/profane-words) — no third-
party dep, just embed the word list as a `Set<String>` literal). If a banned
substring is detected, throw `ChatServiceError.containsProhibitedContent` and
have the UI show: *"Your message couldn't be sent because it contains
prohibited content."*

This is the "filter" requirement (#1).

### 1.5 [CODE] Report UI in chat

Modify `Resonance/Resonance/Views/Chat/ChatView.swift`:

1. Add a toolbar button (top-right, `ellipsis.circle`) with a `Menu` containing:
   - **Report User**
   - **Block User**
2. Tapping **Report User** presents a sheet: `ReportSheet(reportedUserId:
   contextType: .profile, contextId: nil)` (new file at
   `Resonance/Resonance/Views/Components/ReportSheet.swift`). The sheet has a
   `Picker` of `Report.Reason.allCases`, an optional `TextField` for details,
   and a **Submit** button. On submit, call `ModerationService.submitReport`,
   show a confirmation toast, dismiss.
3. Tapping **Block User** presents a `confirmationDialog`: *"Block {name}?
   You won't see their messages or profile again."* On confirm, call
   `ModerationService.blockUser` and pop the chat view back to the chat list.

Also: long-press on an individual message row should expose a **Report
Message** action that opens `ReportSheet` with `contextType: .chatMessage`
and the `messageId`.

### 1.6 [CODE] Report and block on user profiles

In `Resonance/Resonance/Views/Discovery/UserProfileView.swift`, add the same
toolbar `ellipsis.circle` menu with **Report User** and **Block User**.

### 1.7 [CODE] Honor blocks across the app

A blocked user must disappear from the reporter's experience. Update:

1. `DiscoveryService` (in `Resonance/Resonance/Services/DiscoveryService.swift`):
   filter blocked IDs out of any user list returned to the current user.
   Pass the current user's `blockedUserIds` (cached on `AuthViewModel` or
   loaded by the service) into queries.
2. `MatchService`: when listing matches, exclude any whose `userIds` contains
   a blocked ID.
3. `ChatService.listenForMessages`: drop messages whose `senderId` is in the
   blocked set client-side (cheap belt-and-suspenders on top of the filter).
4. Friend request lists in `Resonance/Resonance/Views/Discovery/RequestsView.swift`:
   hide requests from blocked users.

### 1.8 [CODE] Manage blocks from settings

Add a new section in `Resonance/Resonance/Views/Profile/ProfileSettingsSection.swift`
called **Blocked Users** that navigates to a new view
`Resonance/Resonance/Views/Profile/BlockedUsersView.swift`. The view lists
blocked users with their display name and an **Unblock** button next to each.

### 1.9 [CODE] Firestore security rules for new collections

Edit `firestore.rules` at repo root:

- `match /reports/{reportId}`: allow `create` if `request.auth != null` and
  `request.resource.data.reporterId == request.auth.uid`. Disallow `read`,
  `update`, `delete` from clients (only admin / Cloud Functions read these).
- `match /users/{userId}`: ensure `blockedUserIds` is an allowed field on
  update (existing rule should permit, but verify).

Deploy with `firebase deploy --only firestore:rules` (the human owner will
run this — note in the commit message).

### 1.10 [EXTERNAL] Commit to a 24-hour response window

In the privacy policy and EULA (Task 3), include language:

> *We review reports of objectionable content and take action — including
> ejecting abusive users — within 24 hours of receipt. Contact us at
> support@resonance.app to report content or appeal a moderation decision.*

### 1.11 Acceptance criteria

- [ ] Sending a message containing a banned word fails with a user-visible
      error and writes nothing to Firestore.
- [ ] Reporting from chat creates a `reports/{id}` document with
      `reporterId`, `reportedUserId`, `reason`, `createdAt`, `status: open`.
- [ ] Blocking a user adds to `blockedUserIds` and immediately hides them
      from the discovery feed, matches list, and chat list.
- [ ] Blocked users do not see new messages from the blocker either (mutual
      block effect: filter on either side of `ChatService.listenForMessages`).
- [ ] Settings → Blocked Users shows the list with working Unblock buttons.
- [ ] Firestore rules deny client reads of `reports/`.

---

## TASK 2 — Switch APS environment to production for App Store builds

**Priority:** P0. Required for production push notifications.

**Type:** `[CONFIG]`

**Files:** `Resonance/Resonance/Resonance.entitlements`

### Steps

1. Open `Resonance/Resonance/Resonance.entitlements`. Today it has:
   ```xml
   <key>aps-environment</key>
   <string>development</string>
   ```
2. Apple's recommended approach is to keep two entitlements files (one for
   Debug, one for Release) **or** rely on the fact that the Distribution
   provisioning profile auto-promotes `development` to `production`. The safer
   path: create a second entitlements file for Release.

3. **Implementation:** duplicate the file as
   `Resonance/Resonance/Resonance.Release.entitlements` with `aps-environment
   = production`. In `Resonance.xcodeproj/project.pbxproj`, set
   `CODE_SIGN_ENTITLEMENTS` per-configuration:
   - Debug: `Resonance/Resonance.entitlements`
   - Release: `Resonance/Resonance.Release.entitlements`

4. Verify the Apple Push Notifications capability is enabled on the App ID at
   developer.apple.com.

### Acceptance criteria

- [ ] Release archive (Product → Archive) embeds `aps-environment =
      production` (verify with `codesign -d --entitlements - Resonance.app`).
- [ ] TestFlight build receives push notifications from your production APNs
      flow.

---

## TASK 3 — Stand up real Privacy Policy, Terms of Service, and Support pages

**Priority:** P0. Apple opens these URLs during review. A 404 = rejection.

**Type:** `[EXTERNAL]` + `[CODE]` (only if URL changes)

### What's referenced today

`Resonance/Resonance/Utilities/Constants.swift` (lines 65-66):

```swift
static let privacyPolicyURL = URL(string: "https://resonance.app/privacy")!
static let termsOfServiceURL = URL(string: "https://resonance.app/terms")!
```

These are linked from `LoginView.swift` and `ProfileSettingsSection.swift`.

### Steps

1. **Confirm domain ownership.** If `resonance.app` is owned by the human
   owner, proceed. If not, choose a domain they own and update `Constants.swift`.
2. **Author three pages:**
   - `/privacy` — see template below
   - `/terms` — see template below
   - `/support` — a simple page with a contact email and a section explaining
     the report/moderation process (required to satisfy the 24-hour commitment).
3. **Host them.** A static site on GitHub Pages, Vercel, Cloudflare Pages, or
   Firebase Hosting (the project already uses Firebase — easiest path) is
   fine. To use Firebase Hosting:
   - `firebase init hosting` in the repo, write the three pages into a
     `public/` directory, `firebase deploy --only hosting`.
4. **Verify in a browser** that all three URLs return 200 and the content is
   readable on mobile.

### Privacy Policy must disclose (matches `PrivacyInfo.xcprivacy`):

- **Data collected and linked to user identity:**
  - Email address — for account auth
  - User ID — internal account identifier
  - Name (display name) — shown on profile
  - Audio data (listening history, currently-playing) — for matching
  - Device ID (FCM token) — for push notifications
  - Photo (profile picture) — user-provided
- **No tracking, no third-party advertising.**
- **Data sharing:** listening data and profile info are visible to other
  Resonance users when matched.
- **Data retention:** retained until the user deletes their account, which
  triggers full server-side deletion via the existing `deleteAccount` Cloud
  Function.
- **Children:** the service is not directed at users under 13 (or 16 in EU).
- **Contact:** `support@resonance.app` for privacy requests.

### Terms of Service must include:

- Acceptable use / community guidelines (no harassment, hate, sexual content
  involving minors, illegal activity, spam).
- Statement that the developer reviews reports within 24 hours and may
  terminate accounts.
- Disclaimer of warranties, limitation of liability.
- Governing law (whatever jurisdiction the human owner operates in).
- The "no objectionable content" language Apple requires.

> Apple also requires an EULA. The default Apple EULA is sufficient — it's
> linked automatically from App Store Connect and you do **not** need to host
> your own. Skip a custom EULA unless the owner specifically wants one.

### Acceptance criteria

- [ ] Both `Constants.Legal` URLs return HTTP 200 with the documented content.
- [ ] Tapping the links from `LoginView` and Settings opens the live pages on
      device.

---

## TASK 4 — Lower iOS deployment target to 18.0

**Priority:** P1. Reaches more users and matches the documented architecture
in `AGENTS.md` (which states iOS 18.0 minimum).

**Type:** `[CONFIG]`

**Files:** `Resonance/Resonance.xcodeproj/project.pbxproj`

### Steps

1. Open the `project.pbxproj` and find every `IPHONEOS_DEPLOYMENT_TARGET = 26.4;`
   (currently 4 occurrences: lines around 309, 367, plus tests). Change each
   to `IPHONEOS_DEPLOYMENT_TARGET = 18.0;`.
2. Build the app (`xcodebuild -scheme Resonance -destination
   'generic/platform=iOS' build`). Fix any iOS 26-only API usage. Likely
   suspects:
   - SwiftUI APIs that were added in iOS 19+ (mesh gradients, new ScrollView
     APIs). Audit `Views/` for any.
   - `@Entry` macro is iOS 17+, fine.
   - `Observation` (`@Observable`) is iOS 17+, fine.
3. If a feature truly requires a newer OS, gate it with `if #available(iOS
   N, *)` rather than raising the global target.

### Acceptance criteria

- [ ] App builds and links against iOS 18.0 SDK with no warnings.
- [ ] App runs on an iOS 18.0 simulator and on the latest iOS device.

---

## TASK 5 — App Icon: provide all required sizes

**Priority:** P1.

**Type:** `[CONFIG]`

**Files:** `Resonance/Resonance/Assets.xcassets/AppIcon.appiconset/`

### Current state

Only one `1024x1024` universal icon (`resonance-icon-1024.png`). For iOS 14+
this is technically sufficient — Xcode will scale it — but App Store Connect
ingestion has historically been sensitive. Best practice is to provide
explicit sizes.

### Steps

1. Use the existing `resonance-icon-1024.png` as the source. Generate the
   following PNGs (no alpha channel, no transparency, no rounded corners —
   Apple applies the mask):

   | Size | Filename | Use |
   |---|---|---|
   | 1024×1024 | `AppIcon-1024.png` | App Store |
   | 180×180 | `AppIcon-60@3x.png` | iPhone 60pt @3x |
   | 120×120 | `AppIcon-60@2x.png` | iPhone 60pt @2x |
   | 167×167 | `AppIcon-83.5@2x.png` | iPad Pro |
   | 152×152 | `AppIcon-76@2x.png` | iPad |
   | 80×80 | `AppIcon-40@2x.png` | Spotlight |
   | 120×120 | `AppIcon-40@3x.png` | Spotlight |
   | 87×87 | `AppIcon-29@3x.png` | Settings |
   | 58×58 | `AppIcon-29@2x.png` | Settings |
   | 60×60 | `AppIcon-20@3x.png` | Notifications |
   | 40×40 | `AppIcon-20@2x.png` | Notifications |

2. Replace the `Contents.json` to enumerate all images. Use this template
   (one entry per size×idiom combination):

   ```json
   {
     "images": [
       { "filename": "AppIcon-20@2x.png", "idiom": "iphone", "scale": "2x", "size": "20x20" },
       { "filename": "AppIcon-20@3x.png", "idiom": "iphone", "scale": "3x", "size": "20x20" },
       { "filename": "AppIcon-29@2x.png", "idiom": "iphone", "scale": "2x", "size": "29x29" },
       { "filename": "AppIcon-29@3x.png", "idiom": "iphone", "scale": "3x", "size": "29x29" },
       { "filename": "AppIcon-40@2x.png", "idiom": "iphone", "scale": "2x", "size": "40x40" },
       { "filename": "AppIcon-40@3x.png", "idiom": "iphone", "scale": "3x", "size": "40x40" },
       { "filename": "AppIcon-60@2x.png", "idiom": "iphone", "scale": "2x", "size": "60x60" },
       { "filename": "AppIcon-60@3x.png", "idiom": "iphone", "scale": "3x", "size": "60x60" },
       { "filename": "AppIcon-1024.png", "idiom": "ios-marketing", "scale": "1x", "size": "1024x1024" }
     ],
     "info": { "author": "xcode", "version": 1 }
   }
   ```

3. Verify the source PNG has **no transparency**. If it does, flatten against
   black or the brand background (`musicRed`).

### Acceptance criteria

- [ ] Build → no missing-icon warnings in Xcode.
- [ ] App icon renders correctly on home screen, Spotlight, Settings, and
      notifications on a real device.

---

## TASK 6 — Reconcile FCM vs APNs

**Priority:** P1.

**Type:** `[CODE]` (decision + cleanup)

### The discrepancy

`Resonance/Resonance/AGENTS.md` line 14 states: *"Push Notifications: APNs
(no Firebase Cloud Messaging)."* But the actual code uses Firebase Messaging:

- `Resonance/Resonance/App/AppDelegate.swift` imports `FirebaseMessaging`,
  forwards APNs token to `Messaging.messaging()`, and stores the FCM token.
- `functions/index.js` likely uses FCM to send.

### Decision

**Use FCM.** It's already wired end-to-end, and rewriting the server to send
direct APNs payloads adds risk for no benefit. Update `AGENTS.md` line 14 to
read: *"Push Notifications: APNs delivery via Firebase Cloud Messaging
(FCM) — APNs key is uploaded to Firebase, app stores FCM tokens."*

(Alternative: rip out FCM and send via APNs directly. Only do this if the
human owner explicitly requests it. It is meaningfully more work.)

### Steps

1. Edit `Resonance/Resonance/AGENTS.md` line 14 as above.
2. Verify `functions/index.js` uses `admin.messaging().send(...)` correctly.
3. Confirm at developer.apple.com → Keys, that an APNs Auth Key (`.p8`) has
   been created with **APNs** capability enabled.
4. Confirm in Firebase Console → Project Settings → Cloud Messaging → iOS
   App Configuration, that the `.p8` key, key ID, and team ID `J8B37RB4S6`
   are uploaded.

### Acceptance criteria

- [ ] `AGENTS.md` reflects reality.
- [ ] Sending a push from `functions/index.js` reaches a TestFlight device.

---

## TASK 7 — Remove debug-only code paths from Release builds

**Priority:** P1. Apple sometimes flags developer-tooling UI as confusing.

**Type:** `[CODE]`

### What to check

Search the codebase for `#if DEBUG` blocks. Confirm every such block is
properly compiled out of Release. Known cases:

- `Resonance/Resonance/Views/Profile/ProfileSettingsSection.swift` lines
  23-27, 139-141, 179-270 — "Seed Test Match" debug button. **Verify** the
  `#if DEBUG` properly excludes the `Functions` import, the seed buttons,
  and the `seedTestMatch` callable. Build a Release configuration and grep
  the resulting `.app` for `seedTestMatch` — should not appear.

### Steps

1. `xcodebuild -scheme Resonance -configuration Release build`
2. Verify Release `.app` binary does **not** contain debug strings:
   ```
   strings <path>/Resonance.app/Resonance | grep -i 'seed\|debug-test-user'
   ```
3. If it does, audit the `#if DEBUG` boundaries.

### Acceptance criteria

- [ ] No debug UI visible in a Release build run on device.
- [ ] No debug strings in the Release binary.

---

## TASK 8 — Sign in with Apple compliance

**Priority:** P1. Guideline 4.8.

**Type:** `[CODE]`

### Rule

If you offer any third-party login (Google, Facebook, etc.), you MUST offer
Sign in with Apple, **at least equivalent in placement and prominence**.

### Current state

`Resonance/Resonance/Views/Auth/LoginView.swift` already shows
`SignInWithAppleButton` above the Google button (lines 88-115), both same
height (50pt), same corner radius. **This is compliant** — no change needed.

### Steps

1. Visually verify on a real device that the Apple button is at least as
   prominent as the Google button (same size, same visual weight).
2. Confirm `com.apple.developer.applesignin` is in
   `Resonance/Resonance/Resonance.entitlements`. ✓ (already present).
3. In App Store Connect → App Information, declare "Sign in with Apple."

### Acceptance criteria

- [ ] Side-by-side review of LoginView passes Apple's "equivalent prominence"
      test.

---

## TASK 9 — Account deletion (verify completeness)

**Priority:** P0 (already partially done). Guideline 5.1.1(v).

**Type:** `[CODE]` audit

### Current state

`ProfileSettingsSection.swift` lines 113-137 has a Delete Account button
calling `onDeleteAccount`. The actual deletion logic must exist in
`AuthService` / `UserService` and (from commit `ae1325e`) is enforced by a
Cloud Function in `functions/index.js`.

### Steps

1. Read `functions/index.js` and confirm the deletion function:
   - Deletes the user document from `users/{uid}`.
   - Deletes the user's `listeningHistory/{uid}` subcollection.
   - Deletes the user's profile photo from Firebase Storage.
   - Either deletes their messages or anonymizes their `senderId` in messages
     they sent (so the other party still has chat history but with "Deleted
     User" as the sender — this is the friendlier UX).
   - Deletes any `friendRequests/` referencing the user.
   - Deletes any `matches/` where the user is a participant **only if the
     other party is also deleted**, otherwise marks the match as
     `participantDeleted: true` so the surviving user sees a "User left
     Resonance" tombstone.
   - Calls `auth.deleteUser(uid)` to remove the Firebase Auth record.
2. If any of the above is missing, add it. The function must be `https.onCall`
   so the client can invoke it after re-authentication.
3. The client side: ensure `AuthService.deleteAccount` re-authenticates the
   user (Apple/Google) before calling the function — Firebase requires recent
   auth for account deletion.

### Acceptance criteria

- [ ] Deleting an account leaves no `users/{deletedId}` document, no
      Storage photo, no listening history.
- [ ] The other party in a match still sees the chat history but the sender
      shows as "Deleted User" or a tombstone.
- [ ] User can re-sign-up with the same Apple ID afterward.

---

## TASK 10 — Permission prompt UX

**Priority:** P2. Guideline 5.1.1.

**Type:** `[CODE]`

### Rule

Don't request permissions on launch. Request each one only when the feature
that needs it is engaged, and explain *why* in a custom pre-prompt.

### Current state

- **Notifications** — `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
  immediately calls `registerForPushNotifications` which calls
  `UNUserNotificationCenter.requestAuthorization`. This **is** prompting on
  launch. ❌
- **Apple Music** — likely requested in onboarding (good).
- **Photo Library** — likely requested when user taps "change photo" (good).

### Steps

1. Move the notification permission request out of `AppDelegate` and into
   the post-onboarding flow:
   - After the user signs in and completes onboarding (genre/artist picks),
     show a screen explaining: *"Get notified when someone matches with you
     or sends a message."* with **Enable Notifications** and **Not Now**
     buttons.
   - On tap, call `UNUserNotificationCenter.current().requestAuthorization`.
   - Persist a flag (`hasSeenNotificationPrompt` in `@AppStorage`) so we
     don't ask repeatedly.
2. Verify each `Info.plist` usage description string is human-readable and
   explains the *value* to the user — not just the technical requirement.
   Current strings in `Resonance/Resonance/Info.plist`:
   - `NSAppleMusicUsageDescription` — already good.
   - `NSPhotoLibraryUsageDescription` — already good.

### Acceptance criteria

- [ ] Fresh install does NOT show a notifications permission alert until
      after onboarding completes and the user taps "Enable Notifications."

---

## TASK 11 — Empty-state and graceful-degradation review

**Priority:** P2. Guideline 2.1 — App Completeness.

**Type:** `[CODE]` audit

### What App Review will test

Reviewers create a brand-new account on a device with no Apple Music
subscription and tap through every screen. Anything that crashes, shows a
blank screen, or shows an unrecoverable error is a rejection.

### Required handling

| State | Required UX |
|---|---|
| User denies MusicKit authorization | Show a full-screen explainer + "Open Settings" button. Allow profile/discovery to function with empty taste data. |
| User has no Apple Music subscription | Detect via `MusicSubscription.subscriptionUpdates` and show a non-blocking "Subscribe to Apple Music to unlock real-time matching" banner. App must remain usable. |
| User has zero matches | Empty state on Matches tab: "No matches yet — keep listening!" with illustration. Not a blank screen. |
| User has zero messages | Empty state on Connections tab: "Start a conversation with one of your matches." |
| Network offline | Cached content where possible; clear "You're offline" banner; do not crash on retry. |
| Brand-new account, no listening history | Onboarding must walk them through picking favorite artists/genres so they can be matched on stated preferences before they have history. |

### Steps

1. Walk every screen in `Views/` with an empty/uninitialized ViewModel and
   note any blank states or crashes.
2. Add SwiftUI `ContentUnavailableView` for each empty state. Example:

   ```swift
   ContentUnavailableView(
       String(localized: "No matches yet"),
       systemImage: "music.note.list",
       description: Text(String(localized: "Listen to music to start matching."))
   )
   ```

3. For MusicKit auth-denied state, create
   `Resonance/Resonance/Views/Components/MusicAuthDeniedView.swift`.

### Acceptance criteria

- [ ] Brand-new account on a fresh device, no Apple Music subscription, can
      navigate every tab without crashes or blank screens.

---

## TASK 12 — Accessibility audit

**Priority:** P2. Apple now actively rejects apps with broken accessibility.

**Type:** `[CODE]` audit

### Steps

1. Run **Accessibility Inspector** (Xcode → Open Developer Tool →
   Accessibility Inspector) and audit every screen.
2. Verify:
   - All `Image(systemName:)` decorative icons have `.accessibilityHidden(true)`.
   - All tap targets are at least 44×44pt.
   - All text uses semantic fonts (`.body`, `.headline`, etc.) and respects
     Dynamic Type — already mostly done per `AGENTS.md`.
   - Color contrast meets WCAG AA on the gradient backgrounds in
     `LoginView.swift`.
   - VoiceOver reads every screen meaningfully.

### Acceptance criteria

- [ ] Accessibility Inspector audit shows zero errors per screen.
- [ ] VoiceOver flow from launch → sign-in → home is usable without sight.

---

## TASK 13 — App Store Connect setup (external)

**Priority:** P0 — required to submit.

**Type:** `[EXTERNAL]` — the human owner does these in a browser. Document
exactly what they need to click.

### Prerequisites

- Apple Developer Program enrollment (US$99/yr) under the team `J8B37RB4S6`.
- Bundle ID `com.sep.Resonance` registered in
  developer.apple.com → Certificates, IDs & Profiles → Identifiers, with
  capabilities: **Sign in with Apple**, **Push Notifications**.

### Steps for the human owner

1. **App Store Connect → Apps → +New App.**
   - Platform: iOS
   - Name: **Resonance** (must be unique on the App Store; if taken, add a
     subtitle disambiguator)
   - Primary language: English (U.S.)
   - Bundle ID: `com.sep.Resonance`
   - SKU: `resonance-ios-001` (or any unique string — internal only)
   - User Access: Full Access
2. **App Information:**
   - Subtitle (≤30 chars): suggested *"Connect through music"*
   - Category: Primary — **Social Networking**, Secondary — **Music**
   - Content Rights: confirm you have rights to all content
   - Age Rating questionnaire — see Task 14.
3. **Pricing and Availability:** Free, all territories (or selected ones).
4. **App Privacy:** answer the questionnaire to mirror
   `Resonance/Resonance/PrivacyInfo.xcprivacy`:
   - **Data Linked to User:** Email, Name, User ID, Photos, Audio Data,
     Device ID
   - **Used for:** App Functionality (only)
   - **Not used for tracking.**
   - **Not shared with third parties.** (Firebase processes data on your
     behalf — that's a processor relationship, not "shared.")
5. **Sign-In Information** (review notes): provide a working test account.
   See Task 15.
6. **Version 1.0 Submission:**
   - Upload screenshots (Task 16)
   - Description, keywords, support URL, marketing URL (optional), promo text
   - What's New: *"Initial release."*
   - Build: select the TestFlight build (Task 17)
   - Export Compliance: **Yes** uses encryption, **Yes** only standard
     encryption (HTTPS) — qualifies for the exemption, no docs to upload.

### Acceptance criteria (for the agent: write a CHECKLIST.md the human owner
can tick through)

- [ ] App record exists in App Store Connect with bundle ID `com.sep.Resonance`.
- [ ] App Privacy questionnaire saved.
- [ ] At least one build uploaded via Xcode Organizer.

---

## TASK 14 — Age rating

**Priority:** P0.

**Type:** `[EXTERNAL]`

### Decision

Resonance is a social app with **moderated** UGC (after Task 1). The age
rating questionnaire in App Store Connect → App Information → Age Rating:

| Question | Answer | Why |
|---|---|---|
| Cartoon or Fantasy Violence | None | |
| Realistic Violence | None | |
| Sexual Content or Nudity | None | |
| Profanity or Crude Humor | None | (filtered by your profanity filter) |
| Alcohol, Tobacco, or Drug Use or References | None | |
| Mature/Suggestive Themes | None | |
| Horror/Fear Themes | None | |
| Medical/Treatment Information | None | |
| Gambling | None | |
| Contests | None | |
| Unrestricted Web Access | **No** | |
| User-Generated Content | **Yes — moderated** | Chat + profiles |
| Social Networking Features | **Yes** | Match + chat |

Expected resulting rating: **12+** (because of "Infrequent/Mild Mature/Suggestive
Themes" implied by user-generated content). Without moderation it would be 17+.

### Acceptance criteria

- [ ] Age rating answers saved in App Store Connect.

---

## TASK 15 — Reviewer test account

**Priority:** P0. Apple cannot review the app without one — they don't sign
up with their own Apple ID.

**Type:** `[EXTERNAL]` + `[CODE]` (seed)

### Steps

1. **Create a dedicated Apple ID** (e.g. `resonance.review@<your-domain>.com`)
   with a working Apple Music subscription on the test device — or a sandbox
   Apple ID with an Apple Music free trial.
2. **Sign in once on a test device,** complete onboarding (pick favorite
   artists/genres), so the account has a populated profile.
3. **Seed test data** so the reviewer sees a non-empty experience:
   - Use the existing `seedTestMatch` Cloud Function (Task 7) — but only
     from a one-off admin script, NOT from the shipped app. From a local
     Node script:
     ```js
     const admin = require('firebase-admin');
     admin.initializeApp();
     // Create 2-3 fake users with realistic profiles
     // Create 2-3 matches between the review account and the fake users
     // Seed a few chat messages in each match
     ```
   - Or invoke the existing function manually with the review account's UID.
4. **In App Store Connect → App Review Information,** enter:
   - Sign-in required: **Yes**
   - User name: `resonance.review@<domain>.com`
   - Password: (the password)
   - Notes for Reviewer:
     ```
     Resonance is a music-taste-based social app. To test:
     1. Sign in with the provided credentials.
     2. The account already has 3 pre-seeded matches and chat threads —
        tap the Connections tab to view them.
     3. To test reporting/blocking, open any chat → top-right menu →
        Report or Block.
     4. To test matching, the account is configured to "currently listen"
        to a popular song that other test accounts also listen to.
     Apple Music subscription is required for full functionality but the
     app remains usable without one.
     ```

### Acceptance criteria

- [ ] Test account exists, has populated profile, has matches and messages.
- [ ] Credentials saved in App Store Connect → App Review Information.

---

## TASK 16 — Screenshots and metadata

**Priority:** P0.

**Type:** `[EXTERNAL]` + asset generation

### Required screenshots

App Store Connect requires at minimum **one** of these device sizes (Apple
will scale to others):

| Device class | Resolution | Required | How |
|---|---|---|---|
| 6.9" iPhone (16 Pro Max) | 1320×2868 | **Yes** | Run on iPhone 16 Pro Max simulator, ⌘S to capture. |
| 6.5" iPhone (11 Pro Max / XS Max) | 1242×2688 or 1284×2778 | **Yes** if 6.9" not provided | Same. |
| 13" iPad Pro (M4) | 2064×2752 | only if iPad-supported | App is iPhone-only based on `TARGETED_DEVICE_FAMILY` — confirm in `project.pbxproj`. |

You need **3-10 screenshots** per device size. Recommended sequence:

1. **Login** — show the gradient + Sign in with Apple button.
2. **Match feed** — populated Connections tab.
3. **Match detail / now-playing** — the matching moment.
4. **Chat** — a thread in progress.
5. **Profile** — top artists, genres, On Repeat.
6. **Discovery** — browsing other users.

### Steps

1. Run on `iPhone 16 Pro Max` simulator with the seeded review account
   (Task 15).
2. Navigate to each screen, ⌘S to capture. Saves to Desktop.
3. Optional: drop into a screenshot framing tool (Fastlane Frameit, or
   manual in Figma) to add a device frame and a single-line caption per
   screen.
4. Upload via App Store Connect → App Store → 1.0 Prepare for Submission →
   iPhone 6.9" Display.

### Required metadata text

| Field | Limit | Suggested |
|---|---|---|
| Name | 30 | Resonance |
| Subtitle | 30 | Connect through music |
| Promotional Text | 170 | (changeable without resubmission) |
| Description | 4000 | See template below |
| Keywords | 100 (comma-separated) | music,match,connect,social,taste,share,listen,artist,song,friends |
| Support URL | URL | https://resonance.app/support |
| Marketing URL | URL (optional) | https://resonance.app |

**Description template:**

```
Resonance connects you with people who share your music taste.

• Match in real time with someone listening to the same song right now.
• Match by historical taste — find people whose top artists overlap yours.
• Chat with your matches and discover new music together.
• Curated profile with your top artists, genres, and "On Repeat" tracks.

Sign in with Apple. Apple Music subscription recommended for full
functionality.

By using Resonance you agree to our community guidelines: no harassment,
hate speech, spam, or inappropriate content. We respond to reports within
24 hours.

Privacy: https://resonance.app/privacy
Terms: https://resonance.app/terms
Support: https://resonance.app/support
```

### Acceptance criteria

- [ ] At least 3 screenshots uploaded for the 6.9" iPhone size.
- [ ] All metadata fields completed.

---

## TASK 17 — Build, archive, and TestFlight

**Priority:** P0.

**Type:** `[CODE]` + `[CONFIG]`

### Pre-archive checklist

- [ ] Marketing version is `1.0`, build is incremented from any previous
      TestFlight upload (`CURRENT_PROJECT_VERSION` in `project.pbxproj`).
- [ ] Release configuration uses production APS entitlement (Task 2).
- [ ] No DEBUG code paths in the binary (Task 7).
- [ ] All capabilities enabled in App ID:
      - Sign in with Apple
      - Push Notifications
      - Associated Domains (only if you implement universal links — not
        required for v1)

### Archive

1. In Xcode, select **Any iOS Device (arm64)** from the destination dropdown
   (NOT a simulator).
2. **Product → Archive.**
3. When the Organizer opens, select the new archive → **Distribute App** →
   **App Store Connect** → **Upload**. Use automatic signing.
4. Wait for "Upload Successful" — typically 5-15 min.
5. In App Store Connect → TestFlight, the build appears in **Processing**
   (~30 min). Once green, it's ready.

### Provide export compliance answers

When prompted (in Organizer or App Store Connect):

- Does your app use encryption? **Yes**
- Does it qualify for an exemption? **Yes — only standard encryption (HTTPS,
  App Transport Security).**
- Result: no `ITSAppUsesNonExemptEncryption` change needed, but you can also
  add `<key>ITSAppUsesNonExemptEncryption</key><false/>` to `Info.plist` to
  skip the question on every upload — recommended.

### Internal TestFlight

1. App Store Connect → TestFlight → Internal Testing → add testers
   (yourself, the human owner).
2. Install via TestFlight app on an iPhone.
3. **Smoke-test the full flow on a real device:** sign in, onboarding,
   listen to a song, check matches, send a message, report a user, block
   a user, delete account.
4. If anything fails, fix → bump build → re-upload → retest.

### Acceptance criteria

- [ ] Build appears as "Ready to Submit" in TestFlight.
- [ ] Internal testers can install and use the app.
- [ ] Push notifications arrive (production APNs).

---

## TASK 18 — Submit for review

**Priority:** P0.

**Type:** `[EXTERNAL]`

### Steps

1. App Store Connect → App Store → 1.0 Prepare for Submission.
2. Confirm:
   - Build selected (Task 17 build)
   - Screenshots uploaded (Task 16)
   - Metadata complete (Task 16)
   - App Privacy answered (Task 13)
   - Age Rating answered (Task 14)
   - Sign-in info for reviewer set (Task 15)
   - Export Compliance answered (Task 17)
3. **Add to Review.**
4. **Submit for Review.**

Apple typically responds within 24-48 hours. If rejected, the rejection
notice cites a specific guideline — fix and resubmit.

### Common rejection reasons specific to this app

| Reason | Fix |
|---|---|
| Guideline 1.2 — UGC moderation | Task 1 |
| Guideline 5.1.1(v) — account deletion | Task 9 |
| Guideline 4.8 — Sign in with Apple parity | Task 8 |
| Guideline 2.1 — broken empty states | Task 11 |
| Privacy policy URL 404 | Task 3 |
| Reviewer can't sign in | Task 15 |
| Apple Music required but not declared | Make it clear in the description that Apple Music subscription is recommended, not required, and that the app degrades gracefully (Task 11) |

---

## TASK 19 — Post-approval

**Priority:** P1 — operational hygiene after launch.

**Type:** `[CODE]` + ops

1. **Monitor reports.** Build a simple admin dashboard or Firebase Console
   query to surface new `reports/` documents daily. The 24-hour SLA in your
   privacy policy is a real commitment.
2. **Crash reporting.** Add Firebase Crashlytics (already part of Firebase
   suite — minimal code) or accept Apple's built-in Xcode Organizer crash
   reports.
3. **Analytics.** If you add any analytics SDK, update `PrivacyInfo.xcprivacy`
   AND App Privacy in App Store Connect. Don't ship analytics that are not
   declared.
4. **Versioning.** For 1.1, bump `MARKETING_VERSION` to `1.1` and reset
   build to `1` (or keep monotonic — both work).

---

## Quick reference: file paths cheat sheet

| What | Path |
|---|---|
| Architecture rules | `Resonance/Resonance/AGENTS.md` |
| Info.plist | `Resonance/Resonance/Info.plist` |
| Privacy manifest | `Resonance/Resonance/PrivacyInfo.xcprivacy` |
| Entitlements | `Resonance/Resonance/Resonance.entitlements` |
| Xcode project | `Resonance/Resonance.xcodeproj/project.pbxproj` |
| Login | `Resonance/Resonance/Views/Auth/LoginView.swift` |
| Settings | `Resonance/Resonance/Views/Profile/ProfileSettingsSection.swift` |
| Chat | `Resonance/Resonance/Views/Chat/ChatView.swift` |
| User profile (other users) | `Resonance/Resonance/Views/Discovery/UserProfileView.swift` |
| Constants (legal URLs) | `Resonance/Resonance/Utilities/Constants.swift` |
| AppDelegate (push) | `Resonance/Resonance/App/AppDelegate.swift` |
| Chat service | `Resonance/Resonance/Services/ChatService.swift` |
| Discovery service | `Resonance/Resonance/Services/DiscoveryService.swift` |
| Cloud Functions | `functions/index.js` |
| Firestore rules | `firestore.rules` |
| Storage rules | `storage.rules` |
| App icon catalog | `Resonance/Resonance/Assets.xcassets/AppIcon.appiconset/` |

---

## Execution order summary

Submission-blocking work (must do, in order):

1. Task 1 — UGC reporting & blocking
2. Task 3 — Privacy/Terms/Support pages live
3. Task 9 — Verify account deletion completeness
4. Task 2 — Production APS entitlement
5. Task 5 — App icon sizes
6. Task 7 — DEBUG code excluded from Release
7. Task 13 — App Store Connect record + App Privacy
8. Task 14 — Age rating
9. Task 15 — Test account + seed data
10. Task 16 — Screenshots + metadata
11. Task 17 — Archive + TestFlight
12. Task 18 — Submit

Strongly recommended before submission:

- Task 4 — Lower deployment target to iOS 18.0
- Task 6 — Reconcile FCM/APNs documentation
- Task 8 — Sign in with Apple visual parity check
- Task 10 — Defer notification permission prompt
- Task 11 — Empty states / graceful degradation
- Task 12 — Accessibility audit

Post-launch:

- Task 19 — Monitoring, crash reporting, analytics hygiene

Good luck — work top-to-bottom, verify each task's acceptance criteria
before moving on.
