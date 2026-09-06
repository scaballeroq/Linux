#compdef podman-utils
# =============================================================================
# Zsh Completion for podman-utils (CachyOS + KDE Plasma 6)
# =============================================================================

_podman_utils_get_repo_dir() {
    local script_target
    script_target=$(command -v podman-utils 2>/dev/null)
    if [ -n "$script_target" ]; then
        local real_target
        real_target=$(readlink -f "$script_target" 2>/dev/null || echo "$script_target")
        echo "$(cd "$(dirname "$real_target")/.." 2>/dev/null && pwd)"
    else
        echo ""
    fi
}

_podman_utils() {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    local -a commands
    commands=(
        'create:Crea un nuevo proyecto a partir de una plantilla'
        'start:Inicia todos los contenedores del proyecto vía systemd'
        'stop:Detiene el proyecto y sus contenedores'
        'restart:Reinicia el proyecto'
        'logs:Muestra los logs en vivo vía journalctl'
        'status:Muestra el estado detallado de contenedores y servicios'
        'destroy:Elimina por completo el proyecto (archivos, contenedores, volúmenes)'
        'link:Enlaza los archivos Quadlet del proyecto a systemd'
        'unlink:Desenlaza los archivos Quadlet de systemd'
        'install-global:Instala un servicio compartido en systemd user'
        'uninstall-global:Desinstala un servicio compartido'
        'list:Lista todos los proyectos creados y su estado'
        'list-templates:Muestra las plantillas de proyectos disponibles'
        'doctor:Ejecuta diagnóstico de Podman y Quadlets'
        'help:Muestra mensaje de ayuda'
    )

    _arguments -C \
        '1:Comando:->command' \
        '*::Argumentos:->args'

    case $state in
        command)
            _describe -t commands 'Comandos de podman-utils' commands
            ;;
        args)
            local cmd="${line[1]}"
            local repo_dir
            repo_dir=$(_podman_utils_get_repo_dir)

            case $cmd in
                create)
                    if [ $CURRENT -eq 2 ]; then
                        local -a templates
                        if [ -n "$repo_dir" ] && [ -d "$repo_dir/templates" ]; then
                            templates=($(find "$repo_dir/templates" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null))
                        fi
                        _describe -t templates 'Plantillas disponibles' templates
                    elif [ $CURRENT -eq 3 ]; then
                        _message 'Nombre del nuevo proyecto'
                    fi
                    ;;
                start|stop|restart|status|destroy|link|unlink)
                    local -a projects
                    if [ -n "$repo_dir" ] && [ -d "$repo_dir/projects" ]; then
                        projects=($(find "$repo_dir/projects" -mindepth 1 -maxdepth 1 -type d ! -name ".*" -printf "%f\n" 2>/dev/null))
                    fi
                    _describe -t projects 'Proyectos existentes' projects
                    ;;
                logs)
                    if [ $CURRENT -eq 2 ]; then
                        local -a projects
                        if [ -n "$repo_dir" ] && [ -d "$repo_dir/projects" ]; then
                            projects=($(find "$repo_dir/projects" -mindepth 1 -maxdepth 1 -type d ! -name ".*" -printf "%f\n" 2>/dev/null))
                        fi
                        _describe -t projects 'Proyectos existentes' projects
                    elif [ $CURRENT -eq 3 ]; then
                        local proj="${line[2]}"
                        local -a services
                        if [ -n "$repo_dir" ] && [ -d "$repo_dir/projects/$proj" ]; then
                            services=($(find "$repo_dir/projects/$proj" -maxdepth 1 -name "*.container" -printf "%f\n" 2>/dev/null | sed -e "s/^${proj}-//" -e 's/\.container$//'))
                        fi
                        _describe -t services 'Servicio del proyecto' services
                    fi
                    ;;
                install-global|uninstall-global)
                    local -a global_services
                    if [ -n "$repo_dir" ] && [ -d "$repo_dir/services-shared" ]; then
                        global_services=($(find "$repo_dir/services-shared" -maxdepth 1 -name "*.container" -printf "%f\n" 2>/dev/null | sed 's/\.container$//'))
                    fi
                    _describe -t global_services 'Servicios globales' global_services
                    ;;
            esac
            ;;
    esac
}

_podman_utils "$@"
