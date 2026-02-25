#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
SKILLS_DST="$HOME/.claude/skills"

usage() {
    echo "Usage: ./skills.sh <command> [skill-name]"
    echo ""
    echo "Commands:"
    echo "  install [name]    Symlink skills into ~/.claude/skills/"
    echo "  uninstall [name]  Remove symlinks pointing to this repo"
    echo "  list              Show status of all skills"
    echo ""
    echo "If no name is given, operates on all skills."
}

# List skill directories in the repo
available_skills() {
    for dir in "$SKILLS_SRC"/*/; do
        [ -d "$dir" ] && basename "$dir"
    done
}

skill_exists() {
    [ -d "$SKILLS_SRC/$1" ]
}

# Check status of a skill: installed, conflict, or not_installed
skill_status() {
    local name="$1"
    local target="$SKILLS_DST/$name"

    if [ -L "$target" ]; then
        local link_target
        link_target="$(readlink "$target")"
        # Resolve relative symlink for comparison
        local resolved
        resolved="$(cd "$SKILLS_DST" && cd "$(dirname "$link_target")" && pwd)/$(basename "$link_target")"
        if [ "$resolved" = "$SKILLS_SRC/$name" ]; then
            echo "installed"
        else
            echo "conflict"
        fi
    elif [ -e "$target" ]; then
        echo "conflict"
    else
        echo "not_installed"
    fi
}

do_install() {
    local name="$1"

    if ! skill_exists "$name"; then
        echo "  error: skill '$name' not found in repo"
        return 1
    fi

    mkdir -p "$SKILLS_DST"

    local status
    status="$(skill_status "$name")"

    case "$status" in
        installed)
            echo "  $name: already installed, skipping"
            ;;
        conflict)
            echo "  $name: conflict — something already exists at $SKILLS_DST/$name (not a symlink to this repo). Remove it manually to install."
            ;;
        not_installed)
            ln -s "$SKILLS_SRC/$name" "$SKILLS_DST/$name"
            echo "  $name: installed"
            ;;
    esac
}

do_uninstall() {
    local name="$1"
    local target="$SKILLS_DST/$name"

    local status
    status="$(skill_status "$name")"

    case "$status" in
        installed)
            rm "$target"
            echo "  $name: uninstalled"
            ;;
        conflict)
            echo "  $name: skipping — exists but doesn't point to this repo"
            ;;
        not_installed)
            echo "  $name: not installed, skipping"
            ;;
    esac
}

do_list() {
    echo "Skills in $(basename "$SCRIPT_DIR"):"
    echo ""
    for name in $(available_skills); do
        local status
        status="$(skill_status "$name")"
        case "$status" in
            installed)
                printf "  %-30s %s\n" "$name" "installed"
                ;;
            conflict)
                printf "  %-30s %s\n" "$name" "conflict (not managed by this repo)"
                ;;
            not_installed)
                printf "  %-30s %s\n" "$name" "not installed"
                ;;
        esac
    done
}

# --- Main ---

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

command="$1"
shift

case "$command" in
    install)
        if [ $# -gt 0 ]; then
            do_install "$1"
        else
            for name in $(available_skills); do
                do_install "$name"
            done
        fi
        ;;
    uninstall)
        if [ $# -gt 0 ]; then
            do_uninstall "$1"
        else
            for name in $(available_skills); do
                do_uninstall "$name"
            done
        fi
        ;;
    list)
        do_list
        ;;
    *)
        usage
        exit 1
        ;;
esac
