#!/usr/bin/env bash

CONTAINER_CACHE_HOME="${HOME}/.containers/cache/home"

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
    [[ "${words[0]}" == "podstart" || "${words[0]}" == "podrun" ]] && {
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


podrun() {
    xhost | grep -q "$USER" || {
        echo "Enabling X11 authority"
        xhost +"SI:localuser:${USER}"
    }
    local runopts=(
        --net=host
        --group-add=keep-groups
        --userns=keep-id
        --security-opt=label=disable
        --device=nvidia.com/gpu=all
        --tz=local
        --tty
        --interactive
        --rm
        --env "DISPLAY=${DISPLAY}"
        --volume "${CONTAINER_CACHE_HOME}:${HOME}"
    )
    if [[ ! -z "$SSH_AUTH_SOCK" ]]; then
        runopts+=(--volume "${SSH_AUTH_SOCK}":"${SSH_AUTH_SOCK}")
        runopts+=(--env "SSH_AUTH_SOCK=${SSH_AUTH_SOCK}")
    fi
    if [[ "$PWD" != "$HOME" && "$PWD" == *"$HOME"* ]]; then
        local _container_home="$CONTAINER_CACHE_HOME"
        local _target_in_container="${_container_home}"/"${PWD#${HOME}/}"
        if [[ ! -d "$_target_in_container" ]]; then
            mkdir -p "$_target_in_container"
        else
            local _nonempty_dirs="$(find "$_target_in_container" -maxdepth 1 -type d ! -empty)"
            [[ ! -z "$_nonempty_dirs" ]] && {
                printf -v _warn_msg "%s" \
                    "Warning: mounting pwd would overwrite " \
                    "these nonempty directories in the container"
                echo "$_warn_msg"
                echo "$_nonempty_dirs"
            }
        fi
        runopts+=(--volume "${PWD}":"${PWD}")
        runopts+=(--workdir "${PWD}")
    else
        runopts+=(--workdir "${HOME}")
    fi
    podman run "${runopts[@]}" "$@"
}
complete -F __complete_delegate_podman podrun

podstart() {
    podrun --detach "$@"
}
complete -F __complete_delegate_podman start

podshell() {
    if [ -t 1 ]; then
        podman exec --tty --interactive \
            --env "TERM=xterm-256color" "$@" bash -l
    else
        podman exec --interactive "$@" bash -l
    fi
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
