#!/usr/bin/env bash

function waitkill() {
    # No matching process? Do nothing 
    pkill -0 -f "$@" || return 0

    # Setup
    local TIMEOUT=30
    local INTERVAL=1
    local tmpscript=""
    tmpscript=$(mktemp)

    # Be nice, post SIGTERM first
    pkill --signal SIGTERM -f "$@"

    # Wait for process to exit
    cat <<EOF > "$tmpscript"
((t = $TIMEOUT))
pkill -0 -f "$@"
ret=$?
while [[ (\$ret -eq 0) && (\$t > 0) ]]; do
    sleep $INTERVAL
    ((t -= $INTERVAL))
    pkill -0 -f "$@"
    ret=\$?
done
EOF
    (
        GUM_SPIN_TITLE=$(printf "Waiting for %s to exit...\n" "$@") \
            gum spin --spinner dot -- /bin/bash "$tmpscript"
        rm "$tmpscript"
    )

    # If it died, stop
    pkill -0 -f "$@" || return 0

    # Otherwise, done being nice. Send SIGKILL
    printf "Unable to gracefully stop %s. Raising to SIGKILL\n" "$@"
    pkill -9 -f "$@"
}
