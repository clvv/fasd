Fad is a self-contained posix shell script that can be either sourced or
executed. A Makefile is provided to install `fad` and `fad.1` to desired
places.


System-wide install:

    make install

Install to $HOME:

    PREFIX=$HOME make install

Or alternatively you can just copy `fad` to anywhere you like.

To get fad working in a shell, some initialization code must be run. Put the
line below in your shell rc.

    eval "$(fad --init auto)"

This will setup a command hook that executes on every command and advanced tab
completion for zsh and bash.

If you want more control over what gets into your shell environment, you can
pass customized set of arguments to `fad --init`.

    zsh-hook             # define _fad_preexec and add it to zsh preexec array
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

    eval "$(fad --init posix-alias zsh-hook)"

Note that this method will slightly increase your shell start-up time, since
calling binaries has overhead. You can cache fad init code if you want minimal
overhead. Example code for bash (to be put into .bashrc):

    fad_cache="$HOME/.fad-init-bash"
    if [ "$(command -v fad)" -nt "$fad_cache" -o ! -s "$fad_cache" ]; then
      fad --init posix-alias bash-hook bash-ccomp bash-ccomp-install >| "$fad_cache"
    fi
    source "$fad_cache"
    unset fad_cache

Optionally, if you can also source `fad` if you want `fad` to be a shell
function instead of an executable.

You can tweak initialization code. For instance, if you want to use "c"
instead of "z" to do directory jumping. You run the code below:

    # function to execute built-in cd
    fad_cd() {
      if [ $# -le 1 ]; then
        fad "$@"
      else
        local _fad_ret="$(fad -e echo "$@")"
        [ -z "$_fad_ret" ] && return
        [ -d "$_fad_ret" ] && cd "$_fad_ret" || echo "$_fad_ret"
      fi
    }
    alias c='fad_cd -d' # `-d' option present for bash completion

