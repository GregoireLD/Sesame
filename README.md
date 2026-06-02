# Sesame

**Your building access codes, always at hand.**

Sesame stores your building access codes and delivers them automatically when you arrive — no more searching through your phone at the door.

For the Android port, see : [Sesame Lite (Android)](https://github.com/GregoireLD/Sesame_Lite)

## Features

- **Automatic geofencing** — notified when you approach a saved location
- **AES-256 encryption** — all sensitive fields encrypted on-device before syncing
- **Private iCloud sync** — your data stays in your private iCloud account
- **Share via QR, link, or AirDrop** — securely share entries with others
- **Import from QR, link, or clipboard** — scan or paste to add entries instantly
- **Open in Maps** — swipe any entry to view its location in Apple Maps
- **Configurable notification radius** — 50 m to 500 m per entry
- **Location details and comments** — attach extra notes to each entry
- **Per-entry disabling** — silence codes and disable tracking with a simple swipe
- **Sort by name or distance** — switch instantly in the toolbar
- **Key recovery** — guided flow if iCloud Keychain becomes temporarily unavailable
- **10 languages** — English, Arabic, French, German, Italian, Japanese, Korean, Spanish, Simplified Chinese, and Traditional Chinese

## Philosophy

Sesame is paid software. Our business model is simple: you pay once, we build a good app. Your data is never our product.

The source code is open so our privacy claims are verifiable, not just promises.

## Privacy

All sensitive fields (access codes, addresses, coordinates, location details, notes) are encrypted on your device using AES-256-GCM via Apple's CryptoKit before syncing to iCloud. The encryption key is stored in your iCloud Keychain and never leaves your devices.

Location data is used solely for geofencing and is never logged, stored, or transmitted. Silenced entries are excluded from location monitoring entirely.

When sharing an entry as a link, all data is encoded in the URL fragment. Fragments are never sent to the server, so your access code and address stay off the network even if the recipient opens the link in a browser without Sesame installed.

[Read the full privacy policy](https://sesame-app.com/privacy.php)

## Requirements

- iOS 26.0+
- macOS 26.0+ (via iPad compatibility)
- Xcode 26+
- Active Apple Developer account for building

## Building

1. Clone the repository
2. Open `Sesame.xcodeproj` in Xcode 26+
3. Set your Development Team in **Signing & Capabilities**
4. Build and run on a device or simulator

## Support

- **Website**: [sesame-app.com](https://sesame-app.com)
- **Email**: support@sesame-app.com
- **Ko-fi**: [ko-fi.com/duvalparis](https://ko-fi.com/duvalparis)

## License

Sesame is open source. The source code is available for inspection and learning.

© 2026 Grégoire Duval. All rights reserved.
