# Build unsigned IPA without a Mac

This folder cannot build a real iOS IPA directly on Windows because Apple only ships the iOS compiler, SDK, and `xcodebuild` with Xcode on macOS.

The included GitHub Actions workflow builds an unsigned IPA on a GitHub-hosted macOS runner. You can then sign and install that IPA from Windows with Sideloadly and a free Apple ID.

## Steps

1. Create a GitHub repository.
2. Upload this whole folder, including:
   - `NammaTorrent/`
   - `project.yml`
   - `.github/workflows/build-unsigned-ipa.yml`
3. Open the repository on GitHub.
4. Go to Actions -> Build unsigned IPA -> Run workflow.
5. When the workflow finishes, download the `NammaTorrent-unsigned-ipa` artifact.
6. Open Sideloadly on Windows.
7. Drag `NammaTorrent-unsigned.ipa` into Sideloadly and sign it with your Apple ID.

## Included targets

- Main iPhone app: `NammaTorrent`
- Widget extension: `NammaTorrentWidget`
- Live Activity / Dynamic Island UI: included in the widget extension
- Share extension: `NammaTorrentShare`

## Notes

- A free Apple ID can usually sideload the main app for 7 days.
- Capabilities like App Groups, Push Notifications, Network Extension, Widgets, and Live Activities may require extra Apple signing support and can fail with free sideloading.
