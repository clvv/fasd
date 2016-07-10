#!/bin/zsh
#
# ZSH-style plugin for `fasd`.
# Allows this repo to be used by any ZSH plugin manager.
#
# You may want to add some of the following to your .zshrc (all optional):
#
#   # If you want more control over initialization hooks:
#   _FASD_INIT_OPTS=(
#       zsh-hook
#       zsh-ccomp
#       zsh-ccomp-install
#       zsh-wcomp
#       zsh-wcomp-install
#   )
#
#   # Handy aliases:
#   alias v="f -e $EDITOR"
#   alias v='f -t -e vim -b viminfo'
#   alias o='a -e open_command'
#
#   # Key bindings:
#   bindkey '^X^A' fasd-complete    # C-x C-a to do fasd-complete (files and directories)
#   bindkey '^X^F' fasd-complete-f  # C-x C-f to do fasd-complete-f (only files)
#   bindkey '^X^D' fasd-complete-d  # C-x C-d to do fasd-complete-d (only directories)
#
: ${_FASD_INIT_CACHE:=${ZSH_CACHE_DIR:-${ZDOTDIR:-$HOME}}/.fasd-init.zsh}

fpath+=($0:h/fasd.plugin/bin)
manpath+=($0:h/fasd.plugin/man)

emulate sh -c 'autoload -U fasd'

if [ $0:h/fasd -nt $_FASD_INIT_CACHE -o ! -s $_FASD_INIT_CACHE ]; then
    fasd --init \
      ${=_FASD_INIT_OPTS:-'auto'} \
      >| $_FASD_INIT_CACHE
fi
source $_FASD_INIT_CACHE
