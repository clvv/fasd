#!/usr/bin/env bash

# Fasd (this file) can be sourced or executed by any POSIX compatible shell.

# Fasd is originally written based on code from z (https://github.com/rupa/z)
# by rupa deadwyler under the WTFPL license. Most if not all of the code has
# been rewritten.

# Copyright (C) 2011, 2012 by Wei Dai. All rights reserved.
# Copyright (C) 2016 by Michael Wood. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

fasd() {

  # make zsh do word splitting inside this function
  [ "$ZSH_VERSION" ] && emulate sh && setopt localoptions

  shopt -s extglob

  case $1 in
  --init) shift
    while [ "$1" ]; do
      case $1 in
        env)
          { # source rc files if present
          [ -s "/etc/fasdrc" ] && . "/etc/fasdrc"
          [ -s "$HOME/.fasdrc" ] && . "$HOME/.fasdrc"

          # set default options
          [ -z "$_FASD_DATA" ] && _FASD_DATA="$HOME/.fasd"
          [ -z "$_FASD_BLACKLIST" ] && _FASD_BLACKLIST="--help"
          [ -z "$_FASD_SHIFT" ] && _FASD_SHIFT="sudo busybox"
          [ -z "$_FASD_IGNORE" ] && _FASD_IGNORE="fasd ls echo"
          [ -z "$_FASD_SINK" ] && _FASD_SINK=/dev/null
          [ -z "$_FASD_TRACK_PWD" ] && _FASD_TRACK_PWD=1
          [ -z "$_FASD_MAX" ] && _FASD_MAX=2000
          [ -z "$_FASD_BACKENDS" ] && _FASD_BACKENDS=native
          [ -z "$_FASD_FUZZY" ] && _FASD_FUZZY=2
          [ -z "$_FASD_VIMINFO" ] && _FASD_VIMINFO="$HOME/.viminfo"
          [ -z "$_FASD_RECENTLY_USED_XBEL" ] && \
            _FASD_RECENTLY_USED_XBEL="$HOME/.local/share/recently-used.xbel"

          if [ -z "$_FASD_AWK" ]; then
            # awk preferences
            local awk; for awk in mawk gawk original-awk nawk awk; do
              $awk "" && _FASD_AWK=$awk && break
            done
          fi

          # set up a rotating pair of _FASD_DATA files
          # so we can avoid issuing mktemp/mv/rm/cp commands
          if [ -f $_FASD_DATA.1 -a -f $_FASD_DATA.2 ]; then
            if [ $_FASD_DATA.1 -nt $_FASD_DATA.2 ]; then
              dataFile=$_FASD_DATA.1
              newDataFile=$_FASD_DATA.2
            else
              dataFile=$_FASD_DATA.2
              newDataFile=$_FASD_DATA.1
            fi
          elif [ -f $_FASD_DATA.1 ]; then
            dataFile=$_FASD_DATA.1
            newDataFile=$_FASD_DATA.2
          else   # look for an unpaired data file; we will pair it up
            dataFile=$_FASD_DATA
            newDataFile=$_FASD_DATA.1
          fi
        } >> "${_FASD_SINK:-/dev/null}" 2>&1
        ;;

      auto) cat <<EOS
{ if [ "\$ZSH_VERSION" ] && compctl; then # zsh
    eval "\$(fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install \\
      zsh-wcomp zsh-wcomp-install)"
  elif [ "\$BASH_VERSION" ] && complete; then # bash
    eval "\$(fasd --init posix-alias bash-hook bash-ccomp bash-ccomp-install)"
  else # posix shell
    eval "\$(fasd --init posix-alias posix-hook)"
  fi
} >> "$_FASD_SINK" 2>&1
EOS
        ;;

      posix-alias) cat <<EOS
alias a='fasd -a'
alias s='fasd -si'
alias sd='fasd -sid'
alias sf='fasd -sif'
alias d='fasd -d'
alias f='fasd -f'
# function to execute built-in cd
fasd_cd() {
  if [ \$# -le 1 ]; then
    fasd "\$@"
  else
    local _fasd_ret="\$(fasd -e 'printf %s' "\$@")"
    [ -z "\$_fasd_ret" ] && return
    [ -d "\$_fasd_ret" ] && cd "\$_fasd_ret" || printf %s\\n "\$_fasd_ret"
  fi
}
alias z='fasd_cd -d'
alias zz='fasd_cd -d -i'
EOS
        ;;

      tcsh-alias) cat <<EOS
