# Mobile Build Pipeline

This project uses Capacitor so the app wrapper can be built headlessly in GitHub Actions while the JustBid mod logic stays in JavaScript at `src/js/justbid-inject.js`.

## GitHub Secrets

Add these repository secrets before expecting the iOS build to export a usable `.ipa`:

- `APPLE_TEAM_ID`
- `IOS_BUILD_CERTIFICATE_BASE64`
- `IOS_P12_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `IOS_PROVISIONING_PROFILE_NAME`
- `IOS_KEYCHAIN_PASSWORD`
- `IOS_EXPORT_METHOD` optional, defaults to `ad-hoc`

Optional Android release signing secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

## Ubuntu Certificate Flow

Generate a CSR on Ubuntu with OpenSSL, upload it to the Apple Developer Portal, download the generated `.cer`, then convert it with your private key into a `.p12`.

This server already generated:

- `signing/ios_distribution.csr` to upload to Apple Developer
- `signing/ios_distribution.key` as the private key; keep it private

The connected iPhone UDID for the provisioning profile is:

```text
00008120-001651302282201E
```

After downloading Apple's `.cer` and `.mobileprovision` files into `signing/`, the helper can create the base64 files:

```bash
IOS_P12_PASSWORD='use-a-long-password' ./scripts/prepare-ios-secrets.sh
```

## Downloading Builds

Every push runs `.github/workflows/build.yml`. When it finishes, open the workflow run in GitHub Actions and download the `mobile-builds` artifact. It contains the exported `.ipa` and whichever `.apk` Gradle produced.

## Sideloading

Install the downloaded `.ipa` onto the plugged-in iPhone from Ubuntu:

```bash
.venv-ios-tools/bin/pymobiledevice3 apps install JustBidBot.ipa
```

Android can install directly:

```bash
/home/lilzac/Android/Sdk/platform-tools/adb install path/to/app.apk
```
