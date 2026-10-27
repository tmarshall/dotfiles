export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0=rerere.enabled
export GIT_CONFIG_VALUE_0=true

alias gcm="git commit --message"
alias gca="git commit --amend"
alias gcp="git cherry-pick"
alias ga="git add ."
alias gd="git diff"
alias gpo="git push origin"

# Worktree-aware git helpers. A branch can be checked out in only one worktree,
# and files flagged skip-worktree or assume-unchanged hide their edits from
# `git status` while still blocking a checkout, so these say why and recover.
unalias gs gch gcb 2>/dev/null

# Tracked files whose edits `git status` does not show.
_git_hidden_files() {
  git ls-files -v 2>/dev/null | grep -E '^([a-z]|S) ' | cut -c3-
}

_git_warn_hidden_files() {
  local hidden
  hidden=$(_git_hidden_files)
  [ -n "$hidden" ] || return 0
  echo "Hidden from git status (skip-worktree/assume-unchanged), and they still block a checkout:" >&2
  echo "$hidden" | sed 's/^/  /' >&2
  echo "Unhide with: git update-index --no-skip-worktree --no-assume-unchanged <file>" >&2
}

# The worktree that has local branch $1 checked out, if any.
_git_worktree_for_branch() {
  git worktree list --porcelain 2>/dev/null | awk -v ref="refs/heads/$1" '
    /^worktree / { dir = substr($0, 10) }
    $0 == "branch " ref { print dir; exit }'
}

gs() {
  git status "$@" && _git_warn_hidden_files
}

# `gch <branch>` moves to the worktree that already has the branch, instead of
# failing with "already used by worktree".
gch() {
  if [ $# -eq 1 ]; then
    local wt_dir
    wt_dir=$(_git_worktree_for_branch "$1")
    if [ -n "$wt_dir" ] && [ "$wt_dir" != "$(git rev-parse --show-toplevel 2>/dev/null)" ]; then
      echo "$1 is checked out in $wt_dir, moving there" >&2
      cd "$wt_dir" || return
      return 0
    fi
  fi
  git checkout "$@" && return 0
  local rc=$?
  _git_warn_hidden_files
  return $rc
}

# `gcb <branch> [start]`. --no-track, so a branch cut from origin/main does not
# track main, where a bare `git push` would then go.
gcb() {
  git checkout --no-track -b "$@"
}

# `gwt <branch> [start]` creates <branch> in a new worktree beside the main
# checkout (<repo>.worktrees/<branch>) and moves there. The start defaults to a
# freshly fetched origin default branch.
gwt() {
  if [ -z "${1:-}" ]; then
    echo "usage: gwt <branch> [start]" >&2
    return 2
  fi
  local main_dir start wt_dir
  main_dir=$(git worktree list --porcelain | awk '/^worktree / { print substr($0, 10); exit }')
  [ -n "$main_dir" ] || return 1
  start=${2:-}
  if [ -z "$start" ]; then
    git fetch --quiet origin || return
    start=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)
  fi
  wt_dir="$main_dir.worktrees/$(printf '%s' "$1" | tr '/' '-')"
  git worktree add --no-track -b "$1" "$wt_dir" "$start" && cd "$wt_dir"
}

alias py="python"

run() {
  repo_path=/workspace

  execscript() {
    local -a lines
    lines=("${(@)@/#/do script \"}")
    lines=("${lines[@]/%/\" in front window}")
    lines=$(printf "%s\n" "${lines[@]}")

    osascript <<SCRIPT
      tell application "Terminal" to activate
      tell application "Terminal"
        ${lines}
      end tell
SCRIPT
  }

  case $1 in
    www)
      cd $repo_path/www || return
      py manage.py runserver
      ;;

    shell)
      cd $repo_path/www || return
      execscript "py manage.py shell_plus"
      ;;

    fe)
      cd $repo_path/www/frontend || return
      npm run dev
      ;;

    migrate)
      cd $repo_path/www || return
      py manage.py migrate
      ;;
  esac
}
