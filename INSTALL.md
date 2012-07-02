Fasd is a self-contained posix shell script that can be either sourced or
executed. A Makefile is provided to install `fasd` and `fasd.1` to desired
places.


System-wide install:

    make install

Install to $HOME:

    PREFIX=$HOME make install

Or alternatively you can just copy `fasd` to anywhere you like.

To get fasd working in a shell, some initialization code must be run. Put the
line below in your shell rc.

    eval "$(fasd --init auto)"

This will setup a command hook that executes on every command and advanced tab
completion for zsh and bash.

If you want more control over what gets into your shell environment, you can
pass customized set of arguments to `fasd --init`.

    zsh-hook             # define _fasd_preexec and add it to zsh preexec array
    zsh-ccomp            # zsh command mode completion definitions
    zsh-ccomp-install    # setup command mode completion for zsh
    zsh-wcomp            # zsh word mode completion definitions
    zsh-wcomp-install    # setup word mode completion for zsh
    bash-hook            # add hook code to bash $PROMPT_COMMAND
    bash-ccomp           # bash command mode completion definitions
    bash-ccomp-install   # setup command mode completion for bash
    posix-alias          # define alias that applies to all posix shells
    posix-hook           # setup $PS1 hook for shells that's posix compatible
    tcsh-alias           # define aliases for tcsh
    tcsh-hook            # setup tcsh precmd alias

Example for a minimal zsh setup (no tab completion):

    eval "$(fasd --init posix-alias zsh-hook)"

Note that this method will slightly increase your shell start-up time, since
calling binaries has overhead. You can cache fasd init code if you want minimal
overhead. Example code for bash (to be put into .bashrc):

    fasd_cache="$HOME/.fasd-init-bash"
    if [ "$(command -v fasd)" -nt "$fasd_cache" -o ! -s "$fasd_cache" ]; then
      fasd --init posix-alias bash-hook bash-ccomp bash-ccomp-install >| "$fasd_cache"
    fi
    source "$fasd_cache"
    unset fasd_cache

Optionally, if you can also source `fasd` if you want `fasd` to be a shell
function instead of an executable.

You can tweak initialization code. For instance, if you want to use "c"
instead of "z" to do directory jumping. You run the code below:

    # function to execute built-in cd
    fasd_cd() {
      if [ $# -le 1 ]; then
        fasd "$@"
      else
        local _fasd_ret="$(fasd -e echo "$@")"
        [ -z "$_fasd_ret" ] && return
        [ -d "$_fasd_ret" ] && cd "$_fasd_ret" || echo "$_fasd_ret"
      fi
    }
    alias c='fasd_cd -d' # `-d' option present for bash completion

