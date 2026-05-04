# Mobile Build Pipeline

This project uses Capacitor so the app wrapper can be built headlessly in GitHub Actions while the JustBid mod logic stays in JavaScript at `src/js/justbid-inject.js`.

## Free Apple ID Build

The GitHub workflow intentionally does not sign iOS builds. It produces:

- `JustBidBot-unsigned.ipa`
- `JustBidBot.app.zip`

Use Sideloadly, AltStore, or AltServer-Linux to sign the unsigned IPA locally with a free Apple ID.

Free Apple ID limits usually apply:

- App refresh is needed about every 7 days
- 3 active sideloaded apps
- Signing happens locally, not in GitHub Actions

## Android Secrets

Optional Android release signing secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

## Downloading Builds

Every push runs `.github/workflows/build.yml`. When it finishes, open the workflow run in GitHub Actions and download the `mobile-builds` artifact. It contains the unsigned iOS files and whichever `.apk` Gradle produced.

## Sideloading

iOS needs local signing before install. From Ubuntu, use AltServer-Linux if you want the server to refresh the app over Wi-Fi. A Windows or macOS machine running Sideloadly is the easiest first install path.

Android can install directly:

```bash
/home/lilzac/Android/Sdk/platform-tools/adb install path/to/app.apk
```
