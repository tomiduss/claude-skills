#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------------
# Resolve the real location of this script, even when invoked via a symlink
# (e.g. ~/.local/bin/my-skills -> /path/to/repo/skills.sh). We can't rely on
# `readlink -f` because macOS ships the BSD readlink without -f, so we walk
# the symlink chain ourselves.
# ----------------------------------------------------------------------------
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "$SOURCE")"
SKILLS_SRC="$SCRIPT_DIR/skills"

# Hidden file placed inside copy-installed skill directories so we can tell
# them apart from unrelated directories and know where to pull updates from.
SOURCE_MARKER=".skill-source"

# Scope destinations. Project scope is based on the caller's working directory
# at invocation time — that's where they expect `.claude/skills/` to live.
USER_DST="$HOME/.claude/skills"
PROJECT_DST="$(pwd)/.claude/skills"

# PATH install target. Override with MY_SKILLS_BIN_DIR if you keep your
# personal scripts elsewhere.
BIN_DIR="${MY_SKILLS_BIN_DIR:-$HOME/.local/bin}"
BIN_NAME="my-skills"

usage() {
    cat <<EOF
Usage: my-skills <command> [flags] [skill-name]

Commands:
  install [name]     Install skill(s) — symlink by default, or --copy
  uninstall [name]   Remove managed skills (links and copies)
  update [name]      Re-copy skills that were installed with --copy
  list               Show status of all skills in the chosen scope
  setup              Symlink this script into \$PATH as '$BIN_NAME'
  doctor             Report resolved paths and whether '$BIN_NAME' is on \$PATH
  help               Show this message

Install mode:
  --copy, -c         Deep-copy instead of symlink (portable, git-committed)
                     Without --copy, install creates a symlink (auto-updates)

Scope flags (for install / uninstall / update / list):
  --user, -u         Target \$HOME/.claude/skills          (default)
  --project, -p      Target <cwd>/.claude/skills           (the current repo)
  --both             Target both user and project scopes

If no [name] is given, the command operates on every skill in this repo.

Examples:
  my-skills install                            # symlink all → user scope
  my-skills install --project --copy qa-testing  # copy into current project
  my-skills update --project                   # refresh all copies in project
  my-skills uninstall -p qa-testing
  my-skills list --both
  my-skills setup                              # make 'my-skills' work anywhere
  my-skills doctor

Environment:
  MY_SKILLS_BIN_DIR  Where 'setup' installs the launcher (default: ~/.local/bin)
EOF
}

# ---------- skill discovery -------------------------------------------------

