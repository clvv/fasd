# This tool gives you quick access to your frequent/recent files
#
# INSTALL:
#   Source this file somewhere in your shell rc (.bashrc or .zshrc).
#
# SYNOPSIS:
#   f [options] [query ..]
#     options:
#       -s, --show       show list of files with their ranks
#       -l, --list       list paths only
#       -e, --exec CMD   set command to execute on the result file
#       -a, --any        match files and directories
#       -d, --directory  match directories only
#       -f, --file       match files only
#       -r, --rank       match by rank only
#       -h, --help       show a brief help message
#
# EXAMPLES:
#   f foo # list recent files mathcing foo
#   f foo bar # list recent files mathcing foo and bar
#   f -e vim foo # run vim on the most frecent file matching foo
#
# TIPS:
#   alias z="f -d -e cd"
#   alias v="f -e vim"
#   alias m="f -e mplayer"
#   alias o="f -e xdg-open"

_asdf() {

  if [ "$1" = "--add" ]; then # add entries
    shift

    # bail out if we don't own ~/.f (we're another user but our ENV is still set)
    [ -f "$_ASDF_DATA" -a ! -O "$_ASDF_DATA" ] && return

    # blacklists
    local each
    for each in "${_ASDF_BLACKLIST[@]}"; do
      [[ "$*" =~ "$each" ]] && return
    done

    # shifts
    for each in "${_ASDF_SHIFT[@]}"; do
      while [ "$1" = "$each" ]; do shift; done
    done

    # ignores
    [[ "${_ASDF_IGNORE[@]}" =~ "$1" ]] && return
    shift

    local FILES
    while [ "$1" ]; do
      # add the adsolute path of the file to FILES
      FILES+="$($_ASDF_READLINK -e "$1" 2>> "$_ASDF_SINK")|"
      shift
    done

    # add current pwd if the option set
    [ "$_ASDF_TRACK_PWD" -a "$(pwd -P)" != "$HOME" ] && FILES+="$(pwd -P)"

    [ -z "${FILES//|/}" ] && return # stop if we have nothing to add

    # maintain the file
    local tempfile
    tempfile="$(mktemp $_ASDF_DATA.XXXXXX)" || return
    $_ASDF_AWK -v list="$FILES" -v now="$(date +%s)" -F"|" '
      BEGIN {
        split(list, files, "|")
        for(i in files) {
          path = files[i]
          if ( path == "" ) continue
          paths[path] = path # array for checking
          rank[path] = 1
          time[path] = now
        }
      }
      $2 >= 1 {
        if( $1 in paths ) {
          rank[$1] = $2 + 1
          time[$1] = now
        } else {
          rank[$1] = $2
          time[$1] = $3
        }
        count += $2
      }
      END {
        if( count > 1000 )
          for( i in rank ) print i "|" 0.9*rank[i] "|" time[i] # aging
        else
          for( i in rank ) print i "|" rank[i] "|" time[i]
      }' "$_ASDF_DATA" 2>> "$_ASDF_SINK" >| "$tempfile"
    if [ $? -ne 0 -a -f "$_ASDF_DATA" ]; then
      env rm -f "$tempfile"
    else
      env mv -f "$tempfile" "$_ASDF_DATA"
    fi

  elif [ "$1" = "--query" ]; then
    # query the database, this need some local variables to be set
    while read line; do
      [ -${typ} "${line%%|*}" ] && echo "$line"
    done < "$_ASDF_DATA" | \
    $_ASDF_AWK -v t="$(date +%s)" -v mode="$mode" -v q="$fnd" -F"|" '
      function frecent(rank, time) {
        dx = t-time
        if( dx < 3600 ) return rank*4
        if( dx < 86400 ) return rank*2
        if( dx < 604800 ) return rank/2
        return rank/4
      }
      function likelihood(pattern, path) {
        m = gsub( "/+", "/", path )
        r = 1
        for( i in pattern ) {
          tmp = path
          gsub( ".*" pattern[i], "", tmp)
          n = gsub( "/+", "/", tmp )
          if( n == m )
            return 0
          else if( n == 0 )
            r *= 20 # F
          else
            r *= 1 - ( n / m )
        }
        return r
      }
      function getRank() {
        if( mode == "rank" )
          f = $2
        else
          f = frecent($2, $3)
        wcase[$1] = f * likelihood( pattern, $1 )
        nocase[$1] = f * likelihood( pattern2, tolower($1) )
      }
      BEGIN {
        split(q, pattern, " ")
        for( i in pattern ) pattern2[i] = tolower(pattern[i]) # nocase
      }
      {
        getRank()
        cx = cx || wcase[$1]
        ncx = ncx || nocase[$1]
      }
      END {
        if( cx ) {
          for( i in wcase )
            if( wcase[i] ) printf "%-10s %s\n", wcase[i], i
        } else if( ncx ) {
          for( i in nocase )
            if( nocase[i] ) printf "%-10s %s\n", nocase[i], i
        }
      }' - 2>> "$_ASDF_SINK"

  else
    # parsing logic and processing
    [ -f "$_ASDF_DATA" ] || return # no db yet
    local fnd; fnd=()
    while [ "$1" ]; do case "$1" in
      --complete) set -- $(echo $2); local list=1;;
      -h|--help) echo "f [options] [query ..]
      options:
        -s, --show       show list of files with their ranks
        -l, --list       list paths only
        -e, --exec CMD   set command to execute on the result file
        -a, --any        match files and directories
        -d, --directory  match directories only
        -f, --file       match files only
        -r, --rank       match by rank only
        -h, --help       show a brief help message" >&2; return;;
      -s|--show) local show=1;;
      -l|--list) local list=1;;
      -r|--rank) local mode="rank";;
      -t|--recent) local mode="recent";;
      -e|--exec) local exec=${2:?"Argument needed after -e"}; shift;;
      -a|--any) local typ="e";;
      -d|--directory) local typ="d";;
      -f|--file) local typ="f";;
      *) fnd+="$1 ";;
    esac; local last="$1"; shift; done

    [ "$typ" ] || local typ="e" # default to match file and directory

    # if we hit enter on a completion just execute
    case "$last" in
     # completions will always start with /
     /*) [ -z "$show$list" -a -${typ} "$last" ] && $exec "$last" && return;;
    esac

    local result
    result="$(_asdf --query 2>> "$_ASDF_SINK")" # query the database
    [ $? -gt 0 ] && return
    if [ "$list" ]; then
      echo "$result" | sort -n | sed 's/^[0-9.]*[ ]*//'
    elif [ "$show" ]; then
      echo "$result" | sort -n
    elif [ "$fnd" -a "$exec" ]; then
      $exec "$(echo "$result" | sort -n | sed 's/^[0-9.]*[ ]*//' | tail -n1)"
    elif [ "$fnd" ] && [ "$ZSH_SUBSHELL$BASH_SUBSHELL" -eq 1 ]; then # echo
      echo "$(echo "$result" | sort -n | sed 's/^[0-9.]*[ ]*//' | tail -n1)"
    else # no args, show
      echo "$result" | sort -n
    fi

  fi
}

