#!/usr/bin/env bash
set -euo pipefail

# --- config ---
DOMAIN="my-domaine"                                  # just the subdomain label
TOKEN="my-token"        # consider storing in a file with 600 perms

LOG_DIR="/home/pihole/logs/duckdns"
LOG_FILE="$LOG_DIR/duckdns.log"
STATE_FILE="/home/pihole/.duckdns/last_ip"
CURL="/usr/bin/curl"

# --- SETUP ---
mkdir -p "$LOG_DIR" "$(dirname "$STATE_FILE")"
touch "$LOG_FILE"
chmod 700 "$(dirname "$STATE_FILE")"
chmod 600 "$LOG_FILE"

log() {
    printf "%s %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE" >/dev/null
}

# --- GET CURRENT PUBLIC IP ---
NEW_IP="$($CURL -sS -4 --max-time 5 ifconfig.me || true)"
[[ -z "$NEW_IP" ]] && NEW_IP="$($CURL -sS -4 --max-time 5 https://api.ipify.org || true)"

if [[ -z "$NEW_IP" ]]; then
    log "ERROR: Could not detect public IPv4 address."
    exit 1
fi

OLD_IP="$(cat "$STATE_FILE" 2>/dev/null || true)"

# --- SKIP IF IP UNCHANGED ---
if [[ "$NEW_IP" == "$OLD_IP" && -n "$OLD_IP" ]];then
    log "OK: IP unchanged ($NEW_IP). No update sent."
    exit 0
fi

# --- UPDATE DUCKDNS ---
UPDATE_URL="https://www.duckdns.org/update?domains=${DOMAIN}&token=${TOKEN}&ip=${NEW_IP}"
RESP="$($CURL -sS -4 --max-time 8 "$UPDATE_URL" || true)"

if [[ "$RESP" != "OK" ]]; then
    log "WARN: First update attempt failed (resp='$RESP'). Retrying..."
    sleep 2
    RESP="$($CURL -sS -4 --max-time 8 "$UPDATE_URL" || true)"
fi

# --- SAVE RESULT ---
if [[ "$RESP" == "OK" ]]; then
    printf "%s" "$NEW_IP" > "$STATE_FILE"
    chmod 600 "$STATE_FILE"
    if [[ -z "$OLD_IP" ]]; then
        log "OK: Set initial IP to $NEW_IP."
    else
        log "OK: IP changed $OLD_IP -> $NEW_IP, DuckDNS updated."
    fi
else
    log "ERROR: DuckDNS update failed (resp='$RESP')."
    exit 1
fi
 
