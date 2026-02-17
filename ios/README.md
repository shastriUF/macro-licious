# iOS App Setup (Milestone 1)

Create the iOS project in Xcode (manual setup keeps signing and App Store settings clean).

Detailed setup + new machine onboarding guide:
- `ios/XCODE_SETUP.md`

## Project settings
- Product Name: `MacroLicious`
- Interface: `SwiftUI`
- Language: `Swift`
- Bundle Identifier: `com.aniruddha.macrolicious`
- Team: your Apple Developer team
- Use automatic signing: enabled

## Folder expectation
After creating in Xcode, keep iOS app sources under this `ios/` directory.

Suggested structure:
- `ios/MacroLicious/` (Xcode project + app target)

## Milestone 1 target
- App launches successfully on simulator/device
- Internal TestFlight archive path is functional
- Basic auth entry screen scaffold is ready for Phase B

## Auth callback behavior (current)
- URL scheme `macrolicious://auth/callback` is registered for app callback handling.
- In `AUTH_PROVIDER=dev`, request endpoint returns a token and manual verify remains enabled in-app.
- In `AUTH_PROVIDER=supabase`, request endpoint expects email-link sign-in; app waits for callback URL and then verifies automatically.
