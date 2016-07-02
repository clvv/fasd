#!/bin/zsh
: ${_FASD_INIT_CACHE:=${ZSH_CACHE_DIR:-${ZDOTDIR:-$HOME}}/.fasd-init}

path+=($0:h)
manpath+=($0:h)

if [ "${commands[fasd]}" -nt "$_FASD_INIT_CACHE" -o ! -s "$_FASD_INIT_CACHE" ]; then
	fasd --init \
	  posix-alias \
	  zsh-hook \
	  zsh-ccomp zsh-ccomp-install \
	  zsh-wcomp zsh-wcomp-install \
	  >| "$_FASD_INIT_CACHE"
fi
source "$_FASD_INIT_CACHE"

#alias v="f -e $EDITOR"
#alias v='f -t -e vim -b viminfo'
#alias o='a -e open_command'

#bindkey '^X^A' fasd-complete    # C-x C-a to do fasd-complete (files and directories)
#bindkey '^X^F' fasd-complete-f  # C-x C-f to do fasd-complete-f (only files)
#bindkey '^X^D' fasd-complete-d  # C-x C-d to do fasd-complete-d (only directories)
