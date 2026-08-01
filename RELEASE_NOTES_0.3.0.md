# Floating Browser 0.3.0 - Unsigned Public Beta

Floating Browser is a small macOS browser window for keeping websites and web video visible above other apps. This is an unsigned, unnotarized public beta for macOS 14 or later.

## Highlights

- Modern adaptive browser chrome with Liquid Glass on supported macOS versions.
- Responsive Home launcher with clearer saved-site names and identities.
- Visible status feedback for navigation, downloads, blocking, and recovery.
- Saved-site editing, reordering, and removal.
- Compact 16:9 Mini mode that stays above other apps.
- Home launcher with Netflix, YouTube, Hulu, Disney+, Max, Prime Video on Amazon, Apple TV+, Peacock, Paramount+, Tubi, and custom shortcuts.
- Back, forward, reload, address search, and Safari fallback.
- Lightweight local ad and popup blocking.
- Native download destination picker.
- Guarded recovery if a WebKit page process stops responding.
- Universal build for Apple silicon and Intel Macs.

## Install

Download `Floating-Browser-0.3.0-unsigned-beta-macOS.dmg`, open it, and drag Floating Browser to Applications.

Because this beta is not signed or notarized, macOS blocks the first launch. Try to open it once, then use **System Settings > Privacy & Security > Open Anyway**. Do not disable Gatekeeper or use Terminal bypass commands.

## Known Limitations

- Streaming services can change their players or embedded-browser policies without notice.
- Disney+ may reject protected playback with Error 83.
- Prime Video compatibility depends on its current web-player behavior.
- The built-in blocker is intentionally lighter than a full browser extension and pauses on major streaming sites.

Use **More > Open in Safari** when a service refuses playback.

## Integrity

The GitHub Release includes a `.sha256` file for the DMG. Source code is available under the MIT License.
