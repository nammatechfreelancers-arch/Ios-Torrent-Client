# SideloadyGuide.md — Installing NammaTorrent via Sideloadly

## What You Need

- Windows PC or Mac
- [Sideloadly](https://sideloadly.io) installed
- iTunes installed (Windows) — required by Sideloadly
- Apple ID (free tier works — 7-day certificate)
- iPhone with iOS 18+ and Developer Mode enabled
- USB cable or Wi-Fi (same network)

---

## Step 1 — Enable Developer Mode on iPhone

1. Settings → Privacy & Security → Developer Mode → ON
2. Restart when prompted
3. Confirm "Turn On" after restart

---

## Step 2 — Build the .ipa in Xcode

1. Open `NammaTorrent.xcodeproj` in Xcode 16+
2. Select scheme: **NammaTorrent**
3. Select destination: **Any iOS Device (arm64)**
4. Product → **Archive**
5. In the Organizer window → **Distribute App**
6. Select: **Custom** → **Direct Distribution**
7. Sign with your Apple ID developer certificate
8. Export → save the `.ipa` file to your Desktop

---

## Step 3 — Install with Sideloadly

1. Open Sideloadly
2. Connect your iPhone via USB (trust the computer if prompted)
3. Drag the `.ipa` file into Sideloadly
4. Enter your Apple ID email
5. Click **Start**
6. Enter your Apple ID password when prompted
   - Sideloadly uses it locally to sign — it does NOT store it
7. Wait for "Done" message

---

## Step 4 — Trust the Certificate on iPhone

1. Settings → General → VPN & Device Management
2. Tap your Apple ID under "Developer App"
3. Tap **Trust "your@email.com"**
4. Confirm Trust

---

## Step 5 — Launch NammaTorrent

Tap the NammaTorrent icon on your home screen.

---

## Re-signing (Every 7 Days — Free Apple ID)

Free Apple ID certificates expire every 7 days.

**Auto-resign with Sideloadly:**
1. Open Sideloadly
2. Enable **Automatic re-sign** in settings
3. Keep Sideloadly running in background — it will re-sign automatically

**Manual re-sign:**
- Repeat Step 3 with the same `.ipa` — your data is preserved

---

## Paid Apple Developer Account ($99/year)

- Certificate valid for 1 year
- No 7-day re-signing needed
- Same Sideloadly process

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Unable to install" | Ensure Developer Mode is ON |
| "App is damaged" | Re-trust certificate in Settings |
| Sideloadly can't find device | Install/update iTunes, try different USB port |
| "Maximum number of apps" | Free tier limited to 3 apps — remove one |
| App crashes on launch | Check Xcode console via Instruments or Console.app |
| Wi-Fi install fails | Use USB cable instead |

---

## Notes

- NammaTorrent is for **personal use only**
- Do not distribute the `.ipa` to others
- Downloads are saved to the app's Documents/Downloads folder
- Access files via: Files app → On My iPhone → NammaTorrent → Downloads
