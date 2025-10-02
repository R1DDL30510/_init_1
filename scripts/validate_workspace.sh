#!/usr/bin/env bash
# Validates that the repository folder name is compatible with Docker volume naming rules.
# If the current folder is not compliant (e.g. starts with an underscore), the script
# attempts to create a sibling symlink that uses a sanitized, Docker-friendly name so
# developers have a predictable path to open in tooling such as VS Code Dev Containers.

set -euo pipefail

STRICT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --require-compliant)
      STRICT=1
      shift
      ;;
    --help|-h)
      cat <<USAGE
Usage: $(basename "$0") [--require-compliant]

Validates that the repository resides in a Docker-compliant folder name.
When --require-compliant is supplied, the script exits non-zero if the
active workspace alias violates Docker's volume naming rules.
USAGE
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PHYSICAL_BASENAME="$(basename "${ROOT}")"
PARENT_DIR="$(dirname "${ROOT}")"
PATTERN='^[A-Za-z0-9][A-Za-z0-9_.-]*$'

CHECK_PATH="${LOCAL_WORKSPACE_FOLDER:-${PWD:-${ROOT}}}"
CHECK_BASENAME="$(basename "${CHECK_PATH}")"

if [[ "${PHYSICAL_BASENAME}" =~ ${PATTERN} ]]; then
  # Physical folder already satisfies Docker's constraints; nothing to do.
  exit 0
fi

printf 'Workspace name "%s" violates Docker volume naming rules.\n' "${PHYSICAL_BASENAME}"
printf 'Docker requires names to match %s.\n' "[A-Za-z0-9][A-Za-z0-9_.-]*"

# Derive a sanitized alternative that developers can adopt when opening the project.
SANITIZED="${PHYSICAL_BASENAME//[^A-Za-z0-9_.-]/-}"
SANITIZED="${SANITIZED#[-._]}"
if [[ -z "${SANITIZED}" ]]; then
  SANITIZED="shs-stack"
fi

SYMLINK_PATH="${PARENT_DIR}/${SANITIZED}"
if [[ -e "${SYMLINK_PATH}" && ! -L "${SYMLINK_PATH}" ]]; then
  printf 'A filesystem entry already exists at %s. Please remove or rename it manually.\n' "${SYMLINK_PATH}"
  printf 'Recommended action: open the repository via a folder whose name matches Docker rules.\n'
  exit 1
fi

# Create or update the symlink so tools can rely on a compliant path.
ln -sfn "${ROOT}" "${SYMLINK_PATH}"
printf 'Created/updated helper symlink: %s -> %s\n' "${SYMLINK_PATH}" "${ROOT}"
printf 'Open that sanitized path in Dev Containers or other tooling to avoid volume errors.\n'

if [[ ${STRICT} -eq 1 && ! "${CHECK_BASENAME}" =~ ${PATTERN} ]]; then
  printf 'Strict mode: refusing to continue while workspace "%s" is non-compliant.\n' "${CHECK_BASENAME}"
  printf 'Reopen the repository via %s and retry.\n' "${SYMLINK_PATH}"
  exit 1
fi

exit 0
