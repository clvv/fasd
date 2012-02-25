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
    zsh-wcomp-install    # setup word mode completioin for zsh
    bash-hook            # add hook code to bash $PROMPT_COMMAND
    bash-ccomp           # bash command mode completion definitions
    bash-ccomp-install   # setup command mode completion for bash
    bash-wcomp           # bash word mode completion definitions (experimental)
    bash-wcomp-install   # setup word mode completion for bash (experimental)
    posix-alias          # define alias that applies to all posix shells
    posix-hook           # setup $PS1 hook for shells that's posix compatible

Example for a minimal zsh setup (no tab completion):

    eval "$(fasd --init posix-alias zsh-hook)"

Optionally, if you can also source `fasd` if you want `fasd` to be a shell
function instead of an executable.

You can tweak initialization code. For instance, if you want to use "c"
instead of "z" to do directory jumping. You run the code below:

    # function to execute built-in cd
    fasd_cd() { [ $# -gt 1 ] && cd "$(fasd -e echo "$@")" || fasd "$@"; }
    alias c='fasd_cd -d' # `-d' option present for bash completion