available_skills() {
    for dir in "$SKILLS_SRC"/*/; do
        [ -d "$dir" ] && basename "$dir"
    done
}

skill_exists() {
    [ -d "$SKILLS_SRC/$1" ]
}

# skill_status <name> <dst_dir>
#   linked         -> symlink pointing at $SKILLS_SRC/<name>
#   copied         -> directory with a .skill-source marker pointing at our repo
#   conflict       -> something exists but isn't managed by us
#   not_installed  -> nothing there
skill_status() {
    local name="$1"
    local dst="$2"
    local target="$dst/$name"

    if [ -L "$target" ]; then
        # It's a symlink — check whether it points at our repo.
        local link_target
        link_target="$(readlink "$target")"
        local resolved
        if [[ "$link_target" = /* ]]; then
            resolved="$link_target"
        else
            resolved="$(cd "$dst" 2>/dev/null && cd "$(dirname "$link_target")" 2>/dev/null && pwd)/$(basename "$link_target")"
        fi
        if [ "$resolved" = "$SKILLS_SRC/$name" ]; then
            echo "linked"
        else
            echo "conflict"
        fi
    elif [ -d "$target" ] && [ -f "$target/$SOURCE_MARKER" ]; then
        # It's a directory with our marker — verify the marker points here.
        local marker_content
        marker_content="$(cat "$target/$SOURCE_MARKER")"
        if [ "$marker_content" = "$SKILLS_SRC/$name" ]; then
            echo "copied"
        else
            echo "conflict"
        fi
    elif [ -e "$target" ]; then
        echo "conflict"
    else
        echo "not_installed"
    fi
}

# ---------- install / uninstall / update / list -----------------------------

do_install() {
    local name="$1"
    local dst="$2"
    local scope="$3"
    local copy_mode="$4"  # 0 = symlink, 1 = copy

    if ! skill_exists "$name"; then
        echo "  [$scope] error: skill '$name' not found in repo"
        return 1
    fi

    mkdir -p "$dst"

    local status
    status="$(skill_status "$name" "$dst")"

    case "$status" in
        linked)
            if [ "$copy_mode" -eq 1 ]; then
                echo "  [$scope] $name: already linked — uninstall first to switch to a copy"
            else
                echo "  [$scope] $name: already linked, skipping"
            fi
            ;;
        copied)
            if [ "$copy_mode" -eq 0 ]; then
                echo "  [$scope] $name: already copied — uninstall first to switch to a symlink"
            else
                echo "  [$scope] $name: already copied, skipping (use 'update' to refresh)"
            fi
            ;;
        conflict)
            echo "  [$scope] $name: conflict — $dst/$name exists and is not managed by this repo. Remove it manually to install."
            ;;
        not_installed)
            if [ "$copy_mode" -eq 1 ]; then
                cp -R "$SKILLS_SRC/$name" "$dst/$name"
                echo "$SKILLS_SRC/$name" > "$dst/$name/$SOURCE_MARKER"
                echo "  [$scope] $name: copied"
            else
                ln -s "$SKILLS_SRC/$name" "$dst/$name"
                echo "  [$scope] $name: linked"
            fi
            ;;
    esac
}

do_uninstall() {
    local name="$1"
    local dst="$2"
    local scope="$3"
    local target="$dst/$name"

    local status
    status="$(skill_status "$name" "$dst")"

    case "$status" in
        linked)
            rm "$target"
            echo "  [$scope] $name: uninstalled (was linked)"
            ;;
        copied)
            rm -rf "$target"
            echo "  [$scope] $name: uninstalled (was copied)"
            ;;
        conflict)
            echo "  [$scope] $name: skipping — exists but not managed by this repo"
            ;;
        not_installed)
            echo "  [$scope] $name: not installed, skipping"
            ;;
    esac
}

do_update() {
    local name="$1"
    local dst="$2"
    local scope="$3"
    local target="$dst/$name"

    if ! skill_exists "$name"; then
        echo "  [$scope] error: skill '$name' not found in repo"
        return 1
    fi

    local status
    status="$(skill_status "$name" "$dst")"

    case "$status" in
        linked)
            echo "  [$scope] $name: linked — always up to date"
            ;;
        copied)
            rm -rf "$target"
            cp -R "$SKILLS_SRC/$name" "$target"
            echo "$SKILLS_SRC/$name" > "$target/$SOURCE_MARKER"
            echo "  [$scope] $name: updated"
            ;;
        conflict)
            echo "  [$scope] $name: skipping — exists but not managed by this repo"
            ;;
        not_installed)
            echo "  [$scope] $name: not installed, skipping"
            ;;
    esac
}

do_list() {
    local dst="$1"
    local scope="$2"

    echo "Skills from $SCRIPT_DIR  [$scope → $dst]"
    echo ""
    for name in $(available_skills); do
        local status
        status="$(skill_status "$name" "$dst")"
        case "$status" in
            linked)
                printf "  %-32s %s\n" "$name" "linked"
                ;;
            copied)
                printf "  %-32s %s\n" "$name" "copied"
                ;;
            conflict)
                printf "  %-32s %s\n" "$name" "conflict (not managed by this repo)"
                ;;
            not_installed)
                printf "  %-32s %s\n" "$name" "not installed"
                ;;
        esac
    done
}

# ---------- setup / doctor --------------------------------------------------

bin_dir_on_path() {
    case ":$PATH:" in
        *":$BIN_DIR:"*) return 0 ;;
        *) return 1 ;;
    esac
}

launcher_points_here() {
    local where
    where="$(command -v "$BIN_NAME" 2>/dev/null || true)"
    [ -n "$where" ] || return 1

    local src="$where"
    while [ -L "$src" ]; do
        local d link
        d="$(cd -P "$(dirname "$src")" && pwd)"
        link="$(readlink "$src")"
        [[ "$link" != /* ]] && link="$d/$link"
        src="$link"
    done
    [ "$src" = "$SCRIPT_PATH" ]
}

do_setup() {
    mkdir -p "$BIN_DIR"
    local target="$BIN_DIR/$BIN_NAME"

    if [ -L "$target" ]; then
        local existing
        existing="$(readlink "$target")"
        if [ "$existing" = "$SCRIPT_PATH" ]; then
            echo "  $BIN_NAME: already linked at $target"
        else
            echo "  $BIN_NAME: a symlink already exists at $target → $existing"
            echo "  Remove it manually and rerun 'setup', or set MY_SKILLS_BIN_DIR to another directory."
            return 1
        fi
    elif [ -e "$target" ]; then
        echo "  $BIN_NAME: something (not a symlink) already exists at $target"
        echo "  Remove it manually and rerun 'setup'."
        return 1
    else
        ln -s "$SCRIPT_PATH" "$target"
        echo "  $BIN_NAME: linked $target → $SCRIPT_PATH"
    fi

    echo ""
    if command -v "$BIN_NAME" >/dev/null 2>&1; then
        echo "  ✓ '$BIN_NAME' is callable from your shell"
    elif bin_dir_on_path; then
        echo "  ✓ $BIN_DIR is on \$PATH, but '$BIN_NAME' isn't resolving yet."
        echo "    Open a new shell (or run: hash -r) and try again."
    else
        echo "  ⚠ $BIN_DIR is not on \$PATH. Add this line to ~/.zshrc (or ~/.bashrc):"
        echo ""
        echo "      export PATH=\"$BIN_DIR:\$PATH\""
        echo ""
        echo "    Then open a new shell and rerun 'my-skills doctor' to confirm."
    fi
}

do_doctor() {
    echo "Paths"
    echo "  script path     : $SCRIPT_PATH"
    echo "  script dir      : $SCRIPT_DIR"
    echo "  skills source   : $SKILLS_SRC"
    echo "  user scope dst  : $USER_DST"
    echo "  project scope   : $PROJECT_DST"
    echo "  bin dir         : $BIN_DIR"
    echo ""
    echo "PATH"
    if command -v "$BIN_NAME" >/dev/null 2>&1; then
        local where
        where="$(command -v "$BIN_NAME")"
        if launcher_points_here; then
            echo "  ✓ '$BIN_NAME' is on \$PATH → $where (points at this repo)"
        else
            echo "  ⚠ '$BIN_NAME' is on \$PATH → $where"
            echo "    but it does NOT resolve to $SCRIPT_PATH."
            echo "    Another skills.sh is winning the PATH race."
        fi
    else
        echo "  ✗ '$BIN_NAME' is not on \$PATH"
        echo "    Fix it with:  bash $SCRIPT_PATH setup"
    fi
}

# ---------- argument parsing ------------------------------------------------

SCOPE="user"
COPY_MODE=0

# parse_flag returns 0 if the arg was recognized (and sets the relevant
# global), 1 otherwise — so the caller can collect non-flag args.
parse_flag() {
    case "$1" in
        --user|-u)    SCOPE="user";    return 0 ;;
        --project|-p) SCOPE="project"; return 0 ;;
        --both)       SCOPE="both";    return 0 ;;
        --copy|-c)    COPY_MODE=1;     return 0 ;;
        *) return 1 ;;
    esac
}

scope_dst() {
    case "$1" in
        user)    echo "$USER_DST" ;;
        project) echo "$PROJECT_DST" ;;
    esac
}

# ---------- main ------------------------------------------------------------

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

command="$1"
shift

# Consume flags from anywhere in the remaining args so that flag order
# doesn't matter:  my-skills install --project --copy qa-testing
#              and my-skills install qa-testing --project --copy
# both work.
remaining=()
while [ $# -gt 0 ]; do
    if parse_flag "$1"; then
        :
    else
        remaining+=("$1")
    fi
    shift
done
# Bash 3.2 (macOS default) chokes on "${empty_array[@]}" under `set -u`,
# so guard the reassignment.
if [ ${#remaining[@]} -gt 0 ]; then
    set -- "${remaining[@]}"
else
    set --
fi

# Expand SCOPE into the list of scopes we'll iterate over.
case "$SCOPE" in
    user)    scopes=("user") ;;
    project) scopes=("project") ;;
    both)    scopes=("user" "project") ;;
esac

case "$command" in
    install)
        for scope in "${scopes[@]}"; do
            dst="$(scope_dst "$scope")"
            if [ $# -gt 0 ]; then
                do_install "$1" "$dst" "$scope" "$COPY_MODE"
            else
                for name in $(available_skills); do
                    do_install "$name" "$dst" "$scope" "$COPY_MODE"
                done
            fi
        done
        ;;
    uninstall)
        for scope in "${scopes[@]}"; do
            dst="$(scope_dst "$scope")"
            if [ $# -gt 0 ]; then
                do_uninstall "$1" "$dst" "$scope"
            else
                for name in $(available_skills); do
                    do_uninstall "$name" "$dst" "$scope"
                done
            fi
        done
        ;;
    update)
        for scope in "${scopes[@]}"; do
            dst="$(scope_dst "$scope")"
            if [ $# -gt 0 ]; then
                do_update "$1" "$dst" "$scope"
            else
                for name in $(available_skills); do
                    do_update "$name" "$dst" "$scope"
                done
            fi
        done
        ;;
    list)
        first=1
        for scope in "${scopes[@]}"; do
            dst="$(scope_dst "$scope")"
            [ $first -eq 1 ] || echo ""
            do_list "$dst" "$scope"
            first=0
        done
        ;;
    setup)
        do_setup
        ;;
    doctor)
        do_doctor
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        usage
        exit 1
        ;;
esac
