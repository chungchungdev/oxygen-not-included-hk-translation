#!/usr/bin/env bash
# local_deploy.sh — Deploy ONI HK translation mod files

set -euo pipefail

# ─── Colors & helpers ────────────────────────────────────────────────────────
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

# ─── Argument parsing ─────────────────────────────────────────────────────────
SOURCE="local"
API_TOKEN=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            SOURCE="$2"
            shift 2
            ;;
        -t|--token)
            API_TOKEN="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--source <local|weblate>] [-t|--token <api_token>]"
            echo
            echo "  --source      Where to get mod files from (default: local)"
            echo "                  local    — use existing files in <cwd>/mod/"
            echo "                  weblate  — download fresh from Weblate first"
            echo "  -t, --token   Weblate API token (only used when --source=weblate)"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *)
            error "Unknown argument: $1"
            echo "Usage: $0 [--source <local|weblate>] [-t|--token <api_token>]"
            exit 1
            ;;
    esac
done

if [[ "$SOURCE" != "local" && "$SOURCE" != "weblate" ]]; then
    error "Invalid --source value: '${SOURCE}'. Must be 'local' or 'weblate'."
    exit 1
fi

# ─── Configuration ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(pwd)/mod"
TARGET_DIR="$HOME/.config/unity3d/Klei/Oxygen Not Included/mods/Local/oni-hk-translation"

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════╗"
echo "║     ONI HK Translation Deployment Script        ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ════════════════════════════════════════════════════════════
if [[ "$SOURCE" == "weblate" ]]; then
    step "Step 1: Download translation file from Weblate"

    WEBLATE_SCRIPT="${SCRIPT_DIR}/weblate_download.sh"
    if [[ ! -f "$WEBLATE_SCRIPT" ]]; then
        error "weblate_download.sh not found at: ${WEBLATE_SCRIPT}"
        error "Make sure both scripts are in the same directory."
        exit 1
    fi

    WEBLATE_ARGS=()
    if [[ -n "$API_TOKEN" ]]; then
        WEBLATE_ARGS+=( --token "$API_TOKEN" )
    fi

    bash "$WEBLATE_SCRIPT" "${WEBLATE_ARGS[@]}"
else
    step "Step 1: Skipped (--source=local)"
    info "Using existing files in: ${SOURCE_DIR}"
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

if [[ ! -d "${SOURCE_DIR}" ]] || [[ -z "$(ls -A "${SOURCE_DIR}" 2>/dev/null)" ]]; then
    error "Source directory is empty or does not exist: ${SOURCE_DIR}"
    error "Run with --source=weblate to download files first, or add files to mod/ manually."
    exit 1
fi

info "Source:      ${SOURCE_DIR}/"
info "Destination: ${TARGET_DIR}/"

mkdir -p "${TARGET_DIR}"
cp -rv "${SOURCE_DIR}/." "${TARGET_DIR}/"

COPIED=$(find "${TARGET_DIR}" -mindepth 1 | wc -l)
success "Copied ${COPIED} file(s) to mod directory."

echo -e "\n${GREEN}${BOLD}✔ Deployment complete!${RESET}"
echo -e "  Translation is ready in: ${TARGET_DIR}"