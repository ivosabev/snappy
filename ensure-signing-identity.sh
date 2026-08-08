#!/bin/bash
# Creates a local code-signing identity once so Accessibility trust survives rebuilds.
set -euo pipefail

CERT_NAME="Snappy Code Signing"
KEYCHAIN="${HOME}/Library/Keychains/login.keychain-db"

if security find-identity -v -p codesigning 2>/dev/null | grep -qF "$CERT_NAME"; then
  echo "Using existing signing identity: $CERT_NAME" >&2
  printf '%s\n' "$CERT_NAME"
  exit 0
fi

echo "Creating local code-signing certificate: $CERT_NAME" >&2
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

openssl genrsa -out "$TMP/key.pem" 2048 2>/dev/null

cat > "$TMP/ext.cnf" <<'EOF'
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = Snappy Code Signing
O = Snappy
C = US

[v3_req]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF

openssl req -new -x509 -key "$TMP/key.pem" -out "$TMP/cert.pem" -days 3650 \
  -config "$TMP/ext.cnf" -extensions v3_req 2>/dev/null

# macOS `security import` needs legacy PKCS#12 (OpenSSL 3 defaults break it).
openssl pkcs12 -export \
  -out "$TMP/cert.p12" \
  -inkey "$TMP/key.pem" \
  -in "$TMP/cert.pem" \
  -name "$CERT_NAME" \
  -passout pass:snappy \
  -legacy \
  -certpbe PBE-SHA1-3DES \
  -keypbe PBE-SHA1-3DES \
  -macalg SHA1 \
  2>/dev/null

security import "$TMP/cert.p12" \
  -k "$KEYCHAIN" \
  -P snappy \
  -A \
  -T /usr/bin/codesign \
  -T /usr/bin/security \
  >/dev/null

security set-key-partition-list \
  -S apple-tool:,apple:,codesign: \
  -s \
  -D "$CERT_NAME" \
  -t private \
  "$KEYCHAIN" >/dev/null 2>&1 || true

# Convert to DER and trust for code signing in the user domain (admin -d often fails silently).
openssl x509 -in "$TMP/cert.pem" -outform DER -out "$TMP/cert.cer"
if ! security add-trusted-cert -r trustRoot -p codeSign "$TMP/cert.cer" 2>/dev/null; then
  echo "NOTE: Trust '$CERT_NAME' for Code Signing in Keychain Access:" >&2
  echo "  Get Info → Trust → Code Signing → Always Trust" >&2
fi

if security find-identity -v -p codesigning 2>/dev/null | grep -qF "$CERT_NAME"; then
  echo "Signing identity ready: $CERT_NAME" >&2
else
  echo "WARNING: '$CERT_NAME' may need manual trust:" >&2
  echo "  Keychain Access → login → Certificates → $CERT_NAME" >&2
  echo "  Get Info → Trust → Code Signing → Always Trust" >&2
fi

printf '%s\n' "$CERT_NAME"
