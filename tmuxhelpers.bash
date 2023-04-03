#!/usr/bin/env bash

function exec_in_window()
{
    local session_name=$1; shift 
    local window_name=$1; shift
    tmux select-window -t "=$session_name:=$window_name" > /dev/null 2>&1 || 
        tmux new-window -n "$window_name" -t "=$session_name"
    tmux send-keys -t "=$session_name:=$window_name" "$@" Enter
}


function attach_or_switch_to()
{
    local target_session=$1
    if [ -n "${TMUX:-}" ]
    then
        tmux switch-client -t "=$target_session"
    else
        tmux attach-session -t "=$target_session"
    fi
}
