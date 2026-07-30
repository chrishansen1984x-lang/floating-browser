# Floating Browser Release Checklist

The current build is suitable for local testing and direct-download preparation. It is not yet an App Store package.

## Required Decisions

- Keep the public bundle identifier fixed at `com.chrishansen.FloatingBrowser`.
- Add the final GitHub repository URL to public launch materials.
- Decide whether GitHub Issues is sufficient for support or publish a support email.
- Confirm the publisher has permission to market compatibility with named third-party services. Add a clear non-affiliation statement.

## Signing And Distribution

- For the current unsigned beta, run `package-unsigned-beta.sh`.
- Confirm the DMG contains the app, Applications shortcut, and unsigned-beta installation guide.
- Confirm a clean Mac blocks the first launch and that Apple's **Open Anyway** workflow succeeds.
- Label the GitHub Release and download clearly as **unsigned** and **unnotarized**.
- Keep the generated SHA-256 checksum next to the download.
- Upload the generated `.dmg` and `.sha256` files to a tagged GitHub Release.
- Do not distribute GitHub's automatically generated source archives as the app download.
- Enable GitHub private vulnerability reporting or publish a private security contact.

For a future signed release:

- Install a valid **Developer ID Application** certificate.
- Create a `notarytool` keychain profile.
- Run `package-release.sh` with `SIGNING_IDENTITY` and `NOTARY_PROFILE`.
- Confirm Gatekeeper accepts the stapled app on a different Mac.

## Compatibility

- Test on Apple silicon and Intel hardware.
- Test every supported macOS major version, beginning with macOS 14.
- Verify sign-in, playback, mini mode, next-episode behavior, external authentication, and downloads on each listed service.
- Document services that reject WebKit playback, including known Disney+ Error 83 behavior.
- Verify the Safari fallback for unsupported playback.
- Test the release with a fresh macOS user account so existing cookies and preferences cannot hide first-run bugs.

## Store Submission

Mac App Store distribution needs a separate sandboxed target, App Store signing, and a review of third-party service and trademark requirements. The direct-download scripts do not produce that package.
