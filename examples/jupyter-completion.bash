# load with: . jupyter-completion.bash

if [[ -n ${ZSH_VERSION-} ]]; then
    autoload -Uz bashcompinit && bashcompinit
fi

_jupyter_get_flags()
{
    local url=$1
    local var=$2
    local dash=$3
    if [[ "$url $var" == $__jupyter_complete_last ]]; then
        opts=$__jupyter_complete_last_res
        return
    fi
    # matplotlib and profile don't need the = and the
    # version without simplifies the special cased completion
    opts=$(jupyter ${url} --help-all | grep -E "^-{1,2}[^-]" | sed -e "s/<.*//" -e "s/[^=]$/& /" -e "$ s/^/\n-h\n--help\n--help-all\n/")
    __jupyter_complete_last="$url $var"
    __jupyter_complete_last_res="$opts"
}

_jupyter()
{
    local cur=${COMP_WORDS[COMP_CWORD]}
    local prev=${COMP_WORDS[COMP_CWORD - 1]}
    local subcommands="notebook qtconsole console nbconvert kernelspec trust "
    local opts="help"
    if [ -z "$__jupyter_complete_baseopts" ]; then
        _jupyter_get_flags baseopts
        __jupyter_complete_baseopts="${opts}"
    fi
    local baseopts="$__jupyter_complete_baseopts"
    local mode=""
    for i in "${COMP_WORDS[@]}"; do
        [ "$cur" = "$i" ] && break
        if [[ ${subcommands} == *${i}* ]]; then
            mode="$i"
            break
        elif [[ ${i} == "--"* ]]; then
            mode="nosubcommand"
            break
        fi
    done


    if [[ ${cur} == -* ]]; then
        case $mode in
            "notebook" | "qtconsole" | "console" | "nbconvert")
                _jupyter_get_flags $mode
                opts=$"${opts} ${baseopts}"
                ;;
            "kernelspec")
                if [[ $COMP_CWORD -ge 3 ]]; then
                    # 'history trim' and 'history clear' covered by next line
                    _jupyter_get_flags $mode\ "${COMP_WORDS[2]}"
                else
                    _jupyter_get_flags $mode

                fi
                opts=$"${opts}"
                ;;
            *)
                opts=$baseopts
        esac
        # don't drop the trailing space
        local IFS=$'\t\n'
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    elif [[ $mode == "kernelspec" ]]; then
        if [[ $COMP_CWORD -ge 3 ]]; then
            # drop into flags
            opts="--"
        else
            opts="list 	install "
        fi
        local IFS=$'\t\n'
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    else
        if [ "$COMP_CWORD" == 1 ]; then
            local IFS=$'\t\n'
            local sub=$(echo $subcommands | sed -e "s/ / \t/g")
            COMPREPLY=( $(compgen -W "${sub}" -- ${cur}) )
        else
            COMPREPLY=( $(compgen -f -- ${cur}) )
        fi
    fi

}
complete -o default -o nospace -F _jupyter jupyter
