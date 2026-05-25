#!/usr/bin/env bash
# Verify a release tarball contains the expected binaries for its platform.
#
# Usage: util/verify-release-artifact.sh OS_ARCH [path/to/bin]

set -euo pipefail

OS_ARCH="${1:?OS_ARCH required (linux-arm64 or darwin-arm64)}"
BIN_DIR="${2:-bin}"

case "$OS_ARCH" in
   linux-arm64)
      GO_PATTERN='ELF.*ARM aarch64'
      ;;
   darwin-arm64)
      GO_PATTERN='Mach-O.*arm64'
      ;;
   *)
      echo "Unsupported OS_ARCH: $OS_ARCH" >&2
      exit 1
      ;;
esac

GO_TOOLS=(
   pt-galera-log-explainer
   pt-k8s-debug-collector
   pt-mongodb-index-check
   pt-mongodb-query-digest
   pt-mongodb-summary
   pt-pg-summary
   pt-secure-collect
)

PERL_TOOLS=(
   pt-query-digest
   pt-online-schema-change
)

echo "Checking Go binaries in ${BIN_DIR} for ${OS_ARCH}..."
for tool in "${GO_TOOLS[@]}"; do
   path="${BIN_DIR}/${tool}"
   if [[ ! -f "$path" ]]; then
      echo "Missing Go tool: $tool" >&2
      exit 1
   fi
   if ! file "$path" | grep -Eq "$GO_PATTERN"; then
      echo "Wrong architecture for $tool:" >&2
      file "$path" >&2
      exit 1
   fi
   echo "  OK $tool"
done

echo "Checking Perl tools..."
for tool in "${PERL_TOOLS[@]}"; do
   path="${BIN_DIR}/${tool}"
   if [[ ! -f "$path" ]]; then
      echo "Missing Perl tool: $tool" >&2
      exit 1
   fi
   if ! head -n1 "$path" | grep -q perl; then
      echo "Not a Perl script: $tool" >&2
      exit 1
   fi
   echo "  OK $tool"
done

echo "Verification passed for ${OS_ARCH}"
