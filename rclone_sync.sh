#!/bin/bash

# rclone_sync.sh - Infinite rclone sync with environment variable validation

# Default sleep time between runs (in seconds)
DEFAULT_SLEEP_TIME=300  # 5 minutes

# Function to display usage
usage() {
    echo "Usage: $0"
    echo ""
    echo "Environment variables required:"
    echo "  RCLONE_REMOTE       - Remote name (e.g., 'dest')"
    echo "  RCLONE_REMOTE_PATH  - Remote path (e.g., 'downloads/jordan-downloads/')"
    echo "  RCLONE_LOCAL_PATH   - Local path (e.g., '/mnt/plex_library/downloads/')"
    echo ""
    echo "Optional environment variables:"
    echo "  SLEEP_TIME          - Time in seconds between syncs (default: ${DEFAULT_SLEEP_TIME})"
    echo "  RCLONE_EXTRA_FLAGS  - Additional flags for rclone command"
    echo ""
    echo "Example:"
    echo "  export RCLONE_REMOTE=\"dest\""
    echo "  export RCLONE_REMOTE_PATH=\"downloads/jordan-downloads/\""
    echo "  export RCLONE_LOCAL_PATH=\"/mnt/plex_library/downloads/\""
    echo "  export SLEEP_TIME=60"
    echo "  ./rclone_sync.sh"
}

# Function to validate environment variables
validate_env_vars() {
    local missing_vars=()
    
    if [[ -z "${RCLONE_REMOTE}" ]]; then
        missing_vars+=("RCLONE_REMOTE")
    fi
    
    if [[ -z "${RCLONE_REMOTE_PATH}" ]]; then
        missing_vars+=("RCLONE_REMOTE_PATH")
    fi
    
    if [[ -z "${RCLONE_LOCAL_PATH}" ]]; then
        missing_vars+=("RCLONE_LOCAL_PATH")
    fi
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        echo "ERROR: Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        echo ""
        usage
        exit 1
    fi
}

# Function to run rclone sync
run_sync() {
    local remote_path="${RCLONE_REMOTE}:${RCLONE_REMOTE_PATH}"
    local local_path="${RCLONE_LOCAL_PATH}"
    local extra_flags="${RCLONE_EXTRA_FLAGS:-}"
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting rclone sync..."
    echo "Remote: ${remote_path}"
    echo "Local:  ${local_path}"
    echo "Flags:  --transfers 16 --stats-one-line -P --size-only ${extra_flags}"
    
    rclone sync --transfers 16 --stats-one-line -P --size-only ${extra_flags} "${remote_path}" "${local_path}"
    
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sync completed successfully"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sync failed with exit code: $exit_code"
    fi
    
    return $exit_code
}

# Main execution
main() {
    # Validate environment variables
    validate_env_vars
    
    # Set sleep time with default
    local sleep_time=${SLEEP_TIME:-$DEFAULT_SLEEP_TIME}
    
    echo "=================================================="
    echo "rclone Infinite Sync Script"
    echo "=================================================="
    echo "Remote:          ${RCLONE_REMOTE}:${RCLONE_REMOTE_PATH}"
    echo "Local:           ${RCLONE_LOCAL_PATH}"
    echo "Sleep time:      ${sleep_time} seconds"
    echo "Extra flags:     ${RCLONE_EXTRA_FLAGS:-None}"
    echo "=================================================="
    echo "Press Ctrl+C to stop the script"
    echo "=================================================="
    
    # Infinite loop
    while true; do
        run_sync
        
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sleeping for ${sleep_time} seconds..."
        echo "=================================================="
        
        # Sleep with progress indicator
        for ((i=0; i<sleep_time; i++)); do
            printf "\rSleeping: %3d/%d seconds" "$i" "$sleep_time"
            sleep 1
        done
        printf "\rSleeping: %3d/%d seconds - Complete!\n" "$sleep_time" "$sleep_time"
    done
}

# Handle script termination
cleanup() {
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Script terminated by user"
    exit 0
}

# Set trap for Ctrl+C
trap cleanup SIGINT SIGTERM

# Run main function
main
