#!/bin/bash
# Deploy a WAR to Tomcat, restart, and revert to previous WAR on failure.
# Usage: tomcatstart.sh /path/to/new.war [context] [health_url] [timeout_seconds]
set -euo pipefail

CATALINA_HOME="/opt/tomcat"
TOMCAT_BIN="$CATALINA_HOME/bin"
WEBAPPS="$CATALINA_HOME/webapps"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 /path/to/new.war [context] [health_url] [timeout_seconds]"
    exit 2
fi

NEW_WAR="$1"
if [[ ! -f "$NEW_WAR" ]]; then
    echo "Error: WAR file not found: $NEW_WAR"
    exit 3
fi

CONTEXT="${2:-login}"
HEALTH_URL="${3:-http://localhost:8080/${CONTEXT:-ROOT}/health}"
TIMEOUT="${4:-60}"

# Derive context if not provided: basename without .war
if [[ -z "$CONTEXT" ]]; then
    base="$(basename "$NEW_WAR")"
    CONTEXT="${base%.war}"
fi

APP_WAR="$WEBAPPS/$CONTEXT.war"
APP_DIR="$WEBAPPS/bkp/$CONTEXT"

timestamp() { date +%s; }

backup_ts=$(timestamp)
BACKUP_WAR="${APP_WAR}.bak.${backup_ts}"
BACKUP_DIR="${APP_DIR}.bak.${backup_ts}"

echo "Deploying $NEW_WAR -> $APP_WAR (context: $CONTEXT)"
echo "Tomcat home: $CATALINA_HOME"

stop_tomcat() {
    echo "Stopping Tomcat..."
    "$TOMCAT_BIN/shutdown.sh" >/dev/null 2>&1 || true
    # wait for java process that uses CATALINA_HOME to exit
    for i in $(seq 1 20); do
        if ! pgrep -f "$CATALINA_HOME" >/dev/null 2>&1; then
            echo "Tomcat stopped."
            return
        fi
        sleep 1
    done
    echo "Tomcat did not stop gracefully; continuing."
}

start_tomcat() {
    echo "Starting Tomcat..."
    "$TOMCAT_BIN/startup.sh"
}

deploy_new() {
    # Backup existing war/dir if present
    [[ -f "$APP_WAR" ]] && mv "$APP_WAR" "$BACKUP_WAR"
    [[ -d "$APP_DIR" ]] && mv "$APP_DIR" "$BACKUP_DIR"
    # Copy new war
    cp -f "$NEW_WAR" "$APP_WAR"
    chown --reference="$CATALINA_HOME" "$APP_WAR" || true
}

restore_backup() {
    echo "Restoring previous deployment..."
    # Find and restore the latest backup
    latest_war=$(ls -t "$APP_WAR".bak.* 2>/dev/null | head -1)
    if [[ -n "$latest_war" ]]; then
        mv "$latest_war" "$APP_WAR"
    fi
    
    latest_dir=$(ls -td "$APP_DIR".bak.* 2>/dev/null | head -1)
    if [[ -n "$latest_dir" ]]; then
        mv "$latest_dir" "$APP_DIR"
    fi
}

check_health() {
    # If user provided health URL, use it. Otherwise, wait for exploded dir + WEB-INF.
    if [[ -n "$HEALTH_URL" ]]; then
        echo "Checking health URL: $HEALTH_URL (timeout ${TIMEOUT}s)"
        end=$((SECONDS + TIMEOUT))
        while [[ $SECONDS -lt $end ]]; do
            if curl -sfS "$HEALTH_URL" >/dev/null 2>&1; then
                echo "Health check passed."
                return 0
            fi
            sleep 2
        done
        echo "Health check failed."
        return 1
    else
        echo "No health URL provided; checking for exploded app directory presence."
        end=$((SECONDS + TIMEOUT))
        while [[ $SECONDS -lt $end ]]; do
            if [[ -d "$APP_DIR" && -d "$APP_DIR/WEB-INF" ]]; then
                echo "App exploded and WEB-INF found."
                return 0
            fi
            sleep 1
        done
        echo "App did not explode within timeout."
        return 1
    fi
}

# Main flow
stop_tomcat
deploy_new
start_tomcat

if check_health; then
    echo "Deployment succeeded."
    # cleanup old backups optionally - keep for safety
    exit 0
else
    echo "Deployment failed; attempting rollback."
    stop_tomcat
    restore_backup
    start_tomcat
    if check_health; then
        echo "Rollback succeeded; previous version restored."
        exit 0
    else
        echo "Rollback failed. Manual intervention required. Backups:"
        [[ -f "$BACKUP_WAR" ]] && echo "  WAR backup: $BACKUP_WAR"
        [[ -d "$BACKUP_DIR" ]] && echo "  Dir backup: $BACKUP_DIR"
        exit 4
    fi
fi