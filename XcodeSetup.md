# XcodeSetup.md — Xcode Project Configuration Guide

## 1. Create the Xcode Project

1. Open Xcode 16+
2. File → New → Project → iOS → App
3. Settings:
   - Product Name: `NammaTorrent`
   - Bundle ID: `com.nammatorrrent`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployment: iOS 18.0
4. Save to `E:\iOS Torrent Client\`

---

## 2. Add All Source Files

Drag the entire `NammaTorrent/` folder into the Xcode project navigator.
- Check "Copy items if needed" → NO (files are already in place)
- Add to target: NammaTorrent ✓

---

## 3. Project Settings

### General tab
- Display Name: NammaTorrent
- Bundle Identifier: com.nammatorrrent
- Version: 1.0 / Build: 1
- Deployment Target: iOS 18.0
- Device: iPhone

### Signing & Capabilities tab
- Team: Your personal Apple ID (free tier works for Sideloadly)
- Signing Certificate: iPhone Developer
- Add capabilities:
  - **App Groups** → `group.com.nammatorrrent`
  - **Push Notifications**
  - **Background Modes** → check: Background fetch, Background processing
  - **Live Activities** (add via + Capability)

### Build Settings
- Swift Language Version: Swift 6
- SWIFT_STRICT_CONCURRENCY = complete
- Enable Testability: Yes (Debug)

---

## 4. Add Widget Extension Target

1. File → New → Target → Widget Extension
   - Name: `NammaTorrentWidget`
   - Bundle ID: `com.nammatorrrent.widget`
   - Include Live Activity: YES
2. Add source files from `Widgets/` and `LiveActivities/` to this target
3. Also add to widget target:
   - `Models/` (all model files)
   - `Components/ProgressRing.swift`
   - `Components/SpeedBadge.swift`
   - `Utilities/Formatters.swift`
   - `Extensions/Color+Theme.swift`
4. Set App Group on widget target: `group.com.nammatorrrent`

---

## 5. Add Share Extension Target

1. File → New → Target → Share Extension
   - Name: `NammaTorrentShare`
   - Bundle ID: `com.nammatorrrent.share`
2. Replace generated `ShareViewController.swift` with `ShareExtension/ShareViewController.swift`
3. Set App Group: `group.com.nammatorrrent`
4. Edit `Info.plist` of share extension:
   ```xml
   <key>NSExtension</key>
   <dict>
       <key>NSExtensionAttributes</key>
       <dict>
           <key>NSExtensionActivationRule</key>
           <dict>
               <key>NSExtensionActivationSupportsFileWithMaxCount</key>
               <integer>1</integer>
               <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
               <integer>1</integer>
           </dict>
       </dict>
       <key>NSExtensionMainStoryboard</key>
       <string>MainInterface</string>
       <key>NSExtensionPointIdentifier</key>
       <string>com.apple.share-services</string>
   </dict>
   ```

---

## 6. Add Test Target

1. File → New → Target → Unit Testing Bundle
   - Name: `NammaTorrentTests`
2. Add test files from `Tests/` to this target
3. Set Host Application: NammaTorrent

---

## 7. Info.plist

- Use `Resources/Info.plist` — copy its contents into the Xcode-generated Info.plist
- Or set the project to use a custom Info.plist:
  Build Settings → Info.plist File → `NammaTorrent/Resources/Info.plist`

---

## 8. Entitlements

- Build Settings → Code Signing Entitlements → `NammaTorrent/Resources/NammaTorrent.entitlements`

---

## 9. Swift Package Dependencies

No external packages required — pure Swift implementation.

---

## 10. Build & Run

1. Select scheme: NammaTorrent
2. Select destination: Any iOS Device (arm64)
3. Product → Archive
4. Export as: Development (Ad Hoc or Development signing)
5. Export `.ipa` file → use Sideloadly to install

---

## Common Build Errors

| Error | Fix |
|-------|-----|
| `'NammaTorrent' is not a member type` | Ensure all files are added to the correct target |
| `Sendable` conformance warnings | Expected — Swift 6 strict concurrency mode |
| `ActivityKit` not found | Ensure deployment target is iOS 16.2+ for Live Activities |
| `AppIntents` not found | Ensure deployment target is iOS 16.0+ |
| Widget compile errors | Ensure widget target has access to shared model files |
