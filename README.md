# Nomad

A digital postcard app for iPhone. Capture a moment, stamp it with where and when, and send it as a real-looking postcard to another Nomad user — or share it straight to iMessage.

> **Capture → Compose → Send or Share.**

---

## Stack

- **iOS 26+** · iPhone (iPhone Air-first layout)
- **SwiftUI** with Liquid Glass styling
- **Swift Data** for local persistence
- **CloudKit** (public DB) for user-to-user delivery
- **Sign in with Apple** for identity
- **AVFoundation** for capture
- **Core Location + MapKit** for stamping & travel map
- **PencilKit / Photos / WeatherKit / FoundationModels** for delight features

No third-party dependencies — Apple frameworks only.

---

## Features

- Live camera preview with front/back toggle, library fallback
- Reverse-geocoded "City, Country" stamps with country flag + state badge
- 16 hand-drawn city landmarks (Paris, Tokyo, NYC, etc.) + 4 generic theme arts (city / coast / mountain / countryside) as fallback
- 4:3 postcard renderer (@3x via `ImageRenderer`) — same image used for iMessage share and CloudKit upload
- AI caption suggestion via on-device `SystemLanguageModel` (FoundationModels)
- Sign in with Apple onboarding → unique username on CloudKit
- Sent / Mailbox / Travel Map / Stats / Year-in-Review views
- Siri shortcuts via App Intents
- Widgets (Home + Lock Screen) — code scaffolded, needs a Widget Extension target to ship
- Settings: photo quality, sign out, delete account (App Store guideline 5.1.1(v))

---

## Project layout

```
Nomad/
├── Intents/              # Siri shortcuts via App Intents
├── Managers/             # Camera, Location, CloudKit
├── Models/               # SwiftData @Model classes, UserSettings
├── Utilities/            # Renderers, validators, image cache, weather
├── Views/
│   ├── Auth/
│   ├── Camera/
│   ├── Collage/
│   ├── Collections/
│   ├── Composer/         # PostcardView, StampView, CityLandmark, composer
│   ├── History/          # List, Map, Travel Stats
│   ├── Mailbox/
│   ├── Onboarding/
│   ├── Review/           # Year in Review
│   ├── Shared/           # Settings, ShareSheet, RecipientPicker
│   ├── Social/
│   ├── Stamps/
│   └── Timeline/
├── Widgets/              # Home + lock-screen widgets (needs extension target)
├── Assets.xcassets
├── Info.plist
├── PrivacyInfo.xcprivacy
└── NomadApp.swift
```

---

## Running it locally

1. Open `Nomad.xcodeproj` in Xcode 16+.
2. Set the deployment target to iOS 26.0 (already the default).
3. Under **Target → Signing & Capabilities**, pick your Team and a unique Bundle Identifier.
4. Add the **Sign in with Apple** capability.
5. Run on a real iPhone — camera + location don't work in the Simulator.

CloudKit is **opt-in**. By default the app simulates send/receive so it can run without an iCloud entitlement. To enable real CloudKit:

```swift
CloudKitManager.shared.enable()
```

…and add the iCloud + Push Notifications + Background Modes (Remote notifications) capabilities, then deploy the schema in the CloudKit Dashboard (`UserRecord`, `PostcardRecord` — see the engineering brief).

---

## Testing

Swift Testing framework. Run from Xcode (⌘U) or:

```bash
xcodebuild test -scheme Nomad -destination 'platform=iOS Simulator,name=iPhone 16'
```

Coverage: models, CloudKit gating, postcard renderer, sync, stamp heuristic, message validator, manager init, photo library helper.

---

## Status

| Sprint | Status |
|---|---|
| 0 — TestFlight blockers | Code done; Xcode capability + signing setup remaining |
| 1 — Login + Permissions | ✅ Done |
| 2 — Pre-submit polish (Logger, MetricKit, privacy URL) | Pending |
| 3 — Quality bar (a11y, Dynamic Type, empty states) | Pending |
| 4 — Real CloudKit + external testers | Pending |

---

## License

Private project. All rights reserved.
