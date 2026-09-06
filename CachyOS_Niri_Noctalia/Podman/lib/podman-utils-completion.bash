# =============================================================================
# Bash Completion for podman-utils
# =============================================================================

_podman_utils_completions() {
    local cur prev words cword
    _init_completion || return

    local commands="create start stop restart logs status destroy link unlink install-global uninstall-global list list-templates doctor help"

    local script_target
    script_target=$(command -v podman-utils 2>/dev/null)
    local repo_dir=""
    if [ -n "$script_target" ]; then
        local real_target
        real_target=$(readlink -f "$script_target" 2>/dev/null || echo "$script_target")
        repo_dir="$(cd "$(dirname "$real_target")/.." 2>/dev/null && pwd)"
    fi

    if [ "$cword" -eq 1 ]; then
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        return 0
    fi

    local cmd="${words[1]}"
    case "$cmd" in
        create)
            if [ "$cword" -eq 2 ] && [ -n "$repo_dir" ] && [ -d "$repo_dir/templates" ]; then
                local templates
                templates=$(find "$repo_dir/templates" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null)
                COMPREPLY=($(compgen -W "$templates" -- "$cur"))
            fi
            ;;
        start|stop|restart|status|destroy|link|unlink)
            if [ "$cword" -eq 2 ] && [ -n "$repo_dir" ] && [ -d "$repo_dir/projects" ]; then
                local projects
                projects=$(find "$repo_dir/projects" -mindepth 1 -maxdepth 1 -type d ! -name ".*" -printf "%f\n" 2>/dev/null)
                COMPREPLY=($(compgen -W "$projects" -- "$cur"))
            fi
            ;;
        logs)
            if [ "$cword" -eq 2 ] && [ -n "$repo_dir" ] && [ -d "$repo_dir/projects" ]; then
                local projects
                projects=$(find "$repo_dir/projects" -mindepth 1 -maxdepth 1 -type d ! -name ".*" -printf "%f\n" 2>/dev/null)
                COMPREPLY=($(compgen -W "$projects" -- "$cur"))
            elif [ "$cword" -eq 3 ] && [ -n "$repo_dir" ]; then
                local proj="${words[2]}"
                if [ -d "$repo_dir/projects/$proj" ]; then
                    local services
                    services=$(find "$repo_dir/projects/$proj" -maxdepth 1 -name "*.container" -printf "%f\n" 2>/dev/null | sed -e "s/^${proj}-//" -e 's/\.container$//')
                    COMPREPLY=($(compgen -W "$services" -- "$cur"))
                fi
            fi
            ;;
        install-global|uninstall-global)
            if [ "$cword" -eq 2 ] && [ -n "$repo_dir" ] && [ -d "$repo_dir/services-shared" ]; then
                local global_services
                global_services=$(find "$repo_dir/services-shared" -maxdepth 1 -name "*.container" -printf "%f\n" 2>/dev/null | sed 's/\.container$//')
                COMPREPLY=($(compgen -W "$global_services" -- "$cur"))
            fi
            ;;
    esac
}

complete -F _podman_utils_completions podman-utils
