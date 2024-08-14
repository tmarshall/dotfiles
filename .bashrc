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
    lines=("${@[@]/#/do script \"}")
    lines=("${lines[@]/%/\" in front window}")
    lines=$(IFS=$'\n'; echo "${lines[*]}")

    osascript <<SCRIPT
      tell application "Terminal" to activate
      tell application "Terminal"
        ${lines[*]}
      end tell
SCRIPT
  }

  case $1 in

    # `run www` just spins up the www server
    www)
      cd $repo_path/www
      py manage.py runserver
      ;;

    # `run shell` kicks open an interactive shell, with some initial imports
    shell)
      cd $repo_path/www
      execscript "py manage.py shell_plus"
      ;;

    # `run fe` runs the webpack dev server
    fe)
      cd $repo_path/www/frontend
      npm run dev
      ;;

    # `run migrate` to run pending migrations
    migrate)
      cd $repo_path/www
      py manage.py migrate
      ;;
  
  esac
}