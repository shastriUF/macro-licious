# Xcode + Apple Developer Setup Guide

This guide documents how to set up MacroLicious on a new dev machine and verify the Apple signing/TestFlight path.

## Project identifiers
- App name: `MacroLicious`
- Bundle ID: `com.aniruddha.macrolicious`
- Team: your paid Apple Developer team

## 1) Machine prerequisites
- Install latest stable Xcode from the App Store.
- Open Xcode once and install required components when prompted.
- Install command line tools if needed:
  - `xcode-select --install`
- Sign into macOS/iCloud with your Apple ID (recommended for smoother keychain behavior).

## 2) Add Apple account in Xcode
1. Open Xcode.
2. Go to `Xcode` -> `Settings` -> `Accounts`.
3. Add your Apple ID.
4. Verify your paid developer team appears (not only a Personal Team).

## 3) Create/open iOS project
If creating from scratch:
1. `File` -> `New` -> `Project...` -> `iOS App`.
2. Set:
   - Product Name: `MacroLicious`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Bundle Identifier: `com.aniruddha.macrolicious`
3. Save project under `ios/`.

If opening existing project:
- Open `.xcodeproj` or `.xcworkspace` and continue to signing checks.

## 4) Signing configuration
1. Select app target -> `Signing & Capabilities`.
2. Enable `Automatically manage signing`.
3. Select your Apple Developer Team.
4. Confirm Bundle Identifier is exactly `com.aniruddha.macrolicious`.
5. Resolve any signing warnings before proceeding.

## 5) Verify local build
- Select an iOS Simulator target.
- Run (`Cmd + R`) to ensure app launches.
- Optional: test on a physical iPhone connected to your Mac.

## 6) App Store Connect setup
If app record does not exist yet:
1. Go to App Store Connect -> `My Apps` -> `+` -> `New App`.
2. Platform: `iOS`
3. Name: `MacroLicious`
4. Bundle ID: `com.aniruddha.macrolicious`
5. SKU: choose a stable internal identifier (e.g., `macrolicious-ios`).

## 7) TestFlight upload verification
1. In Xcode, select a generic iOS device target.
2. `Product` -> `Archive`.
3. In Organizer, choose `Distribute App` -> `App Store Connect` -> `Upload`.
4. Wait for processing in App Store Connect -> `TestFlight`.
5. Add internal testers and install the build.

A successful upload confirms:
- Apple Developer account permissions are correct.
- Bundle ID/signing/provisioning are correctly configured.
- App record linkage is valid.

## 8) Backend connectivity smoke test
Run backend locally:
1. `cd backend`
2. `cp .env.example .env`
3. `npm run dev`

For iOS simulator, use backend base URL:
- `http://127.0.0.1:4000`

For physical device, use your Mac LAN IP (same Wi-Fi network).

## 9) Common issues and fixes
- **No Team appears in Xcode**
  - Re-login Apple ID in Xcode Accounts.
  - Confirm membership is active in Apple Developer portal.
- **Bundle ID already in use**
  - Confirm it belongs to your team; otherwise choose another ID.
- **Provisioning profile errors**
  - Toggle automatic signing off/on.
  - Clean build folder and retry.
- **Upload fails in Organizer**
  - Check App Store Connect app record exists and matches bundle ID exactly.
  - Ensure required agreements are accepted in App Store Connect.

## 10) New machine handoff checklist
- [ ] Xcode installed and launched once
- [ ] Apple ID added in Xcode Accounts
- [ ] Paid team visible in Xcode
- [ ] Project opens under `ios/`
- [ ] Signing set to team + bundle ID
- [ ] Simulator build runs
- [ ] Archive uploads to TestFlight
