# quotesWidget — finishing setup in Xcode

The app side is **done** — `Quote.swift`, `QuoteStore.swift`, `quotesWidgetApp.swift`,
and `ContentView.swift` are wired up. Xcode 26's synchronized file groups will pick
them up automatically when you open the project.

You still need to do three things in Xcode that cannot be done from outside the IDE:

## 1. Add a Widget Extension target

1. Open `quotesWidget.xcodeproj`.
2. `File → New → Target…` → iOS → **Widget Extension**.
3. Product Name: `QuotesWidgetExtension`.
4. **Uncheck** "Include Configuration Intent" (we use a `StaticConfiguration`).
5. When Xcode asks to activate the new scheme, click **Activate**.
6. In the new `QuotesWidgetExtension` folder Xcode just created, **delete** the
   auto-generated `QuotesWidgetExtension.swift` file (move to trash).
7. Drag `QuotesWidgetExtension/QuotesWidgetExtension.swift` (already on disk at the
   project root) into the new extension group. When prompted, check the box for
   the **QuotesWidgetExtension** target only.

## 2. Share the model + store with the widget

Select `Quote.swift` and `QuoteStore.swift` in the Project navigator. In the
**File Inspector** on the right, under "Target Membership", check
**QuotesWidgetExtension** in addition to **quotesWidget**.

## 3. Turn on App Groups on both targets

The widget runs in a different process, so it needs an App Group to read what
the app saves.

For **each** of the two targets (`quotesWidget` and `QuotesWidgetExtension`):

1. Select the target → **Signing & Capabilities**.
2. Click `+ Capability` → **App Groups**.
3. Click `+` under App Groups and add: `group.Dream-AI.quotesWidget`
4. Make sure the checkbox next to that group is on for both targets.

The ID `group.Dream-AI.quotesWidget` is already hard-coded in
`QuoteStore.swift` (see `QuoteStoreConfig.appGroupID`). If you'd rather use a
different ID, change it there too.

## 4. Run on your iPhone

1. Plug in your iPhone, select it as the run destination.
2. Hit ⌘R.
3. Open the app, add a quote or two.
4. Long-press your home screen → `+` → search **Random Quote** → add the widget.

## Common issues

- **Widget shows "Add quotes in the app to see them here." even after adding some.**
  The App Group ID does not match between the two targets, or `QuoteStore.swift`
  isn't in the widget target. Re-check steps 2 and 3.
- **Build error: "Cannot find type 'Quote'".**
  `Quote.swift` is missing from the widget target's Target Membership.
- **Widget never updates.**
  iOS rate-limits widget refreshes. Edit a quote in the app — `WidgetCenter`
  fires a reload. Otherwise, expect ~30 min cadence.
- **"Failed to register bundle identifier".**
  Bundle IDs (`Dream-AI.quotesWidget` and
  `Dream-AI.quotesWidget.QuotesWidgetExtension`) collide with another developer
  on the same Apple ID. Change them both to something unique and re-add the App
  Group capability.
