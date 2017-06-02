# Whether to automatically run clean_project
AUTO_CLEAN_PROJECT="${AUTO_CLEAN_PROJECT:=true}"

# Default file patterns
if [ ! -n "$AUTO_CLEAN_PROJECT_FILE_PATTERNS" ]; then
    AUTO_CLEAN_PROJECT_FILE_PATTERNS=(
        ".DS_Store"
        "Thumbs.db"
    )
fi

# Default ignore paths
if [ ! -n "$AUTO_CLEAN_PROJECT_IGNORE_PATHS" ]; then
    AUTO_CLEAN_PROJECT_IGNORE_PATHS=(
        "./node_modules/*"
        "./bower_components/*"
    )
fi

# Show a message after automatically cleaning
AUTO_CLEAN_PROJECT_SILENT="${AUTO_CLEAN_PROJECT_SILENT:=false}"
AUTO_CLEAN_PROJECT_MESSAGE="${AUTO_CLEAN_PROJECT_MESSAGE:="Automatically removed the following files:"}"

# Check if the current directory is in a Git repository
_is_git() {
  command git rev-parse --is-inside-work-tree &>/dev/null
}

# Delete files in git repos
clean_project() {
    declare -a file_patterns=()
    declare -a ignore_paths=()
    ignore_option=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                echo "usage: clean_project FILE_NAME ... [-i|--ignore PATH ...]"
                echo " "
                echo "default files:"
                printf '%s\n' "${AUTO_CLEAN_PROJECT_FILE_PATTERNS[@]}"
                echo " "
                echo "default ignore paths:"
                printf '%s\n' "${AUTO_CLEAN_PROJECT_IGNORE_PATHS[@]}"
                echo " "
                echo "options:"
                echo "-h, --help                show brief help"
                echo "-i, --ignore              specify paths to ignore"
                return
                ;;
            -i|--ignore)
                ignore_option=true
                shift
                ;;
            *)
                if [ $ignore_option == true ]; then ignore_paths+=("$1");
                else file_patterns+=("$1"); fi
                shift
                ;;
        esac
    done

    _is_git || return

    [[ ${#file_patterns[@]} -eq 0 ]] &&
        file_patterns=("${AUTO_CLEAN_PROJECT_FILE_PATTERNS[@]}")
    [[ ${#ignore_paths[@]} -eq 0 ]] &&
        ignore_paths=("${AUTO_CLEAN_PROJECT_IGNORE_PATHS[@]}")

    # get the current project directory
    dir=$(git rev-parse --show-toplevel)

    # build the `find` command
    find="find $dir -type f \("
    for pattern in "${file_patterns[@]}"; do find+=" -name \"$pattern\" -o"; done
    find="${find:0:-3} \) -a ! \("
    for pattern in "${ignore_paths[@]}"; do find+=" -path \"$pattern\" -prune -o"; done
    find="${find:0:-3} \) -print0"

    # found files
    files=()

    # get results of find
    while IFS= read -d $'\0' -r file ; do
        files=("${files[@]}" "$file")
    done < <(eval $find)

    # remove the found files and print the list
    if [ -n "${files// }" ]; then
        rm $files && printf '%s\n' "${files[@]##$dir/}"
    fi
}

auto_clean_project() {
    if [ $AUTO_CLEAN_PROJECT == true ]; then
        files=$(clean_project)

        if [ $AUTO_CLEAN_PROJECT_SILENT == false ] && [ -n "${files// }" ]; then
            echo $AUTO_CLEAN_PROJECT_MESSAGE
            echo $files
        fi
    fi
}

# zsh autoload
autoload -U add-zsh-hook
add-zsh-hook chpwd auto_clean_project
