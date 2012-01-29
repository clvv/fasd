#!/usr/bin/env sh
# This tool gives you quick access to your frequent/recent files
#
# INSTALL:
#   Source this file somewhere in your shell rc (.bashrc or .zshrc).
#
# SYNOPSIS:
#   _f [options] [query ...]
#     options:
#       -s        show list of files with their ranks
#       -l        list paths only
#       -i        interactive mode
#       -e <cmd>  set command to execute on the result file
#       -a        match files and directories
#       -d        match directories only
#       -f        match files only
#       -r        match by rank only
#       -h        show a brief help message
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

  case "$1" in
  --init)
    # set default options
    [ -z "$_F_DATA" ] && _F_DATA="$HOME/.f"
    [ -z "$_F_BLACKLIST" ] && _F_BLACKLIST="--help"
    [ -z "$_F_SHIFT" ] && _F_SHIFT="sudo busybox"
    [ -z "$_F_IGNORE" ] && _F_IGNORE="_f cd ls echo"
    [ -z "$_F_SINK" ] && _F_SINK=/dev/null
    [ -z "$_F_TRACK_PWD" ] && _F_TRACK_PWD=1
    [ -z "$_F_MAX" ] && _F_MAX=2000
    [ -z "$_F_QUERY_SEPARATOR" ] && _F_QUERY_SEPARATOR=,

    { if [ -z "$_F_AWK" ]; then
        # awk preferences
        for awk in gawk original-awk nawk mawk awk; do
          $awk "" && _F_AWK=$awk && break
        done
      fi
    } >> "$_F_SINK" 2>&1
    ;;

  --init-interactive)
    { # set default aliases
      alias ${_F_CMD_A:=a}='_f -a'
      alias ${_F_CMD_S:=s}='_f -s'
      alias ${_F_CMD_D:=d}='_f -d'
      alias ${_F_CMD_F:=f}='_f -f'

      if compctl; then # zsh
        _f --init-zsh
      elif complete; then # bash
        _f --init-bash
      else # posix shell
        _f --init-posix
      fi
    } >> "$_F_SINK" 2>&1
    ;;

  --init-zsh)
    # zsh command mode completion
    _f_zsh_cmd_complete() {
      local compl
      read -c compl
      compstate[insert]=menu # no expand
      eval 'reply=(${(f)"$(_f --complete "$compl")"})'
    }
    # enbale command mode completion
    compctl -U -K _f_zsh_cmd_complete -V f -x 'C[-1,-*e],s[-]n[1,e]' -c -- _f
    # zsh word mode completion
    _f_zsh_word_complete() {
      [ -z "$_f_cur" ] && eval 'local _f_cur="${words[CURRENT]}"'
      eval 'local _f_fnd="${_f_cur//$_F_QUERY_SEPARATOR/ }"'
      local _f_typ=${1:-e}
      _f --query | sort -nr | sed 's/^[0-9.]*[ ]*//' | while read line; do
        compadd -U -V f "$line"
      done
      compstate[insert]=menu # no expand
    }
    _f_zsh_word_complete_f() { _f_zsh_word_complete f ; }
    _f_zsh_word_complete_d() { _f_zsh_word_complete d ; }
    _f_zsh_word_complete_trigger() {
      eval 'local _f_cur="${words[CURRENT]}"'
      _f --word-complete-trigger _f_zsh_word_complete
    }
    # enable word mode completion
    zstyle ':completion:*' completer _complete _ignored \
      _f_zsh_word_complete_trigger
    # define zle widgets
    zle -C f-complete 'menu-select' _f_zsh_word_complete
    zle -C f-complete-f 'menu-select' _f_zsh_word_complete_f
    zle -C f-complete-d 'menu-select' _f_zsh_word_complete_d
    # add zsh hook
    _f_preexec() { { eval "_f --add $(_f --sanitize $3)"; } >> "$_F_SINK" 2>&1; }
    autoload -U add-zsh-hook
    add-zsh-hook preexec _f_preexec
    ;;

  --init-bash)
    # bash command mode completion
    _f_bash_cmd_complete() {
      # complete command after "-e"
      eval 'local cur=${COMP_WORDS[COMP_CWORD]}
      [[ ${COMP_WORDS[COMP_CWORD-1]} == -*e ]] && \
        COMPREPLY=( $(compgen -A command $cur) ) && return'
      # get completion results using expanded aliases
      local RESULT=$( _f --complete "$(alias -p ${COMP_WORDS} | \
        sed -n "\$s/^.*'\(.*\)'/\1/p") ${COMP_LINE#* }" )
      local IFS=$'\n'
      eval 'COMPREPLY=( $RESULT )'
    }
    _f_bash_hook_cmd_complete() {
      for cmd in $*; do
        complete -F _f_bash_cmd_complete $cmd
      done
    }
    # enable bash command mode completion
    _f_bash_hook_cmd_complete $_F_CMD_A $_F_CMD_S $_F_CMD_D $_F_CMD_F
    # bash word mode completion
    _f_bash_word_complete() {
      [ "$_f_cur" ] || eval 'local _f_cur="${COMP_WORDS[COMP_CWORD]}"'
      local _f_typ=${1:-e}
      eval 'local _f_fnd="${_f_cur//$_F_QUERY_SEPARATOR/ }"'
      local RESULT=$(_f --query | sed 's/^[0-9.]*[ ]*//')
      local IFS=$'\n'
      eval 'COMPREPLY=( $RESULT )'
    }
    _f_bash_word_complete_trigger() {
      [ "$_f_cur" ] || eval 'local _f_cur="${COMP_WORDS[COMP_CWORD]}"'
      _f --word-complete-trigger _f_bash_word_complete
    }
    _f_bash_word_complete_wrap() {
      eval 'local _f_cur="${COMP_WORDS[COMP_CWORD]}"'
      _f_bash_word_complete_trigger
      eval 'local z=${COMP_WORDS[0]}'
      # try original comp func
      [ "$COMPREPLY" ] || eval "$( echo "$_F_BASH_COMPLETE_P" | \
        sed -n "/ $z$/"'s/.*-F \(.*\) .*/\1/p' )"
      # fall back on original complete options
      local cmd="$(echo "$_F_BASH_COMPLETE_P" | \
        sed -n "/ $z$/"'s/complete/compgen/') $_f_cur"
      [ "$COMPREPLY" ] || eval 'COMPREPLY=( $(eval $cmd) )'
    }
    _f_bash_hook_word_complete_wrap_all() {
      export _F_BASH_COMPLETE_P="$(complete -p)"
      for cmd in $(complete -p | awk '{print $NF}' | tr '\n' ' '); do
        complete -o default -o bashdefault -F _f_bash_word_complete_wrap $cmd
      done
    }
    # enable word mode completion as default completion
    complete -o default -o bashdefault -D -F _f_bash_word_complete_trigger
    # add bash hook
    echo $PROMPT_COMMAND | grep -v -q "_f --add" && \
      PROMPT_COMMAND='eval "_f --add $(_f --sanitize $(history 1 | \
      sed -e "s/^[ ]*[0-9]*[ ]*//"))" >> "$_F_SINK" 2>&1;'"$PROMPT_COMMAND"
    ;;

  --init-posix)
    _f_ps1_func() {
      eval "_f --add $(_f --sanitize $(fc -nl -0 | sed -n '$s/\s*\(.*\)/\1/p'))"
    }
    _f_ps1_install() {
      echo "$PS1" | grep -v -q "_f_ps1_func" && \
      export PS1="\$(_f_ps1_func >> "$_F_SINK" 2>&1)$PS1"
    }
    echo "$PS1" | grep -q '\\' && _f_ps1_install
    [ "$KSH_VERSION" ] && _f_ps1_install # ksh has the compatibility
    ;;

  --readlink)
    shift
    case "$1" in
      /*) _f_p="$1";;
      *) _f_p="$PWD/$1";;
    esac
    _f_np="$(echo "$_f_p" | sed 's@[^/]*/*\.\.\(/\|$\)@@g;s@\./@@g;s@/\+@/@g;s@[./]*$@@')"
    [ -e "${_f_np:=/}" ] || return 1
    echo "$_f_np"
    ;;

  # if "$_f_cur" is a query, then eval all the arguments
  --word-complete-trigger)
    shift; case "$_f_cur" in
      $_F_QUERY_SEPARATOR*)
        eval "$@";;
      f$_F_QUERY_SEPARATOR*)
        _f_cur=${_f_cur#?}
        eval "$@" f;;
      d$_F_QUERY_SEPARATOR*)
        _f_cur=${_f_cur#?}
        eval "$@" d;;
      *$_F_QUERY_SEPARATOR$_F_QUERY_SEPARATOR)
        eval "$@";;
      *$_F_QUERY_SEPARATOR${_F_QUERY_SEPARATOR}f)
        _f_cur=${_f_cur%?}
        eval "$@" f;;
      *$_F_QUERY_SEPARATOR${_F_QUERY_SEPARATOR}d)
        _f_cur=${_f_cur%?}
        eval "$@" d;;
    esac
    ;;

  --sanitize)
    shift
    echo "$@" | sed 's/\(^\| \).\?[<>|]\+/ /g;s/&$//'
    ;;

  --add) # add entries
    shift

    # stop if we don't own ~/.f (we're another user but our ENV is still set)
    [ -f "$_F_DATA" -a ! -O "$_F_DATA" ] && return

    # make zsh do word splitting here
    [ "$ZSH_VERSION" ] && emulate sh && setopt localoptions

    # blacklists
    for _f_each in $_F_BLACKLIST; do
      case " $* " in *\ $_f_each\ *) return;; esac
    done; unset _f_each

    # shifts
    while true; do
      case " $_F_SHIFT " in
        *\ $1\ *) shift;;
        *) break
      esac
    done

    # ignores
    case " $_F_IGNORE " in
      *\ $1\ *) return
    esac

    shift # shift out the command itself

    while [ "$1" ]; do
      # add the adsolute path to "paths", and a separator "|"
      _f_paths="$_f_paths|$(_f --readlink "$1" 2>> "$_F_SINK")"
      shift
    done

    # add current pwd if the option is set
    [ "$_F_TRACK_PWD" = "1" -a "$PWD" != "$HOME" ] && _f_paths="$_f_paths|$PWD"

    [ -z "${_f_paths##|}" ] && return # stop if we have nothing to add

    # maintain the file
    _f_tempfile="$(mktemp $_F_DATA.XXXXXX)" || return
    $_F_AWK -v list="$_f_paths" -v now="$(date +%s)" -v max="$_F_MAX" -F"|" '
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
        if( count > max )
          for( i in rank ) print i "|" 0.9*rank[i] "|" time[i] # aging
        else
          for( i in rank ) print i "|" rank[i] "|" time[i]
      }' "$_F_DATA" 2>> "$_F_SINK" >| "$_f_tempfile"
    if [ $? -ne 0 -a -f "$_F_DATA" ]; then
      env rm -f "$_f_tempfile"
    else
      env mv -f "$_f_tempfile" "$_F_DATA"
    fi
    unset _f_paths _f_tempfile
    ;;

  --query)
    # query the database, this need some local variables to be set
    while read _f_line; do
      [ -${_f_typ:-e} "${_f_line%%\|*}" ] && echo "$_f_line"
    done < "$_F_DATA" | \
    $_F_AWK -v t="$(date +%s)" -v mode="$_f_mode" -v q="$_f_fnd" -F"|" '
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
      }' - 2>> "$_F_SINK"
      unset _f_line
    ;;

  *) # parsing logic and processing
    [ -f "$_F_DATA" ] || return # no db yet
    while [ "$1" ]; do case "$1" in
      --complete) [ "$2" = "--" ] && shift; set -- $(echo $2); _f_list=1 _f_r=r;;
      --) while [ "$2" ]; do shift; _f_fnd="$fnd$1 "; _f_last="$1"; done;;
      -*) _f_o="${1#-}"; while [ "$_f_o" ]; do case $_f_o in
          s*) _f_show=1;;
          l*) _f_list=1;;
          i*) _f_interactive=1; _f_show=1;;
          r*) _f_mode=rank;;
          t*) _f_mode=recent;;
          e*) _f_o="${_f_o#?}"; if [ "$_f_o" ]; then # there are characters after "-e"
                _f_exec=$o # anything after "-e"
              else # use the next argument
                _f_exec=${2:?"Argument needed after -e"}
                shift
              fi; break;;
          a*) _f_typ=e;;
          d*) _f_typ=d;;
          f*) _f_typ=f;;
          h*) echo "_f [options] [query ...]
  options:
    -s        show list of files with their ranks
    -l        list paths only
    -i        interactive mode
    -e <cmd>  set command to execute on the result file
    -a        match files and directories
    -d        match directories only
    -f        match files only
    -r        match by rank only
    -h        show a brief help message" >&2; return;;
        esac; _f_o="${_f_o#?}"; done;;
      *) _f_fnd="$fnd $1"; _f_last="$1";;
    esac; shift; done; unset _f_o

    # if we hit enter on a completion just execute
    case "$_f_last" in
     # completions will always start with /
     /*) [ -z "$_f_show$_f_list" -a -${_f_typ:-e} "$_f_last" -a "$_f_exec" ] \
       && $_f_exec "$_f_last" && return;;
    esac

    _f_result="$(_f --query 2>> "$_F_SINK")" # query the database
    [ $? -gt 0 ] && return
    if [ "$_f_interactive" ]; then
      _f_result="$(echo "$_f_result" | sort -nr)"
      echo "$_f_result" | sed = | sed 'N;s/\n/\t/' | sort -nr
      printf "> "; read _f_i
      ${_f_exec:=echo} "$(echo "$_f_result" | sed -n "${_f_i:=1}"'s/^[0-9.]*[ ]*//p')"
    elif [ "$_f_list" ]; then
      echo "$_f_result" | sort -n${_f_r} | sed 's/^[0-9.]*[ ]*//'
    elif [ "$_f_show" ]; then
      echo "$_f_result" | sort -n${_f_r}
    elif [ "$_f_fnd" -a "$_f_exec" ]; then # exec
      $_f_exec "$(echo "$_f_result" | sort -n | sed -n '$s/^[0-9.]*[ ]*//p')"
    elif [ "$_f_fnd" -a ! -t 1 ]; then # echo if output is not terminal
      echo "$_f_result" | sort -n | sed -n '$s/^[0-9.]*[ ]*//p'
    else # no args, show
      echo "$_f_result" | sort -n${_f_r}
    fi

    unset _f_fnd _f_last _f_list _f_show _f_interactive _f_mode _f_typ \
      _f_result _f_r _f_exec

  esac
}

_f --init

case "$-" in
  *i*) _f --init-interactive;; # assume being sourced
  *) _f "$@" # assume being executed as an executable
esac

