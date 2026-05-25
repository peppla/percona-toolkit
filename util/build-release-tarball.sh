#!/usr/bin/env bash
# Build an unofficial percona-toolkit release tarball for one platform.
#
# Usage: util/build-release-tarball.sh VERSION OS_ARCH
# Example: util/build-release-tarball.sh 3.7.1-peppla1 linux-arm64
#
# OS_ARCH must be one of: linux-arm64, darwin-arm64

set -euo pipefail

VERSION="${1:?VERSION required (e.g. 3.7.1-peppla1)}"
OS_ARCH="${2:?OS_ARCH required (linux-arm64 or darwin-arm64)}"

case "$OS_ARCH" in
   linux-arm64|darwin-arm64) ;;
   *)
      echo "Unsupported OS_ARCH: $OS_ARCH" >&2
      echo "Supported: linux-arm64, darwin-arm64" >&2
      exit 1
      ;;
esac

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

echo "Building Go tools for ${OS_ARCH} (version ${VERSION})..."
cd src/go
VERSION="$VERSION" make "$OS_ARCH"
cd "$ROOT"

PKG="percona-toolkit-${VERSION}-${OS_ARCH}"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

mkdir -p "$STAGING/$PKG/bin"

cp bin/* "$STAGING/$PKG/bin/"
cp INSTALL COPYING README.md "$STAGING/$PKG/"

cat >"$STAGING/$PKG/BUILD_INFO" <<EOF
version=${VERSION}
platform=${OS_ARCH}
commit=$(git rev-parse HEAD)
built_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
upstream=https://github.com/percona/percona-toolkit
fork=https://github.com/peppla/percona-toolkit
note=Unofficial build — not supported by Percona LLC
EOF

mkdir -p "$ROOT/release"
TARBALL="$ROOT/release/${PKG}.tar.gz"
tar -C "$STAGING" -czf "$TARBALL" "$PKG"

echo "Created $TARBALL"