;alias a 'fasd -a';
alias s 'fasd -si';
alias sd 'fasd -sid';
alias sf 'fasd -sif';
alias d 'fasd -d';
alias f 'fasd -f';
alias z 'cd "\`fasd -d -e printf\\ %s \\!*\`" >& /dev/null || fasd -d';
EOS
        ;;

      zsh-hook) cat <<EOS
# add zsh hook
_fasd_preexec() {
  { eval "fasd --proc \$2"; } >> "$_FASD_SINK" 2>&1
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _fasd_preexec
EOS
        ;;

      bash-hook) cat <<EOS
_fasd_prompt_func() {
    local cmd=\$(history 1)
    [[ "\$cmd" =~ ^[\ ]*[0-9]*[\ ]*(.*) ]] && cmd=\${BASH_REMATCH[1]}
    eval "fasd --proc \$cmd" >> "$_FASD_SINK" 2>&1
}
# add bash hook
case \$PROMPT_COMMAND in
  *_fasd_prompt_func*) ;;
  *) PROMPT_COMMAND="_fasd_prompt_func;\$PROMPT_COMMAND";;
esac
EOS
        ;;

      posix-hook) cat <<EOS
_fasd_ps1_func() {
  { eval "fasd --proc \$(fc -nl -1)"; } \\
    >> "$_FASD_SINK" 2>&1
}
case \$PS1 in
  *_fasd_ps1_func*) ;;
  *) export PS1="\\\$(_fasd_ps1_func)\$PS1";;
esac
EOS
        ;;

      tcsh-hook) cat <<EOS
set pprecmd="\`alias precmd\`";
alias precmd '\$pprecmd; eval "fasd --proc \`history -h 1\`" >& /dev/null';
EOS

        ;;

      zsh-ccomp) cat <<EOS
# zsh command mode completion
_fasd_zsh_cmd_complete() {
  local compl
  read -c compl
  (( \$+compstate )) && compstate[insert]=menu # no expand if compsys loaded
  reply=(\${(f)"\$(fasd --complete "\$compl")"})
}
EOS
        ;;

      zsh-wcomp) cat <<EOS
(( \$+functions[compdef] )) && {
  # zsh word mode completion
  _fasd_zsh_word_complete() {
    [ "\$2" ] && local _fasd_cur="\$2"
    [ -z "\$_fasd_cur" ] && local _fasd_cur="\${words[CURRENT]}"
    local fnd="\${_fasd_cur//,/ }"
    local typ=\${1:-e}
    fasd --query \$typ "\$fnd" 2>> "$_FASD_SINK" | \\
      sort -nr | sed 's/^[^ ]*[ ]*//' | while read -r line; do
        compadd -U -V fasd "\$line"
      done
    compstate[insert]=menu # no expand
  }
  _fasd_zsh_word_complete_f() { _fasd_zsh_word_complete f ; }
  _fasd_zsh_word_complete_d() { _fasd_zsh_word_complete d ; }
  _fasd_zsh_word_complete_trigger() {
    local _fasd_cur="\${words[CURRENT]}"
    eval \$(fasd --word-complete-trigger _fasd_zsh_word_complete \$_fasd_cur)
  }
  # define zle widgets
  zle -C fasd-complete complete-word _generic
  zstyle ':completion:fasd-complete:*' completer _fasd_zsh_word_complete
  zstyle ':completion:fasd-complete:*' menu-select
  zle -C fasd-complete-f complete-word _generic
  zstyle ':completion:fasd-complete-f:*' completer _fasd_zsh_word_complete_f
  zstyle ':completion:fasd-complete-f:*' menu-select
  zle -C fasd-complete-d complete-word _generic
  zstyle ':completion:fasd-complete-d:*' completer _fasd_zsh_word_complete_d
  zstyle ':completion:fasd-complete-d:*' menu-select
}
EOS
        ;;

      zsh-ccomp-install) cat <<EOS
