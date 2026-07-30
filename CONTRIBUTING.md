# Contributing

Thanks for helping improve Floating Browser.

## Before Opening An Issue

- Search existing issues for the same problem.
- Confirm the problem still happens after reloading the page.
- Include the macOS version, Mac model or architecture, app version, website, and reproducible steps.
- Describe what happened and what you expected.
- Never post account credentials, cookies, private URLs, payment details, or personal browsing information.

Streaming services can change their players and DRM policies without notice. A site-specific playback failure is useful to report, but it may not be fixable through public WebKit APIs.

## Development

Build and install locally:

```sh
./build-local.sh
```

Run the test suite:

```sh
swift test
```

Keep changes focused, use public macOS and WebKit APIs, and add tests for URL or policy behavior. Do not commit signing certificates, notarization credentials, cookies, website data, build output, or release artifacts.

## Pull Requests

- Explain the user-facing problem and the proposed behavior.
- List the verification performed.
- Avoid unrelated refactors.
- Confirm `swift test`, `bash -n build-local.sh package-release.sh`, and `git diff --check` pass.
