# QuoteMark

An iOS app and Home Screen widget that displays a random quote from your personal collection each day. Add, edit, and manage your favorite quotes with automatic daily rotation and optional notifications.

## Requirements

- iOS 16.0 or later
- iPhone (iPad support optional)
- Xcode 26 for building

### Adding the Widget

1. Open the QuoteMark app and add some quotes
2. Long-press your iPhone home screen
3. Tap the "+" button to add a widget
4. Search for "QuoteMark"
5. Select the widget and add it to your home screen

## Architecture

### Project Structure

```
QuoteMark/
├── QuoteMark.xcodeproj
├── quotesWidget/                       # App target
│   ├── quotesWidgetApp.swift           # App entry point + notification handling
│   ├── ContentView.swift               # Main UI (add, edit, delete quotes)
│   ├── Quote.swift                     # Quote model + deterministic selection
│   ├── QuoteStore.swift                # Data persistence via App Group
│   └── quotesWidget.entitlements       # App Group capability
├── QuotesWidgetExtension/              # Widget target
│   ├── QuotesWidgetExtensionBundle.swift   # Widget entry point
│   ├── QuotesWidgetExtension.swift     # Widget timeline + display logic
│   └── QuotesWidgetExtensionExtension.entitlements
└── README.md
```

### Data Sharing

- **App Group ID**: `group.com.douglasbrown.quotemark`
- **Storage**: JSON-encoded `[Quote]` array in `UserDefaults(suiteName:)`
- **Key**: `"quotes"`

The app writes quotes, and the widget reads them. Both share the same App Group so data stays in sync.

### Quote Selection

Quotes are selected deterministically using a hash of the date:
- Same date + same quote list → same quote
- Both widget (8 AM) and notification (9 AM) show the same quote each day
- No immediate repeats; cycle time is ~quote count days

### Timeline & Notifications

**Widget Timeline**
- Pre-rolls 60 days of daily quotes
- Each quote fires at 8:00 AM local time
- After 60 days, iOS requests a new timeline (automatic refresh)



