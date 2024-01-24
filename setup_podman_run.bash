#!/usr/bin/env bash

eval "$(podman completion bash)"

# Adapted from __start_podman given by the output of $(podman completion bash)
__complete_delegate_podman()
{
    local cur prev words cword split

    COMPREPLY=()

    # Call _init_completion from the bash-completion package
    # to prepare the arguments properly
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -n =: || return
    else
        __podman_init_completion -n =: || return
    fi

    i=1
    [[ "${words[0]}" == "podstart" ]] && {
        ((cword++)); words=('podman' 'run' "${words[@]:$i}")
    }
    [[ "${words[0]}" == "podshell" ]] && {
        ((cword++)); words=('podman' 'exec' "${words[@]:$i}")
    }
    [[ "${words[0]}" == "podstop" ]] && {
        ((cword+=2)); words=('podman' 'container' 'stop' "${words[@]:$i}")
    }
    [[ "${words[0]}" == "podkill" ]] && {
        ((cword+=2)); words=('podman' 'container' 'kill' "${words[@]:$i}")
    }
    __podman_debug
    __podman_debug "========= starting completion logic =========="
    __podman_debug "cur is ${cur}, words[*] is ${words[*]}, #words[@] is ${#words[@]}, cword is $cword"


    # The user could have moved the cursor backwards on the command-line.
    # We need to trigger completion from the $cword location, so we need
    # to truncate the command-line ($words) up to the $cword location.
    words=("${words[@]:0:$cword+1}")
    __podman_debug "Truncated words[*]: ${words[*]},"

    local out directive
    __podman_get_completion_results
    __podman_process_completion_results
}


podstart() {
    local runopts=(
        --net=host
        --group-add=keep-groups
        --userns=keep-id
        --security-opt=label=disable
        --device=nvidia.com/gpu=all
        --tty
        --interactive
        --rm
        --env "DISPLAY=${DISPLAY}"
        --volume "${HOME}/Projects:${HOME}/Projects"
        --volume "${HOME}/.cache/containers/home:${HOME}"
        --workdir "${HOME}"
        --detach
    )
    podman run "${runopts[@]}" "$@"
}
complete -F __complete_delegate_podman podstart

podshell() {
    podman exec --tty --interactive "$@" bash -l
}
complete -F __complete_delegate_podman podshell

podstop() {
    podman stop "$@"
}
complete -F __complete_delegate_podman podstop

podkill() {
    podman kill "$@"
}
complete -F __complete_delegate_podman podkill
