# Publishing Floating Browser On GitHub

The source repository and unsigned beta assets are prepared separately:

- Commit the project source to the repository.
- Attach the files in `Dist/` to a GitHub Release. `Dist/` is intentionally ignored by Git.

## 1. Create And Push The Repository

The local FloatingBrowser project is already initialized on the `main` branch with a privacy-preserving GitHub no-reply commit address. From the project directory, create and push the public repository:

```sh
gh repo create floating-browser --public --source=. --remote=origin --push
```

Review the repository on GitHub before announcing it. Confirm that no account credentials, cookies, private URLs, signing certificates, or build output were committed.

## 2. Create The Release

Build fresh assets:

```sh
./package-unsigned-beta.sh
```

Create a prerelease and upload the DMG and checksum:

```sh
gh release create v0.3.0 \
  Dist/Floating-Browser-0.3.0-unsigned-beta-macOS.dmg \
  Dist/Floating-Browser-0.3.0-unsigned-beta-macOS.dmg.sha256 \
  --title "Floating Browser 0.3.0 - Unsigned Public Beta" \
  --notes-file RELEASE_NOTES_0.3.0.md \
  --prerelease
```

GitHub also adds automatic source ZIP and tar archives. Those are for developers; the DMG is the app download.

## 3. Repository Settings

1. Enable **Issues**.
2. Enable **Settings > Security > Private vulnerability reporting**.
3. Add the repository description: `A compact always-on-top macOS browser for websites and web video.`
4. Add topics such as `macos`, `swift`, `webkit`, `picture-in-picture`, and `open-source`.
5. Confirm the Release prominently says **unsigned** and **unnotarized**.

## 4. Final Download Test

Download the DMG from the public Release instead of testing the local copy. On a clean Mac or fresh user account:

1. Verify the checksum.
2. Drag the app to Applications.
3. Confirm the first launch is blocked.
4. Confirm **System Settings > Privacy & Security > Open Anyway** works.
5. Test Home, a public video, Mini/Full, and Safari fallback.
