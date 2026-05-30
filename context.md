# Quotes (project name on disk: `quotesWidget`)

iOS app + Home Screen widget. The user enters quotes with authors in the app; the
widget displays one random quote per day, rotating at 8:00 AM in the user's local
time zone.

Built with Xcode 26 on iOS 26.5 SDK. Target device is the user's iPhone, signed
with personal team `G73MR894DY` (bundle prefix `Dream-AI.`).

## Layout

```
quotesWidget/
├── quotesWidget.xcodeproj
├── quotesWidget/                       # App target
│   ├── quotesWidgetApp.swift           # @main, injects QuoteStore
│   ├── ContentView.swift               # Add / list / delete UI
│   ├── Quote.swift                     # Codable model (id, text, author)
│   ├── QuoteStore.swift                # ObservableObject + App Group store
│   └── quotesWidget.entitlements       # App Group entitlement
├── QuotesWidgetExtension/              # Widget target
│   ├── QuotesWidgetExtensionBundle.swift   # @main WidgetBundle
│   ├── QuotesWidgetExtension.swift     # StaticConfiguration widget + provider
│   ├── AppIntent.swift                 # Leftover from Xcode template, unused — safe to delete
│   └── QuotesWidgetExtensionExtension.entitlements
├── SETUP.md                            # Original onboarding notes (historical)
└── CLAUDE.md                           # This file
```

`Quote.swift` and `QuoteStore.swift` are members of **both** targets — verify via
each file's Target Membership in the File Inspector. They're physically located
in the app folder, not duplicated.

## How app and widget share data

- App Group ID: **`group.Dream-AI.quotesWidget`** — enabled on both targets via
  `Signing & Capabilities → App Groups`. Hard-coded in
  `QuoteStoreConfig.appGroupID` in `QuoteStore.swift`. If you change it, change
  the capability on both targets too.
- Storage: JSON-encoded `[Quote]` array under `UserDefaults(suiteName:)` key
  `"quotes"`.
- App writes via `QuoteStore.save()` (called from the `didSet` on `quotes`).
- Widget reads via the static `QuoteStore.loadQuotes()` — no
  `ObservableObject` plumbing in the extension.
- After every write, the app calls `WidgetCenter.shared.reloadAllTimelines()`
  so adding/deleting a quote refreshes the widget immediately rather than waiting
  for the next 8 AM.

## Widget timeline

`getTimeline(in:completion:)` in `QuotesWidgetExtension.swift`:
- Anchors at 8:00 AM local time today (or yesterday if 8 AM hasn't happened yet).
- Pre-rolls 7 daily entries, each with a randomly-picked quote.
- Returns `Timeline(entries, policy: .atEnd)` so iOS asks for the next week
  after the last entry fires.

Each day's quote is decided at timeline-generation time, not at 8 AM that
morning — so adding a new quote *tonight* won't necessarily show up tomorrow
unless `reloadAllTimelines()` runs (which it does on any add/delete in the app).

Display name on the home screen is set via the build setting
`INFOPLIST_KEY_CFBundleDisplayName = Quotes` (added to both Debug and Release of
both targets). The Xcode `General → Display Name` field is unreliable on Xcode
26 projects — prefer the build setting.

## Common breakage and gotchas

- **Xcode 26 strict imports.** The project has
  `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`. This means files must
  import every module whose members they use — transitive imports don't count.
  `QuoteStore.swift` imports `Combine` (for `@Published`, `ObservableObject`)
  and `SwiftUI` (for `Array.remove(atOffsets:)`). Don't remove those.
- **visionOS embed mismatch.** `SUPPORTED_PLATFORMS` originally included
  `xros xrsimulator`. If the widget extension is built for visionOS while the
  app is built for iOS, the embed phase fails. Both targets' `General →
  Supported Destinations` should be restricted to iPhone (and iPad if desired).
- **App Group not visible to widget.** If the widget shows "Add quotes in the
  app to see them here." even after adding quotes, the App Group capability is
  missing from the widget target or the group ID doesn't match between the two.
- **Home-screen name didn't update.** iOS caches the SpringBoard label. Always
  delete the app from the phone and reinstall after changing
  `CFBundleDisplayName`. If still stale, reboot the iPhone.
- **`AppIntent.swift`** in the widget folder is a leftover from the Xcode
  template. The current widget uses `StaticConfiguration`, not
  `AppIntentConfiguration`, so `ConfigurationAppIntent` is unreferenced. It
  compiles fine; deleting it is optional.

## Build / run

1. Open `quotesWidget.xcodeproj` in Xcode 26.
2. Select the `quotesWidget` scheme and an iPhone destination.
3. ⌘R. First install: trust the developer cert under Settings → General →
   VPN & Device Management.
4. Add quotes in the app. Long-press home screen → `+` → search "Random Quote"
   to add the widget.

To build only the extension for compile-checking:
`xcodebuild -project quotesWidget.xcodeproj -scheme QuotesWidgetExtension -destination 'generic/platform=iOS' build`

## Naming conventions worth knowing

- The on-disk folder, scheme, target, and `.xcodeproj` are all named
  `quotesWidget` (lowercase q) — historical, from `xcodebuild` template.
- The user-facing app name is `Quotes` (via `CFBundleDisplayName`).
- The widget extension's product is `QuotesWidgetExtensionExtension.appex`
  (Xcode adds the second "Extension" suffix automatically; bundle id is
  `Dream-AI.quotesWidget.QuotesWidgetExtension`).
- The widget displayed name in the gallery is "Random Quote", set via
  `.configurationDisplayName(...)` in `QuotesWidgetExtension.swift`.

Don't try to rename the on-disk project unless you're prepared to also re-add
App Group capabilities and re-sign — the cosmetic name is already handled by
the Display Name setting.
