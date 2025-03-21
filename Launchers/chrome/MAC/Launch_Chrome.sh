#!/bin/bash

# Static SOCKS5 proxy configuration
SOCKS_PROXY="PROXYHOSTNAME"

# Arguments from Secret Server
URL="$1"         # e.g., https://docs.delinea.com
REMOTE_PORT="$2" # e.g., 443

# Chrome profile directory and logging
CHROME_PROFILE="$HOME/ChromeProfile"
LOG_FILE="$HOME/launch_chrome.log"

# Logging function
log_message() {
  local MESSAGE="$1"
  echo "$(date +"%Y-%m-%d %H:%M:%S"): $MESSAGE" | tee -a "$LOG_FILE"
}

# Validate required arguments
if [ -z "$URL" ] || [ -z "$REMOTE_PORT" ]; then
  log_message "ERROR: URL or Port argument missing."
  exit 1
fi

# Construct full URL
FULL_URL="$URL:$REMOTE_PORT"

log_message "Launching Chrome with SOCKS5 Proxy: $SOCKS_PROXY"
log_message "Target URL: $FULL_URL"

# Launch Chrome via pwsh
pwsh -Command "Start-Process -FilePath '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' -ArgumentList '--proxy-server=$SOCKS_PROXY','--incognito','--user-data-dir=$CHROME_PROFILE','--enable-strict-mixed-content-checking','--app=$FULL_URL','--new-window','$FULL_URL'"

if [ $? -eq 0 ]; then
  log_message "SUCCESS: Chrome launched successfully."
else
  log_message "ERROR: Chrome failed to launch."
fi