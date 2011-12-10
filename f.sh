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
#       -t, --recent     match by recent access only
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

_f() {

  if [ "$1" = "--add" ]; then # add entries
    shift

    # blacklists
    local each
    for each in "${_F_BLACKLIST[@]}"; do
      [[ "$*" =~ "$each" ]] && return
    done

    # shifts
    for each in "${_F_SHIFT[@]}"; do
      while [ "$1" = "$each" ]; do shift; done
    done

    # ignores
    [[ "${_F_IGNORE[@]}" =~ "$1" ]] && return
    shift

    local FILES
    while [ "$1" ]; do
      # add the adsolute path of the file to FILES
      FILES+="$($_F_READLINK -e "$1" 2>/dev/null)"$'\n'
      shift
    done

    # add current pwd if the option set
    [ "$_F_TRACK_PWD" ] && FILES+="$(pwd -P)"

    # bail out if we don't own ~/.f (we're another user but our ENV is still set)
    [ -f "$_F_DATA" -a ! -O "$_F_DATA" ] && return
    [ -z "${FILES//$'\n'/}" ] && return # stop if we have nothing to add

    # maintain the file
    local tempfile
    tempfile="$(mktemp $_F_DATA.XXXXXX)" || return
    $_F_AWK -v list="$FILES" -v now="$(date +%s)" -F"|" '
      BEGIN {
        split(list, files, "\n")
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
        if( count > 1000 ) {
          for( i in rank ) print i "|" 0.9*rank[i] "|" time[i] # aging
        } else for( i in rank ) print i "|" rank[i] "|" time[i]
      }
    ' "$_F_DATA" 2>/dev/null >| "$tempfile"
    if [ $? -ne 0 -a -f "$_F_DATA" ]; then
      env rm -f "$tempfile"
    else
      env mv -f "$tempfile" "$_F_DATA"
    fi

  # tab completion
  elif [ "$1" = "--complete" ]; then
    $_F_AWK -v q="$2" -v knownFile="$_F_DATA" -F"|" '
      function exists(path, type,    tmp, ret) {
        ret = 0
        if ( type != "d" ) {
          if ( (getline tmp < path) >= 0 ) {
            # type gawk busybox nawk
            #   f    1       1    1
            #   d   -1      -1    0
            close(path)
            if ( type == "" || type == "e" ) return 1
            ret = 1
          }
        }
        n = gsub("/+", "/", path)
        for ( i = 0; i < n; i++ )
          path = path "/.."
        path = path knownFile
        if ( ( getline tmp < path ) >= 0 ) {
          # type gawk busybox nawk
          # f      0       0    0
          # d      1       1    1
          close(path)
          if ( type == "f" )
            return 0
          else
            return 1
        }
        return ret
      }
      BEGIN {
        if( q == tolower(q) ) nocase = 1
        split(substr(q,3),fnd," ")
      } {
        if( !exists($1) ) next
        if( nocase ) {
          for( i in fnd ) tolower($1) !~ tolower(fnd[i]) && $1 = ""
        } else {
          for( i in fnd ) $1 !~ fnd[i] && $1 = ""
        }
        if( $1 ) print $1
      }
   ' "$_F_DATA" 2>/dev/null

  else # list/exec

    local fnd; fnd=()
    while [ "$1" ]; do case "$1" in
      -h|--help) echo "f [options] [query ..]
      options:
        -s, --show       show list of files with their ranks
        -l, --list       list paths only
        -e, --exec CMD   set command to execute on the result file
        -a, --any        match files and directories
        -d, --directory  match directories only
        -f, --file       match files only
        -r, --rank       match by rank only
        -t, --recent     match by recent access only
        -h, --help       show a brief help message" >&2; return;;
      -s|--show) local show=1; shift;;
      -l|--list) local list=1; shift;;
      -r|--rank) local mode="rank"; shift;;
      -t|--recent) local mode="recent"; shift;;
      -e|--exec) local exec=${2:?"Argument needed after -e"}; shift 2;;
      -a|--any) local typ="e"; shift;;
      -d|--directory) local typ="d"; shift;;
      -f|--file) local typ="f"; shift;;
      *) fnd+=("$1"); shift;;
    esac; done

    [ "$fnd" -a "$exec" ] || { [ -z "$list" ] && local show=1 ; }
    [ "$typ" ] || local typ="e" # default to match file and directory

    # if we hit enter on a completion just go there
    [ "$fnd" ] && case "${fnd[-1]}" in
     # completions will always start with /
     /*) [ -z "$show$list" -a -${typ} "${fnd[-1]}" ] \
       && "$exec" "${fnd[-1]}" && return;;
    esac

    # no db yet
    [ -f "$_F_DATA" ] || return

    local result
    result="$($_F_AWK -v t="$(date +%s)" -v knownFile="$_F_DATA" -v \
      list="$show$list" -v mode="$mode" -v typ="$typ" -v q="$fnd" -F"|" '
      function frecent(rank, time) {
        dx = t-time
        if( dx < 3600 ) return rank*4
        if( dx < 86400 ) return rank*2
        if( dx < 604800 ) return rank/2
        return rank/4
      }
      function output(files, toopen, override) {
        if( list ) {
          if( mode == "recent" ) {
            cmd = "sort -nr"
          } else cmd = "sort -n"
          for( i in files ) if( files[i] ) printf "%-10s %s\n", files[i], i | cmd
          if( override ) printf "%-10s %s\n", "common:", override
        } else {
          if( override ) toopen = override
            print toopen
        }
      }
      function common(matches) {
        # shortest match
        for( i in matches ) {
          if( matches[i] && (!short || length(i) < length(short)) ) short = i
        }
        if( short == "/" ) return
        # shortest match must be common to each match
        for( i in matches ) if( matches[i] && i !~ short ) return
        return short
      }
      function exists(path, type,    tmp, ret) {
        ret = 0
        if ( type != "d" ) {
          if ( (getline tmp < path) >= 0 ) {
            # type gawk busybox nawk
            #   f    1       1    1
            #   d   -1      -1    0
            close(path)
            if ( type == "" || type == "e" ) return 1
            ret = 1
          }
        }
        n = gsub("/+", "/", path)
        for ( i = 0; i < n; i++ )
          path = path "/.."
        path = path knownFile
        if ( ( getline tmp < path ) >= 0 ) {
          # type gawk busybox nawk
          # f      0       0    0
          # d      1       1    1
          close(path)
          if ( type == "f" )
            return 0
          else
            return 1
        }
        return ret
      }
      BEGIN { split(q, a, " ") }
      {
        if( !exists($1, typ) ) next
        if( mode == "rank" ) {
          f = $2
        } else if( mode == "recent" ) {
          f = t-$3
        } else f = frecent($2, $3)
        wcase[$1] = nocase[$1] = f
        for( i in a ) {
          if( $1 !~ a[i] ) delete wcase[$1]
          if( tolower($1) !~ tolower(a[i]) ) delete nocase[$1]
        }
        if( wcase[$1] > oldf ) {
          cx = $1
          oldf = wcase[$1]
        } else if( nocase[$1] > noldf ) {
          ncx = $1
          noldf = nocase[$1]
        }
      }
      END {
        if( cx ) {
          output(wcase, cx, common(wcase))
        } else if( ncx ) output(nocase, ncx, common(nocase))
      }
    ' "$_F_DATA")" 2> /dev/null
    [ $? -gt 0 ] && return
    if [ -e "$result" ]; then
      $exec "$result"
    elif [ -z "$list" ]; then # show
      echo "$result"
    else # list
      echo "$result" | grep -v -e "^common" | sort -nr | awk '{print $2}'
    fi

  fi
}

# set default options
alias ${_F_CMD:=f}=_f
[ -z "$_F_DATA" ] && _F_DATA="$HOME/.f"
[ -z "$_F_BLACKLIST" ] && _F_BLACKLIST=(--help)
[ -z "$_F_SHIFT" ] && _F_SHIFT=(sudo busybox)
[ -z "$_F_IGNORE" ] && _F_IGNORE=(_f $_F_CMD ls echo)

if [ -z "$_F_AWK" ]; then
  if awk -Wversion |& grep -q mawk; then
    # f is not compatible with mawk
    if gawk &> /dev/null; then
      _F_AWK=gawk
    elif nawk &> /dev/null; then
      _F_AWK=nawk
    elif original-awk &> /dev/null; then
      _F_AWK=original-awk
    else
      echo "Sorry, but f is not compatible with mawk at the moment."
      echo "Please install gawk, nawk(orignal-awk for debian-like) or busybox awk"
      _F_AWK=mawk
    fi
  else # trust the default awk
    _F_AWK=awk
  fi
fi

if readlink -e / &> /dev/null; then
  _F_READLINK=readlink
elif greadlink -e / &> /dev/null; then
  _F_READLINK=greadlink
else # fall back on emulated readlink
  _f_readlink() {
    # function that mimics readlink from GNU coreutils
    [ "$1" = "-e" ] && shift && local e=1 # existence option
    [ "$1" = "/" ] && echo / && return
    [ "$1" = "." ] && echo "$(pwd -P)" && return
    local path
    if [ "${1##*/}" = ".." ]; then
      path="$(cd "$1" &>/dev/null && pwd -P)"
      [ -z "$path" ] && return 1 # if cd fails
    elif [[ "${1#/}" =~ "/" ]]; then
      # if target contains "/" (not counting top level) or target is ".."
      local base="$(cd "${1%/*}" &>/dev/null && pwd -P)"
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
  _F_READLINK=_f_readlink
fi

if compctl &> /dev/null; then
  # zsh tab completion
  _f_zsh_tab_completion() {
    local compl
    read -l compl
    reply=(${(f)"$(_f --complete "$compl")"})
  }
  compctl -U -K _f_zsh_tab_completion _f
  # add zsh hook
  autoload -U add-zsh-hook
  function _f_preexec () { eval "_f --add $3" &>/dev/null; }
  add-zsh-hook preexec _f_preexec
elif complete &> /dev/null; then
  # bash tab completion
  complete -C '_f --complete "$COMP_LINE"' $_F_CMD
  # add bash hook
  echo $PROMPT_COMMAND | grep -q "_f --add"
  [ $? -gt 0 ] && PROMPT_COMMAND='eval "_f --add $(history 1 | \
    sed -e "s/^[ ]*[0-9]*[ ]*//g")" &>/dev/null;'"$PROMPT_COMMAND"
fi
