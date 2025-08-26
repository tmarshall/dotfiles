alias gcb="git checkout -b"
alias gcm="git commit --message"
alias gca="git commit --amend"
alias gcp="git cherry-pick"
alias ga="git add ."
alias gs="git status"
alias gd="git diff"
alias gch="git checkout"
alias gpo="git push origin"

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