# enable command mode completion
compctl -U -K _fasd_zsh_cmd_complete -V fasd -x 'C[-1,-*e],s[-]n[1,e]' -c - \\
  'c[-1,-A][-1,-D]' -f -- fasd fasd_cd
EOS
        ;;

      zsh-wcomp-install) cat <<EOS
(( \$+functions[compdef] )) && {
  # enable word mode completion
  orig_comp="\$(zstyle -L ':completion:\\*' completer 2>> "$_FASD_SINK")"
  if [ "\$orig_comp" ]; then
    case \$orig_comp in
      *_fasd_zsh_word_complete_trigger*);;
      *) eval "\$orig_comp _fasd_zsh_word_complete_trigger";;
    esac
  else
    zstyle ':completion:*' completer _complete _fasd_zsh_word_complete_trigger
  fi
  unset orig_comp
}
EOS
        ;;

      bash-ccomp) cat <<EOS
# bash command mode completion
_fasd_bash_cmd_complete() {
  # complete command after "-e"
  local cur=\${COMP_WORDS[COMP_CWORD]}
  [[ \${COMP_WORDS[COMP_CWORD-1]} == -*e ]] && \\
    COMPREPLY=( \$(compgen -A command \$cur) ) && return
  # complete using default readline complete after "-A" or "-D"
  case \${COMP_WORDS[COMP_CWORD-1]} in
    -A|-D) COMPREPLY=( \$(compgen -o default \$cur) ) && return;;
  esac
  # get completion results using expanded aliases
  local RESULT=\$( fasd --complete "\$(alias -p \$COMP_WORDS \\
    2>> "$_FASD_SINK" | sed -n "\\\$s/^.*'\\\\(.*\\\\)'/\\\\1/p")
    \${COMP_LINE#* }" | while read -r line; do
      quote_readline "\$line" 2>/dev/null || \\
        printf %q "\$line" 2>/dev/null  && \\
        printf \\\\n
    done)
  local IFS=\$'\\n'; COMPREPLY=( \$RESULT )
}
_fasd_bash_hook_cmd_complete() {
  for cmd in \$*; do
    complete -F _fasd_bash_cmd_complete \$cmd
  done
}
EOS
        ;;

      bash-ccomp-install) cat <<EOS
