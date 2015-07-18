#!/bin/sh


# prompt
function parse_git_branch () {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/ | \1$(parse_git_dirty)/"
}

function parse_git_dirty () {
  [[ $(git status 2> /dev/null | tail -n1) != "nothing to commit (working directory clean)" ]] && echo "*"
}

RED="\[\033[0;31m\]"
YELLOW="\[\033[0;33m\]"
GREEN="\[\033[0;32m\]"
NO_COLOUR="\[\033[0m\]"

#\u = user
#\w = PWD
export PROMPT_COMMAND='echo -ne "\033]0;${PWD/#$HOME/~}\007"'
PS1="$YELLOW\u$NO_COLOUR:\w$GREEN\$(parse_git_branch)$NO_COLOUR\n$ "

#aliases and functions
# Some directory listing with colors
  alias sl=ls
  alias ls='ls -G'        # Compact view, show colors
  alias la='ls -AF'       # Compact view, show hidden
  alias ll='ls -al'
  alias l='ls -a'
  alias l1='ls -1'

  # Usefull stuff for presentation and seeing dotfiles
  alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
  alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"
  alias showall='defaults write com.apple.finder AppleShowAllFiles YES && killall Finder'
  alias hideall='defaults write com.apple.finder AppleShowAllFiles NO && killall Finder'

# Get rid of those pesky .DS_Store files recursively
  alias dsclean='find . -type f -name .DS_Store -print0 | xargs -0 rm'

# Flush your dns cache
  alias flush='dscacheutil -flushcache'


  # Because Typing python -m SimpleHTTPServer is too Damn Long
# Start an HTTP server from a directory, optionally specifying the port
  function server() {
    local port="${1:-8000}"
#    open "http://localhost:${port}/"
    open -a google\ chrome\ canary "http://localhost:${port}/" --args --disable-web-security
    # Set the default Content-Type to `text/plain` instead of `application/octet-stream`
  # And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
    python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
  }


  function download(){
  curl -O "$1"
}


alias dl=download


# incase i forget how to clear
  alias c='clear'
  alias k='clear'
  alias cls='clear'


  # archive file or folder
  function compress()
  {
      dirPriorToExe=`pwd`
      dirName=`dirname $1`
      baseName=`basename $1`

      if [ -f $1 ] ; then
          echo "It was a file change directory to $dirName"
          cd $dirName
          case $2 in
            tar.bz2)
                      tar cjf $baseName.tar.bz2 $baseName
                      ;;
            tar.gz)
                      tar czf $baseName.tar.gz $baseName
                      ;;
            gz)
                      gzip $baseName
                      ;;
            tar)
                      tar -cvvf $baseName.tar $baseName
                      ;;
            zip)
                      zip -r $baseName.zip $baseName
                      ;;
              *)
                      echo "Method not passed compressing using tar.bz2"
                      tar cjf $baseName.tar.bz2 $baseName
                      ;;
          esac
          echo "Back to Directory $dirPriorToExe"
          cd $dirPriorToExe
      else
          if [ -d $1 ] ; then
              echo "It was a Directory change directory to $dirName"
              cd $dirName
              case $2 in
                  tar.bz2)
                          tar cjf $baseName.tar.bz2 $baseName
                          ;;
                  tar.gz)
                          tar czf $baseName.tar.gz $baseName
                          ;;
                  gz)
                          gzip -r $baseName
                          ;;
                  tar)
                          tar -cvvf $baseName.tar $baseName
                          ;;
                  zip)
                          zip -r $baseName.zip $baseName
                          ;;
                  *)
                      echo "Method not passed compressing using tar.bz2"
                  tar cjf $baseName.tar.bz2 $baseName
                          ;;
              esac
              echo "Back to Directory $dirPriorToExe"
              cd $dirPriorToExe
          else
              echo "'$1' is not a valid file/folder"
          fi
      fi
      echo "Done"
      echo "###########################################"
  }

# Extract archives - use: extract <file>
# Based on http://dotfiles.org/~pseup/.bashrc
function extract() {
  local remove_archive
  local success
  local file_name
  local extract_dir

  if (( $# == 0 )); then
    echo "Usage: extract [-option] [file ...]"
    echo
    echo Options:
    echo "    -r, --remove    Remove archive."
  fi

  remove_archive=1
  if [[ "$1" == "-r" ]] || [[ "$1" == "--remove" ]]; then
    remove_archive=0
    shift
  fi

  while (( $# > 0 )); do
    if [[ ! -f "$1" ]]; then
      echo "extract: '$1' is not a valid file" 1>&2
      shift
      continue
    fi

    success=0
    file_name="$( basename "$1" )"
    extract_dir="$( echo "$file_name" | sed "s/\.${1##*.}//g" )"
    case "$1" in
      (*.tar.gz|*.tgz) [ -z $commands[pigz] ] && tar zxvf "$1" || pigz -dc "$1" | tar xv ;;
      (*.tar.bz2|*.tbz|*.tbz2) tar xvjf "$1" ;;
      (*.tar.xz|*.txz) tar --xz --help &> /dev/null \
        && tar --xz -xvf "$1" \
        || xzcat "$1" | tar xvf - ;;
      (*.tar.zma|*.tlz) tar --lzma --help &> /dev/null \
        && tar --lzma -xvf "$1" \
        || lzcat "$1" | tar xvf - ;;
      (*.tar) tar xvf "$1" ;;
      (*.gz) [ -z $commands[pigz] ] && gunzip "$1" || pigz -d "$1" ;;
      (*.bz2) bunzip2 "$1" ;;
      (*.xz) unxz "$1" ;;
      (*.lzma) unlzma "$1" ;;
      (*.Z) uncompress "$1" ;;
      (*.zip|*.war|*.jar|*.sublime-package) unzip "$1" -d $extract_dir ;;
      (*.rar) unrar x -ad "$1" ;;
      (*.7z) 7za x "$1" ;;
      (*.deb)
        mkdir -p "$extract_dir/control"
        mkdir -p "$extract_dir/data"
        cd "$extract_dir"; ar vx "../${1}" > /dev/null
        cd control; tar xzvf ../control.tar.gz
        cd ../data; tar xzvf ../data.tar.gz
        cd ..; rm *.tar.gz debian-binary
        cd ..
      ;;
      (*)
        echo "extract: '$1' cannot be extracted" 1>&2
        success=1
      ;;
    esac

    (( success = $success > 0 ? $success : $? ))
    (( $success == 0 )) && (( $remove_archive == 0 )) && rm "$1"
    shift
  done
}

alias x=extract