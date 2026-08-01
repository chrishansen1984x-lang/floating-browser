# Floating Browser 0.3.1 - YouTube TV Compatibility Fix

This unsigned public beta pauses Floating Browser's built-in content blocker on `tv.youtube.com`. The change fixes reported YouTube TV playback where audio worked but video remained black.

## What Changed

- YouTube TV now receives unmodified media requests when the user has enabled Floating Browser's built-in blocker.
- Standard YouTube pages retain their existing blocking behavior.
- The fix was confirmed by the user who originally reported the problem.

## Install

Download `Floating-Browser-0.3.1-unsigned-beta-macOS.dmg`, open it, and drag Floating Browser to Applications.

Because this beta is not signed or notarized, macOS blocks the first launch. Try to open it once, then use **System Settings > Privacy & Security > Open Anyway**. Do not disable Gatekeeper or use Terminal bypass commands.
