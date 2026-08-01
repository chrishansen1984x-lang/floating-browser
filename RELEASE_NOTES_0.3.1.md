# Floating Browser 0.3.1 - YouTube TV Compatibility Test

This unsigned prerelease pauses Floating Browser's built-in content blocker on `tv.youtube.com`. It addresses a report where YouTube TV played audio but displayed no video.

## Testing Requested

Please test live and recorded YouTube TV playback. If audio plays without video, include the following in your report:

- Whether the same channel plays in Safari.
- Whether the Mac is connected to an external display, dock, or DisplayLink adapter.
- Whether the problem affects live TV, recordings, or both.
- Your macOS version and Mac model.

Protected streaming video may still be rejected by YouTube TV or WebKit even when the blocker is disabled. Use **More > Open in Safari** if playback remains unavailable.

## Install

Download `Floating-Browser-0.3.1-unsigned-beta-macOS.dmg`, open it, and drag Floating Browser to Applications.

Because this beta is not signed or notarized, macOS blocks the first launch. Try to open it once, then use **System Settings > Privacy & Security > Open Anyway**. Do not disable Gatekeeper or use Terminal bypass commands.