# enable bash command mode completion
_fasd_bash_hook_cmd_complete fasd a s d f sd sf z zz
EOS
        ;;
      esac; shift
    done
    ;;

  # if "$_fasd_cur" or "$2" is a query, then output shell code to be eval'd
  --word-complete-trigger)
    shift; [ "$2" ] && local _fasd_cur="$2" || return
    case $_fasd_cur in
      ,*) printf %s\\n "$1 e $_fasd_cur";;
      f,*) printf %s\\n "$1 f ${_fasd_cur#?}";;
      d,*) printf %s\\n "$1 d ${_fasd_cur#?}";;
      *,,) printf %s\\n "$1 e $_fasd_cur";;
      *,,f) printf %s\\n "$1 f ${_fasd_cur%?}";;
      *,,d) printf %s\\n "$1 d ${_fasd_cur%?}";;
    esac
    ;;

  --proc) shift # process commands

    # "sanitize" the command, removing shell operators and metacharacters
    local y="$*"$'\n'
    while [[ "$y" =~ (.*[^\])[|\&\;\<\>$\`{}]+(.*) ]]; do
      y=${BASH_REMATCH[1]}${BASH_REMATCH[2]}
    done
    eval set "-- "$y

    # stop if we don't own $dataFile or $_FASD_RO is set
    [ -f "$dataFile" -a ! -O "$dataFile" ] || [ "$_FASD_RO" ] && return

    # blacklists
    local each; for each in $_FASD_BLACKLIST; do
      case " $* " in *\ $each\ *) return;; esac
    done

    # shifts
    while true; do
      case " $_FASD_SHIFT " in
        *\ $1\ *) shift;;
        *) break;;
      esac
    done

    # ignores
    case " $_FASD_IGNORE " in
      *\ $1\ *) return;;
    esac

    shift; fasd --add "$@" # add all arguments except command
    ;;

  --add|-A) shift # add entries
    # stop if we don't own the current data file or $_FASD_RO is set
    [ -f "$dataFile" -a ! -O "$dataFile" ] || [ "$_FASD_RO" ] && return

    # find all valid path arguments, convert them to simplest absolute form
    local paths=""
    while [ "$1" ]; do
      [ ! -e "$1" ] && { shift; continue; }
      p=$1
      [[ "$p" =~ ^/ ]] || p="$PWD"/$p                  # make paths absolute
      while [[ "$p" =~ (.*)/\./(.*) ]]; do             # clean up "./"
        p=${BASH_REMATCH[1]}/${BASH_REMATCH[2]}
      done
      [[ "$p" =~ /\.\.$ ]] && p+=/                     # clean up final ".."
      while [[ "$p" =~ (.*)[^/]+[/]+\.\./(.*) ]]; do   # clean up "../"
        p=${BASH_REMATCH[1]}/${BASH_REMATCH[2]}
      done
      [[ "$p" =~ ^[/]?\.\.(/.*) ]] && p=${BASH_REMATCH[1]} # clean initial /../
      while [[ "$p" =~ (.*)//(.*) ]]; do               # delete redundant /s
        p=${BASH_REMATCH[1]}/${BASH_REMATCH[2]}
      done
      [[ "$p" =~ (.*)/[.]?$ ]] && p=${BASH_REMATCH[1]} # delete final / or /.
      paths+=$p"|"
      shift
    done

    # add current pwd if the option is set
    [ "$_FASD_TRACK_PWD" = "1" -a "$PWD" != "$HOME" ] && paths="$paths|$PWD"

    [ -z "${paths##\|}" ] && return # stop if we have nothing to add

    # prepare to calculate the new fasd data from the current data
    declare -A ranks times
    local max="$_FASD_MAX"
    local now=$(date +%s)
    local iCount fCount
    OLDFS="$IFS"; IFS='|'
    for fname in $paths; do
      [[ -z "$fname" ]] && continue
      ranks[$fname]=1
      times[$fname]=$now
    done
    IFS="$OLDFS"

    declare -r scale=6
    ((fCount=10**scale)); fCount=${fCount:1}  # "scale" zeros

    # calculation function that acts on every line of the data file
    populate_ranks_and_times() {
      # Parse a line of fasd data
      [[ $2 =~ (.*)\|(([0-9]+)(\.([0-9]*))?)\|(.*) ]]
      fname=${BASH_REMATCH[1]}
      #rank=${BASH_REMATCH[2]}
      iRank=${BASH_REMATCH[3]}
      fRank=${BASH_REMATCH[5]}
      time=${BASH_REMATCH[6]}
  
      local d=0
  
      if ((iRank>=1)); then
        if [[ -n "${ranks[${fname}]}" ]]; then
  
          # Compute 1/rank in several steps

          # Convert decimals to integers
          ((top = 10**${#fRank}))
          bottom=$iRank$fRank
          # Divide and round the quotient
          ((quot = (top*10**scale)/bottom
                 + ((top*10**scale)%bottom > bottom/2)))
          # Left-pad the quotient with zeros
          ((d=scale-${#quot}))
          if ((d>0)); then
            quot=$((10**d))$quot
            quot=${quot:1}
          fi
          # Break the quotient into integer and fractional parts
          iPart=${quot:0:-$scale}
          fPart=${quot:${#quot}-$scale}
 
          # Add rank to 1/rank
          ((total_fRank=10#$fPart+(10#$fRank)*10**(scale-${#fRank})))   # right-pad
          ((total_iRank=iPart+iRank))
          if ((${#total_fRank} > scale)); then      # adjust for overflow
            total_fRank=${total_fRank:1}
            ((total_iRank++))
          fi
  
          # Populate the data arrays
          rank=$total_iRank
          [[ -n $total_fRank ]] && rank+=.$total_fRank
          ranks[$fname]=$rank
          times[$fname]=$now
  
        else
          # Populate the data arrays
          rank=$iRank
          [[ -n $fRank ]] && rank+=.$fRank
          ranks[$fname]=$rank
          times[$fname]=$time
        fi
  
        # Increase the count. Be careful about precision and overflow
        ((d=scale-${#fRank}))
        if ((d>0)); then ((fRank=(10#$fRank)*10**d)); fi
        ((iCount=10#$iCount+10#$iRank))   # force base-10 arithmetic
        ((fCount=10#$fCount+10#$fRank))
        if ((${#fCount} > scale)); then
          fCount=${fCount:1}
          ((iCount++))
        fi
      fi
    }

    mapfile -t -c 1 -C populate_ranks_and_times < "$dataFile"

    # Shrink the rankings if they exceed the threshold. Write the new file. 
    if ((iCount > max)); then
      for fname in "${!ranks[@]}"; do
        [[ "${ranks[$fname]}" =~ ([0-9]*)\.([0-9]*) ]]
        iRank=${BASH_REMATCH[1]}
        fRank=${BASH_REMATCH[2]}
             
        # Divide the rank by 10
        fRank=$((iRank%10))$((fRank/10 + 2*fRank%10))  # Round. Grab a digit.
        ((iRank/=10))  # Give up a digit.
        d=${#fRank}
        # Multiply the rank by 9
        ((fRank*=9)); ((iRank*=9))
        if ((${#fRank}>d)); then
          ((iRank+=${fRank:0:1}))
          fRank=${fRank:1}
        fi
 
        # Represent the rank as a decimal value
        rank=$iRank; if ((fRank>0)); then rank+=.${fRank%%+(0)}; fi

        # append to or write the new file as appropriate
        if ((written>0)); then
          echo $fname"|"$rank"|"${times[$fname]} \
            2>> "$_FASD_SINK" >> "$newDataFile"
        else
          echo $fname"|"$rank"|"${times[$fname]} \
            2>> "$_FASD_SINK" >| "$newDataFile"
          written=1
        fi
      done
    else
      for fname in "${!ranks[@]}"; do
        if ((written>0)); then
          echo $fname"|"${ranks[$fname]}"|"${times[$fname]} \
            2>> "$_FASD_SINK" >> "$newDataFile"
        else
          echo $fname"|"${ranks[$fname]}"|"${times[$fname]} \
            2>> "$_FASD_SINK" >| "$newDataFile"
          written=1
        fi
      done
    fi

    unset ranks times

    # in case of failure, fall back on the preexisting data
    # TODO: replace $? with a cumulative error counter
    if [ $? -ne 0 -a -f "$dataFile" ]; then
      touch "$dataFile"    # make this file "newer" for next time
    fi
    ;;

  --delete|-D) shift # delete entries
    # stop if we don't own the current data file or $_FASD_RO is set
    [ -f "$dataFile" -a ! -O "$dataFile" ] || [ "$_FASD_RO" ] && return

    # turn valid arguments into entry-deleting sed commands
    local sed_cmd="$(while [ "$1" ]; do printf %s\\n "$1"; shift; done | \
      sed '/^[^/]/s@^@'"$PWD"'/@;s@/\.\.$@/../@;s@/\(\./\)\{1,\}@/@g;:0
        s@[^/][^/]*//*\.\./@/@;t 0
        s@^/*\.\./@/@;s@//*@/@g;s@/\.\{0,1\}$@@
        s@^$@/@;s@\([.[\/*^$]\)@\\\1@g;s@^\(.*\)$@/^\1|/d@' 2>> "$_FASD_SINK")"

    sed "$sed_cmd" "$dataFile" 2>> "$_FASD_SINK" >| "$newDataFile"

    # in case of failure, fall back on the preexisting data
    if [ $? -ne 0 -a -f "$dataFile" ]; then
      touch "$dataFile"
    fi
    ;;

  --query) shift # query the db, --query [$typ ["$fnd" [$mode]]]
    [ -f "$dataFile" ] || return # no db yet
    [ "$1" ] && local typ="$1"
    [ "$2" ] && local fnd="$2"
    [ "$3" ] && local mode="$3"

    # cat all backends
    local each _fasd_data; for each in $_FASD_BACKENDS; do
      fasd --backend $each
      [[ -n $_fasd_data ]] && _fasd_data+=$'\n'
      _fasd_data+=$backendBuffer
    done
    [ "$_fasd_data" ] || _fasd_data="$(cat "$dataFile")"

    if [ "$fnd" ]; then # dafault matching
      local bre="$(printf %s\\n "$fnd" | sed 's/\([*\.\\\[]\)/\\\1/g
        s@ @[^|]*@g;s/\$$/|/')"
      bre='^[^|]*'"$bre"'[^|/]*|'
      local _ret="$(printf %s\\n "$_fasd_data" | grep "$bre")"
      [ "$_ret" ] && _ret="$(printf %s\\n "$_ret" | while read -r line; do
        [ -${typ:-e} "${line%%\|*}" ] && printf %s\\n "$line"
      done)"
      if [ "$_ret" ]; then
        _fasd_data="$_ret"
      else # no case mathcing
        _ret="$(printf %s\\n "$_fasd_data" | grep -i "$bre")"
        [ "$_ret" ] && _ret="$(printf %s\\n "$_ret" | while read -r line; do
          [ -${typ:-e} "${line%%\|*}" ] && printf %s\\n "$line"
        done)"
        if [ "$_ret" ]; then
          _fasd_data="$_ret"
        elif [ "${_FASD_FUZZY:-0}" -gt 0 ]; then # fuzzy matching
          local fuzzy_bre="$(printf %s\\n "$fnd" | \
            sed 's/\([*\.\\\[]\)/\\\1/g;s/\$$/|/
              s@\(\\\{0,1\}[^ ]\)@\1[^|/]\\{0,'"$_FASD_FUZZY"'\\}@g
              s@ @[^|]*@g')"
          fuzzy_bre='^[^|]*'"$fuzzy_bre"'[^|/]*|'
          _ret="$(printf %s\\n "$_fasd_data" | grep -i "$fuzzy_bre")"
          [ "$_ret" ] && _ret="$(printf %s\\n "$_ret" | while read -r line; do
            [ -${typ:-e} "${line%%\|*}" ] && printf %s\\n "$line"
          done)"
          [ "$_ret" ] && _fasd_data="$_ret" || _fasd_data=
        fi
      fi
    else # no query arugments
      local _tmp_data=$_fasd_data$'\n'; _fasd_data=""
      while [[ "$_tmp_data" =~ ^(([^|]*)\|[^$'\n']*$'\n')(.*) ]]; do
        [ -${typ:-e} "${BASH_REMATCH[2]}" ] && _fasd_data+=${BASH_REMATCH[1]}
        _tmp_data=${BASH_REMATCH[3]}
      done
      _fasd_data=${_fasd_data%$'\n'}
    fi

    # query the database
    [ "$_fasd_data" ] || return 
    _fasd_data+=$'\n'
    t="$(date +%s)"
    declare -A ranks times
    declare -r scale=6

    OLDFS=$IFS; IFS=$'\n'
    for line in $_fasd_data; do
      # parse a single line of fasd data
      [[ $line =~ (.*)\|(([0-9]+)(\.([0-9]*))?)\|(.*) ]]
      fname=${BASH_REMATCH[1]}
      rank=${BASH_REMATCH[2]}
      iRank=${BASH_REMATCH[3]}
      fRank=${BASH_REMATCH[5]}
      time=${BASH_REMATCH[6]}

      ((d=scale-${#fRank}))
      if ((d>0)); then
        ((fRank=(10#$fRank)*10**(scale-${#fRank})))
      fi

      if [[ -n "${times[$fname]}" ]]; then
        # add current rank to cumulative rank
        [[ ${ranks[$fname]} =~ ([0-9]+)(\.([0-9]*))? ]]
        iRk=${BASH_REMATCH[1]}
        fRk=${BASH_REMATCH[3]}
        ((total_iRank=iRank+iRk))
        ((total_fRank=10#$fRank+(10#$fRk)*10**(scale-${#fRk})))
        if ((${#total_fRank} > scale)); then    # adjust for overflow
          total_fRank=${total_fRank:1}
          ((total_iRank++))
        fi

        # store the new rank and time
        ranks[$fname]=$total_iRank"."${total_fRank%%+(0)}
        if ((time > times[$fname])); then
            times[$fname]=$time
        fi

      else
        # initialize the rank and time
        ranks[$fname]=$rank
        times[$fname]=$time
      fi
    done
    IFS=$OLDFS

    case $mode in
      rank)
        # prior='ranks[i]';;
        for path in "${!ranks[@]}"; do
          printf "%-10s %s\n" ${ranks[$path]} $path
        done
        ;;
      recent)
        # prior='sqrt(100000/(1+t-times[i]))'
        # Use awk to calculate prior because it's far too hard to calculate
        # in bash. Invoke awk just once, and while we're at it do *all* the
        # "real work" there
        input=""
        for path in "${!times[@]}"; do
          input+=${times[$path]}" "$path$'\n'
        done
        input=${input%$'\n'}
        $_FASD_AWK -v t=$t '
        {
          prior=sqrt(100000/(1+t-$1))
          printf "%-10s %s\n", prior, $2
        }' <<< "$input" 2>> "$_FASD_SINK"
        ;;
      *)
        # prior='ranks[i] * frecent(times[i])';;
        local frecent dx
        for path in "${!times[@]}"; do
          # Compute "frecent"
          ((dx = t-times[$path]))
          if ((dx < 3600)); then frecent=6
          elif ((dx < 86400)); then frecent=4
          elif ((dx < 604800)); then frecent=2
          else frecent=1
          fi
          # Compute rank * frecent 
          [[ ${ranks[$path]} =~ ([0-9]+)(\.([0-9]*))? ]]
          iRk=${BASH_REMATCH[1]}
          fRk=${BASH_REMATCH[3]}
          d=${#fRk}
          ((iRk*=frecent)); ((fRk*=frecent))
          if ((${#fRk}>d)); then 
            ((iRk+=${fRk:0:1}))
            fRk=${fRk:1}
          fi

          ranks[$path]=$iRk
          if ((fRk>0)); then ranks[$path]+="."${fRk%%+(0)}; fi
          printf "%-10s %s\n" ${ranks[$path]} $path
        done
      ;;
    esac
      
      unset ranks times
    ;;

  --backend)
    case $2 in
      native)
        backendBuffer="$(<"$dataFile")"
        ;;
      viminfo)
        backendBuffer="$(sed -n '/^>/{s@~@'"$HOME"'@
          s/^..//
          p
          }' "$_FASD_VIMINFO" | $_FASD_AWK ' BEGIN {
             t = systime() - 60 }
            { print $0 "|1|" t
        }')"
        ;;
      recently-used)
        backendBuffer="$(
        local nl="\\"$'\n' # slash newline for sed
        tr -d '\n' < "$_FASD_RECENTLY_USED_XBEL" | \
          sed 's@file:/@'"$nl"'@g;s@count="@'"$nl"'@g' | sed '1d;s/".*$//' | \
          tr '\n' '|' | sed 's@|/@'"$nl"'@g' | $_FASD_AWK -F'|' '{
            sum = 0
            for( i=2; i<=NF; i++ ) sum += $i
            print $1 "|" sum
        }')"
        ;;
      current)
        backendBuffer=""
        for path in *; do
          backendBuffer+="$PWD/$path|1"$'\n'
        done
        ;;
      spotlight)
          backendBuffer="$(
          mdfind '(kMDItemFSContentChangeDate >= $time.today) ||
          kMDItemLastUsedDate >= $time.this_month' \
          | sed '/Library\//d
            /\.app$/d
            s/$/|2/')"
        ;;
      *) eval "$2";;
    esac
    ;;

  *) # parsing logic and processing
    local fnd= last= _FASD_BACKENDS="$_FASD_BACKENDS" _fasd_data= comp= exec=
    while [ "$1" ]; do
      case $1 in
      --complete) [ "$2" = "--" ] && shift; set -- $2; local lst=1 r=r comp=1;;
      --query|--add|--delete|-A|-D) fasd "$@"; return $?;;
      --version) [ -z "$comp" ] && echo "1.0.1" && return;;
      --) while [ "$2" ]; do shift; fnd="$fnd $1"; last="$1"; done;;
      -*) local o="${1#-}"; while [ "$o" ]; do 
          case $o in
          s*) local show=1;;
          l*) local lst=1;;
          i*) [ -z "$comp" ] && local interactive=1 show=1;;
          r*) local mode=rank;;
          t*) local mode=recent;;
          e*) o="${o#?}"; if [ "$o" ]; then # there are characters after "-e"
                local exec="$o" # anything after "-e"
              else # use the next argument
                local exec="${2:?"-e: Argument needed "}"
                shift
              fi; break;;
          b*) o="${o#?}"; if [ "$o" ]; then
                _FASD_BACKENDS="$o"
              else
                _FASD_BACKENDS="${2:?"-b: Argument needed"}"
                shift
              fi; break;;
          B*) o="${o#?}"; if [ "$o" ]; then
                _FASD_BACKENDS="$_FASD_BACKENDS $o"
              else
                _FASD_BACKENDS="$_FASD_BACKENDS ${2:?"-B: Argument needed"}"
                shift
              fi; break;;
          a*) local typ=e;;
          d*) local typ=d;;
          f*) local typ=f;;
          R*) local r=r;;
      [0-9]*) local _fasd_i="$o"; break;;
          h*) [ -z "$comp" ] && echo "fasd [options] [query ...]
[f|a|s|d|z] [options] [query ...]
  options:
    -s         list paths with scores
    -l         list paths without scores
    -i         interactive mode
    -e <cmd>   set command to execute on the result file
    -b <name>  only use <name> backend
    -B <name>  add additional backend <name>
    -a         match files and directories
    -d         match directories only
    -f         match files only
    -r         match by rank only
    -t         match by recent access only
    -R         reverse listing order
    -h         show a brief help message
    -[0-9]     select the nth entry

fasd [-A|-D] [paths ...]
    -A    add paths
    -D    delete paths" >&2 && return;;
        esac; o="${o#?}"; done;;
      *) fnd="$fnd $1"; last="$1";;
    esac; shift; done

    # guess whether the last query is selected from tab completion
    case $last in
      /?*) if [ -z "$show$lst" -a -${typ:-e} "$last" -a "$exec" ]; then
             $exec "$last"
             return
           fi;;
    esac

    local R; [ -z "$r" ] && R=r || R= # let $R be the opposite of $r
    fnd="${fnd# }"

    local res
    res="$(fasd --query 2>> "$_FASD_SINK")" # query the database
    [ $? -gt 0 ] && return
    if [ 0 -lt ${_fasd_i:-0} ] 2>> "$_FASD_SINK"; then
      res="$(printf %s\\n "$res" | sort -n${R} | \
        sed -n "$_fasd_i"'s/^[^ ]*[ ]*//p')"
    elif [ "$interactive" ] || [ "$exec" -a -z "$fnd$lst$show" -a -t 1 ]; then
      if [ "$(printf %s "$res" | sed -n '$=')" -gt 1 ]; then
        res="$(printf %s\\n "$res" | sort -n${R})"
        printf %s\\n "$res" | sed = | sed 'N;s/\n/	/' | sort -nr >&2
        printf "> " >&2
        local i; read i; [ 0 -lt "${i:-0}" ] 2>> "$_FASD_SINK" || return 1
      fi
      res="$(printf %s\\n "$res" | sed -n "${i:-1}"'s/^[^ ]*[ ]*//p')"
    elif [ "$lst" ]; then
      [ "$res" ] && printf %s\\n "$res" | sort -n${r} | sed 's/^[^ ]*[ ]*//'
      return
    elif [ "$show" ]; then
      [ "$res" ] && printf %s\\n "$res" | sort -n${r}
      return
    elif [ "$fnd" ] && [ "$exec" -o ! -t 1 ]; then # exec or subshell
      res="$(printf %s\\n "$res" | sort -n | sed -n '$s/^[^ ]*[ ]*//p')"
    else # no args, show
      [ "$res" ] && printf %s\\n "$res" | sort -n${r}
      return
    fi
    if [ "$res" ]; then
      fasd --add "$res"
      [ -z "$exec" ] && exec='printf %s\n'
      $exec "$res"
    fi
    ;;
  esac
}

fasd --init env

case $- in
  *i*) ;; # assume being sourced, do nothing
  *) # assume being executed as an executable
    if [ -x "$_FASD_SHELL" -a -z "$_FASD_SET" ]; then
      _FASD_SET=1 exec $_FASD_SHELL "$0" "$@"
    else
      fasd "$@"
    fi;;
esac

