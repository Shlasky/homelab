#!/usr/bin/env bash

# Text formatting and colors
_B='\033[1;'      # Bold
G='32m'  # Green
Y='33m'  # Yellow
R='31m'  # Red
B='34m'  # Blue

log(){
  local level="$1"
  shift
  local message="$*"

  case "$level" in
    SUCCESS) clr="$_B$G" ;;
    INFO) clr="$_B$B" ;;
    WARN) clr="$_B$Y" ;;
    ERROR) clr="$_B$R" ;;
  esac

  echo -e "$clr$(date "+%d-%m-%Y %T") | $level | $message"
  return 0
}

# --------------------------------------------------------------------------

log INFO "Starting Tailscale status check..."

# Check if tailscale command exists
if ! command -v tailscale &> /dev/null; then
    log ERROR "Tailscale command not found. Is Tailscale installed?"
    exit 1
fi

# Configuration
MAX_RETRIES=3
RETRY_DELAY=5  # seconds between retries

# Check Tailscale status with retries
check_tailscale_status() {
    local retry=0

    while [ $retry -lt $MAX_RETRIES ]; do
        if tailscale status &> /dev/null; then
            return 0  # Success - Tailscale is connected
        fi

        retry=$((retry + 1))
        if [ $retry -lt $MAX_RETRIES ]; then
            log WARN "Tailscale check failed (attempt $retry/$MAX_RETRIES). Retrying in ${RETRY_DELAY}s..."
            sleep $RETRY_DELAY
        fi
    done

    return 1  # Failed after all retries
}

# Check if Tailscale is connected
if check_tailscale_status; then
    log SUCCESS "Tailscale is connected and running"
    exit 0
fi

# Tailscale is not connected, try to bring it up
log WARN "Tailscale is not connected after $MAX_RETRIES attempts. Attempting to bring it up..."

# Try to reconnect with retries
reconnect_retry=0
while [ $reconnect_retry -lt $MAX_RETRIES ]; do
    if tailscale up --ssh 2>&1; then
        log SUCCESS "Tailscale reconnected successfully"

        # Verify connection after bringing it up
        sleep 2
        if tailscale status &> /dev/null; then
            log SUCCESS "Tailscale connection verified"
            exit 0
        else
            log WARN "Tailscale up succeeded but status check failed. Will retry..."
        fi
    fi

    reconnect_retry=$((reconnect_retry + 1))
    if [ $reconnect_retry -lt $MAX_RETRIES ]; then
        log WARN "Reconnect attempt $reconnect_retry/$MAX_RETRIES failed. Retrying in ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
    fi
done

log ERROR "Failed to reconnect Tailscale after $MAX_RETRIES attempts"
exit 1