# set default options
alias a=_asdf
alias s='_asdf -s'
alias f='_asdf -f'
alias d='_asdf -d'
[ -z "$_ASDF_DATA" ] && _ASDF_DATA="$HOME/.asdf"
[ -z "$_ASDF_BLACKLIST" ] && _ASDF_BLACKLIST=(--help)
[ -z "$_ASDF_SHIFT" ] && _ASDF_SHIFT=(sudo busybox)
[ -z "$_ASDF_IGNORE" ] && _ASDF_IGNORE=(_asdf ls echo)
[ -z "$_ASDF_SINK" ] && _ASDF_SINK=/dev/null

if [ -z "$_ASDF_AWK" ]; then
  # awk preferences
  for awk in gawk original-awk nawk mawk awk; do
    $awk "" 2>1 >> "$_ASDF_SINK" && _ASDF_AWK=$awk && break
  done
fi

if readlink -e / 2>1 >> "$_ASDF_SINK"; then
  _ASDF_READLINK=readlink
elif greadlink -e / 2>1 >> "$_ASDF_SINK"; then
  _ASDF_READLINK=greadlink
else # fall back on emulated readlink
  _asdf_readlink() {
    # function that mimics readlink from GNU coreutils
    [ "$1" = "-e" ] && shift && local e=1 # existence option
    [ "$1" = "/" ] && echo / && return
    [ "$1" = "." ] && echo "$(pwd -P)" && return
    local path
    if [ "${1##*/}" = ".." ]; then
      path="$(cd "$1" 2>1 >> "$_ASDF_SINK" && pwd -P)"
      [ -z "$path" ] && return 1 # if cd fails
    elif [[ "${1#/}" =~ "/" ]]; then
      # if target contains "/" (not counting top level) or target is ".."
      local base="$(cd "${1%/*}" 2>1 >> "$_ASDF_SINK" && pwd -P)"
      [ -z "$base" ] && return 1 # if cd fails
      path="${base%/}/${1##*/}"
    elif [ -z "${1##/*}" ]; then # straight top level
      path="$1"
    else # anything within where we are
      path="$(pwd -P)"'/'"$1"
    fi
    [ "$path" = "/" ] && echo / && return
    path=${path%/} # strip off trailing "/"
    [ "$e" = "1" -a ! -e "$path" ] && return
    echo "$path"
  }
  _ASDF_READLINK=_asdf_readlink
fi

if compctl 2>1 >> "$_ASDF_SINK"; then
  # zsh tab completion
  _asdf_zsh_tab_completion() {
    local compl
    read -c compl
    reply=(${(f)"$(_asdf --complete "$compl")"})
  }
  compctl -U -K _asdf_zsh_tab_completion _asdf
  # add zsh hook
  autoload -U add-zsh-hook
  function _asdf_preexec () { eval "_asdf --add $3" 2>1 >> "$_ASDF_SINK"; }
  add-zsh-hook preexec _asdf_preexec
elif complete 2>1 >> "$_ASDF_SINK"; then
  # bash tab completion
  _asdf_bash_completion() {
    # get completion results using expanded aliases
    local RESULT=$( _asdf --complete "$(alias -p ${COMP_WORDS} | \
      tail -n1 | sed -n "s/^.*'\(.*\)'/\1/p") ${COMP_LINE#* }" )
    local IFS=$'\n'
    COMPREPLY=( $RESULT )
  }
  _asdf_bash_hook_completion() {
    for cmd in $*; do
      complete -F _asdf_bash_completion $cmd
    done
  }
  _asdf_bash_hook_completion a s d f
  # add bash hook
  echo $PROMPT_COMMAND | grep -q "_asdf --add"
  [ $? -gt 0 ] && PROMPT_COMMAND='eval "_asdf --add $(history 1 | \
    sed -e "s/^[ ]*[0-9]*[ ]*//")" 2>1 >> "$_ASDF_SINK";'"$PROMPT_COMMAND"
fi
