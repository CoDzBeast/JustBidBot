#!/usr/bin/env bash
set -euo pipefail

CERT_PATH="${1:-signing/ios_distribution.cer}"
KEY_PATH="${2:-signing/ios_distribution.key}"
PROFILE_PATH="${3:-signing/JustBidBot.mobileprovision}"
P12_PATH="${4:-signing/ios_distribution.p12}"

if [ ! -f "$CERT_PATH" ]; then
  echo "Missing Apple certificate: $CERT_PATH" >&2
  echo "Upload signing/ios_distribution.csr to Apple Developer, download the .cer, then run again." >&2
  exit 1
fi

if [ ! -f "$KEY_PATH" ]; then
  echo "Missing private key: $KEY_PATH" >&2
  exit 1
fi

if [ ! -f "$PROFILE_PATH" ]; then
  echo "Missing provisioning profile: $PROFILE_PATH" >&2
  exit 1
fi

if [ -z "${IOS_P12_PASSWORD:-}" ]; then
  echo "Set IOS_P12_PASSWORD before running, for example:" >&2
  echo "  IOS_P12_PASSWORD='use-a-long-password' $0" >&2
  exit 1
fi

mkdir -p signing/github-secrets
openssl x509 -in "$CERT_PATH" -inform DER -out signing/ios_distribution.pem -outform PEM
openssl pkcs12 -export \
  -inkey "$KEY_PATH" \
  -in signing/ios_distribution.pem \
  -out "$P12_PATH" \
  -password "pass:${IOS_P12_PASSWORD}"

base64 -w 0 "$P12_PATH" > signing/github-secrets/IOS_BUILD_CERTIFICATE_BASE64.txt
base64 -w 0 "$PROFILE_PATH" > signing/github-secrets/IOS_PROVISIONING_PROFILE_BASE64.txt

cat <<EOF
Created:
  signing/github-secrets/IOS_BUILD_CERTIFICATE_BASE64.txt
  signing/github-secrets/IOS_PROVISIONING_PROFILE_BASE64.txt

Add these GitHub repository secrets:
  IOS_BUILD_CERTIFICATE_BASE64 = contents of signing/github-secrets/IOS_BUILD_CERTIFICATE_BASE64.txt
  IOS_P12_PASSWORD = the IOS_P12_PASSWORD value you used
  IOS_PROVISIONING_PROFILE_BASE64 = contents of signing/github-secrets/IOS_PROVISIONING_PROFILE_BASE64.txt
  IOS_PROVISIONING_PROFILE_NAME = the profile name from Apple Developer
  IOS_KEYCHAIN_PASSWORD = any long random CI-only password
  APPLE_TEAM_ID = your Apple Developer Team ID
  IOS_EXPORT_METHOD = development or ad-hoc
EOF
