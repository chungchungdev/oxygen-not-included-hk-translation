#!/usr/bin/env bash
# release.sh — Archive mod/ contents into release.zip (wrapped in oni-hk-translation/)

set -euo pipefail

# ─── Colors & helpers ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*"; }
step()    { echo -e "\n${BOLD}━━━ $* ━━━${RESET}"; }

# ─── Configuration ────────────────────────────────────────────────────────────
SOURCE_DIR="$(pwd)/mod"
OUTPUT_ZIP="$(pwd)/release.zip"
WRAP_DIR="oni-hk-translation"

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════╗"
echo "║         ONI HK Translation Release Script       ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ════════════════════════════════════════════════════════════
step "Validating source directory"
# ════════════════════════════════════════════════════════════

if [[ ! -d "${SOURCE_DIR}" ]]; then
    error "Source directory does not exist: ${SOURCE_DIR}"
    exit 1
fi

if [[ -z "$(ls -A "${SOURCE_DIR}" 2>/dev/null)" ]]; then
    error "Source directory is empty: ${SOURCE_DIR}"
    exit 1
fi

FILE_COUNT=$(find "${SOURCE_DIR}" -mindepth 1 | wc -l)
info "Found ${FILE_COUNT} item(s) in: ${SOURCE_DIR}"

# ════════════════════════════════════════════════════════════
step "Creating release.zip"
# ════════════════════════════════════════════════════════════

if [[ -f "${OUTPUT_ZIP}" ]]; then
    info "Removing existing release.zip ..."
    rm -f "${OUTPUT_ZIP}"
fi

info "Archiving contents as ${WRAP_DIR}/ inside release.zip ..."

# Use a temp dir so the zip contains oni-hk-translation/<files>
# rather than mod/<files>
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "${TEMP_DIR}"' EXIT

cp -r "${SOURCE_DIR}" "${TEMP_DIR}/${WRAP_DIR}"

(cd "${TEMP_DIR}" && zip -r "${OUTPUT_ZIP}" "${WRAP_DIR}")

ZIP_SIZE=$(du -sh "${OUTPUT_ZIP}" | cut -f1)
success "Created: ${OUTPUT_ZIP} (${ZIP_SIZE})"

info "Archive contents:"
zip -sf "${OUTPUT_ZIP}" | sed 's/^/          /'

echo -e "\n${GREEN}${BOLD}✔ Release ready!${RESET}"
echo -e "  ${OUTPUT_ZIP}"