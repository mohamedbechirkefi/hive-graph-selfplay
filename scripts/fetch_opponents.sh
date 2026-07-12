#!/usr/bin/env bash
# Fetch reference engines for gauntlet testing: Mzinga (official UHP
# reference, self-contained macOS binary) and nokamute (fast Rust engine,
# built from source). Installs into ./opponents/.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p opponents
cd opponents

ARCH=$(uname -m) # arm64 on Apple Silicon
if [ "$ARCH" = "arm64" ]; then
    MZINGA_ASSET="Mzinga.MacOSArm64.tar.gz"
else
    MZINGA_ASSET="Mzinga.MacOSX64.tar.gz"
fi

if [ ! -x MzingaEngine ]; then
    echo "Fetching Mzinga ($MZINGA_ASSET)..."
    URL=$(curl -s https://api.github.com/repos/jonthysell/Mzinga/releases/latest \
        | grep browser_download_url | grep "$MZINGA_ASSET" | cut -d '"' -f 4)
    curl -sL "$URL" -o mzinga.tar.gz
    tar xzf mzinga.tar.gz
    rm mzinga.tar.gz
    # The tarball unpacks into a versioned directory; link the binaries here.
    DIR="${MZINGA_ASSET%.tar.gz}"
    for bin in MzingaEngine MzingaPerft MzingaTrainer; do
        chmod +x "$DIR/$bin"
        ln -sf "$DIR/$bin" "$bin"
    done
fi

if [ ! -x nokamute ]; then
    echo "Building nokamute from source..."
    rm -rf nokamute-src
    git clone --depth 1 https://github.com/edre/nokamute.git nokamute-src
    (cd nokamute-src && cargo build --release)
    cp nokamute-src/target/release/nokamute .
fi

echo "--- smoke test: Mzinga info ---"
echo "info" | ./MzingaEngine | head -3 || true
echo "--- smoke test: nokamute info ---"
echo "info" | ./nokamute uhp | head -3 || true
echo "done"
