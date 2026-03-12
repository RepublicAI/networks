#!/bin/bash
# Republic AI - Watchdog Script
# Monitors full-auto.sh and restarts it if it stops

SCRIPT_PATH="$HOME/full-auto.sh"
LOG_PATH="$HOME/full-auto.log"

echo "Watchdog started. Monitoring: $SCRIPT_PATH"

while true; do
  if ! pgrep -f "full-auto.sh" > /dev/null; then
    echo "[$(date '+%H:%M:%S')] full-auto.sh stopped! Restarting..."
    nohup $SCRIPT_PATH >> $LOG_PATH 2>&1 &
    echo "[$(date '+%H:%M:%S')] Restarted! PID: $!"
  fi
  sleep 30
done
