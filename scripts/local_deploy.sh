#!/usr/bin/env bash
# ONI HK Translation Deployment Script

set -euo pipefail

# ─── Colors & helpers ───────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*"; }
step()    { echo -e "\n${BOLD}━━━ $* ━━━${RESET}"; }

# ─── Argument parsing ────────────────────────────────────────────────────────
API_TOKEN=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--token)
            API_TOKEN="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-t|--token <api_token>]"
            echo
            echo "  -t, --token   Weblate API token (required if authentication is needed)"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *)
            error "Unknown argument: $1"
            echo "Usage: $0 [-t|--token <api_token>]"
            exit 1
            ;;
    esac
done

# ─── Configuration ───────────────────────────────────────────────────────────
WEBLATE_URL="http://localhost:4000/download/oxygen-not-included/strings/zh_Hant_HK/?format=po&q=state:%3Ctranslated"
DEST_DIR="$(pwd)/mod"
TARGET_DIR="$HOME/.config/unity3d/Klei/Oxygen Not Included/mods/Local/oni-hk-translation"
OUTPUT_FILE="strings.po"

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════╗"
echo "║     ONI HK Translation Deployment Script        ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ════════════════════════════════════════════════════════════
step "Step 1: Download translation file from Weblate"
# ════════════════════════════════════════════════════════════

info "Checking connectivity to Weblate server at localhost:4000 ..."
if ! curl --silent --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" "http://localhost:4000/" &>/dev/null; then
    warn "Cannot connect to Weblate server at http://localhost:4000"
    warn "Make sure your Docker container is running:  docker ps"
    error "Aborting — Weblate is unreachable."
    exit 1
fi
success "Weblate server is reachable."

info "Creating destination directory: ${DEST_DIR}"
mkdir -p "${DEST_DIR}"

info "Downloading strings.po → ${DEST_DIR}/${OUTPUT_FILE}"

CURL_ARGS=(
    --silent
    --show-error
    --connect-timeout 10
    --max-time 120
    --location
    --output "${DEST_DIR}/${OUTPUT_FILE}"
    --write-out "%{http_code}"
)

if [[ -n "$API_TOKEN" ]]; then
    info "Using provided API token for authentication."
    CURL_ARGS+=( --header "Authorization: Token ${API_TOKEN}" )
else
    warn "No API token provided. Attempting unauthenticated download."
    warn "If this fails with 403, re-run with:  $0 --token <your_token>"
fi

HTTP_STATUS=$(curl "${CURL_ARGS[@]}" "${WEBLATE_URL}")

if [[ "$HTTP_STATUS" == "200" ]]; then
    FILE_SIZE=$(wc -c < "${DEST_DIR}/${OUTPUT_FILE}")
    success "Downloaded successfully (HTTP 200, ${FILE_SIZE} bytes)"
    success "Saved to: ${DEST_DIR}/${OUTPUT_FILE}"
elif [[ "$HTTP_STATUS" == "403" ]]; then
    error "HTTP 403 Forbidden — authentication required or token is invalid."
    error "Re-run with a valid token:  $0 --token <your_weblate_api_token>"
    rm -f "${DEST_DIR}/${OUTPUT_FILE}"
    exit 1
elif [[ "$HTTP_STATUS" == "404" ]]; then
    error "HTTP 404 Not Found — check your Weblate project/component slug."
    rm -f "${DEST_DIR}/${OUTPUT_FILE}"
    exit 1
else
    error "Unexpected HTTP status: ${HTTP_STATUS}"
    rm -f "${DEST_DIR}/${OUTPUT_FILE}"
    exit 1
fi

# ════════════════════════════════════════════════════════════
step "Step 2: Clear existing translation mod files"
# ════════════════════════════════════════════════════════════

info "Target directory: ${TARGET_DIR}"

if [[ -d "${TARGET_DIR}" ]]; then
    FILE_COUNT=$(find "${TARGET_DIR}" -mindepth 1 | wc -l)
    info "Deleting ${FILE_COUNT} item(s) inside the mod directory..."
    rm -rf "${TARGET_DIR:?}"/*
    success "Cleared all contents from mod directory."
else
    warn "Target directory does not exist yet — it will be created in the next step."
fi

# ════════════════════════════════════════════════════════════
step "Step 3: Deploy mod files to ONI mods directory"
# ════════════════════════════════════════════════════════════

info "Source:      ${DEST_DIR}/"
info "Destination: ${TARGET_DIR}/"

mkdir -p "${TARGET_DIR}"
cp -rv "${DEST_DIR}/." "${TARGET_DIR}/"

COPIED=$(find "${TARGET_DIR}" -mindepth 1 | wc -l)
success "Copied ${COPIED} file(s) to mod directory."

echo -e "\n${GREEN}${BOLD}✔ Deployment complete!${RESET}"
echo -e "  Translation is ready in: ${TARGET_DIR}"