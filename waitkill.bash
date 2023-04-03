#!/usr/bin/env bash

function waitkill() {
    local TIMEOUT=30
    local INTERVAL=1
    local tmpscript=""
    tmpscript=$(mktemp)

    # Be nice, post SIGTERM first.
    pkill --signal SIGTERM -f "$@"

    # Wait for process to exit
    printf "\nWaiting for %s to exit.\n" "$@"
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
    gum spin --spinner dot -- /bin/bash "$tmpscript"
    rm "$tmpscript"

    # Done being nice. SIGKIL
    pkill -0 -f "$@"
    ret=$?
    if ((ret == 0)); then
        printf "\nUnable to gracefully stop %s. Raising to SIGKILL\n" "$@"
        pkill -9 -f "$@"
    else
        printf "\n%s exited gracefully.\n" "$@"
    fi
}
