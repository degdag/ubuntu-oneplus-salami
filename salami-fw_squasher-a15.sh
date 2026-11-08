
#!/bin/sh
set -eu

ROOT="${1:?Usage: $0 repository_directory}"
FW="$ROOT/firmware-oneplus-salami-a15/usr/lib/firmware/qcom/sm8550/salami"
BUILD_DIR="$(mktemp -d)"

trap 'rm -rf "$BUILD_DIR"' EXIT

# Build pil-squasher
git clone --depth 1 https://github.com/linux-msm/pil-squasher "$BUILD_DIR/pil-squasher"

make -C "$BUILD_DIR/pil-squasher" install

# Reconstruct modem.mbn from modem.mdt + modem.bXX
/usr/local/bin/pil-squasher \
    "$FW/modem.mbn" \
    "$FW/modem.mdt"

# Verify reconstructed firmware
test -s "$FW/modem.mbn"

# Remove split firmware files from the final package
rm -f "$FW/modem.mdt" "$FW"/modem.b*

# Fix Debian control file line endings and EOF
CONTROL="$ROOT/firmware-oneplus-salami-a15/DEBIAN/control"
sed -i 's/\r$//' "$CONTROL"
if [ "$(tail -c 1 "$CONTROL" | wc -l)" -eq 0 ]; then
    printf '\n' >> "$CONTROL"
fi

# Build firmware package
cd "$ROOT"
dpkg-deb --build --root-owner-group firmware-oneplus-salami-a15
