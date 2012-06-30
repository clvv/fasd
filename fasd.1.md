% FASD(1) fasd user manual
% Wei Dai <x@wei23.net>
% Jun 29, 2012

# NAME

fasd - quick access to files and directories

# SYNOPSIS

fasd [options] [query ...]

[f|a|s|d|z] [options] [query ...]

fasd [-A|-D] [paths ...]

# OPTIONS

    -s         show list of files with their ranks
    -l         list paths only
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

# DESCRIPTION

Fasd keeps track of files and directories you access in your shell and gives you
quick access to them. You can use fasd to reference files or directories by just
a few key identifying characters. You can use fasd to boost your command line
productivity by defining your own aliases to launch programs on files or
directories. Fasd, by default, provides some basic aliases, including a shell
function "z" that resembles the functionality of "z" and "autojump."

The name "fasd" comes from the default suggested aliases `f`(files),
`a`(files/directories), `s`(show/search/select), `d`(directories).

Fasd ranks files and directories by "frecency," that is, by both "frequency"
and "recency." The term "frecency" was first coined by Mozilla and used in
Firefox.

# EXAMPLES

    z bundle
    f -e vim nginx conf
    vi `f nginx conf`
    cp update.html `d www`
    open `sf pdf`

# SHELL INITIALIZATION

To get fasd working in a shell, some initialization code must be run. Put
lines below in your POSIX compatible shell rc.

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
    posix-alias          # define aliases that applies to all posix shells
    posix-hook           # setup $PS1 hook for shells that's posix compatible
    tcsh-alias           # define aliases for tcsh
    tcsh-hook            # setup tcsh precmd alias

Example for a minimal zsh setup (no tab completion):

    eval "$(fasd --init posix-alias zsh-hook)"

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

# COMPATIBILITY

Fasd's basic functionalities are POSIX compliant, meaning that you should be
able to use fasd in all POSIX compliant shells. Your shell need to support
command substitution in $PS1 in order for fasd to automatically track your
commands and files. This feature is not specified by the POSIX standard, but
it's nonetheless present in many POSIX compliant shells. In shells without
prompt command or prompt command substitution (tcsh for instance), you can add
entries manually with "fasd -A". You are very welcomed to contribute shell
initialization code for not yet supported shells.

# TAB COMPLETION

Fasd offers two completion modes, command mode completion and word mode
completion. Command mode completioin works in bash and zsh. Word mode
completion only works in zsh.

Command mode completion is just like completion for any other commands. It is
triggered when you hit tab on a fasd command or its aliases. Under this mode
your queries can be separated by a space. Tip: if you find that the completion
result overwrites your queries, type an extra space before you hit tab.

Word mode completion can be triggered on *any* command. Word completion is
triggered by any command line argument that starts with "," (all), "f,"
(files), or "d," (directories), or that ends with ",," (all), ",,f" (files),
or ",,d" (directories). Examples:

    $ vim ,rc,lo<Tab>
    $ vim /etc/rc.local

    $ mv index.html d,www<Tab>
    $ mv index.html /var/www/

There are also three zle widgets: "fasd-complete", "fasd-complete-f",
"fasd-complete-d". You can bind them to keybindings you like:

    bindkey '^X^A' fasd-complete    # C-x C-a to do fasd-complete (fils and directories)
    bindkey '^X^F' fasd-complete-f  # C-x C-f to do fasd-complete-f (only files)
    bindkey '^X^D' fasd-complete-d  # C-x C-d to do fasd-complete-d (only directories)

# BACKENDS

Fasd can take advantage of different sources of recent / frequent files. Most
desktop environments (like Gtk) and some editors (like Vim) keep a list of
accessed files. Fasd can use them as additional backends if the data can be
converted into fasd's native format. As of now, fasd supports Gtk's
`recently-used.xbel` and Vim's `viminfo` backends. You can define your own
backend by declaring a function by that name in your `.fasdrc`. You set default
backend with `_FASD_BACKENDS` variable in our `.fasdrc`.

# TWEAKS

Upon every execution, fasd will source "/etc/fasdrc" and "$HOME/.fasdrc" if
they are present. Below are some variables you can set:

    $_FASD_DATA
    Path to the fasd data file, default "$HOME/.fasd".

    $_FASD_BLACKLIST
    List of blacklisted strings. Commands matching them will not be processed.
    Default is "--help".

    $_FASD_SHIFT
    List of all commands that needs to be shifted, defaults to "sudo busybox".

    $_FASD_IGNORE
    List of all commands that will be ignored, defaults to "fasd ls echo".

    $_FASD_TRACK_PWD
    Fasd defaults to track your "$PWD". Set this to 0 to disable this behavior.

    $_FASD_AWK
    Which awk to use. fasd can detect and use a compatible awk.

    $_FASD_SINK
    File to log all STDERR to, defaults to "/dev/null".

    $_FASD_MAX
    Max total score / weight, defaults to 2000.

    $_FASD_SHELL
    Which shell to execute. Some shells will run faster than others. fasd
    runs faster with dash and ksh variants.

    $_FASD_BACKENDS
    Default backends.

    $_FASD_RO
    If set to any non-empty string, fasd will not add or delete entries from
    database. You can set and export this variable from command line.

    $_FASD_FUZZY
    Level of "fuzziness" when doing fuzzy matching. More precisely, the number of
    characters that can be skipped to generate a match. Set to empty or 0 to
    disable fuzzy matching. Default value is 2.

# DEBUGGING

Fasd is hosted on GitHub: https://github.com/clvv/fasd

If fasd does not work as expected, please file a bug report on GitHub describing
the unexpected behavior along with your OS version, shell version, awk version,
sed version, and a log file.

You can set `_FASD_SINK` in your `.fasdrc` to obtain a log.

    _FASD_SINK="$HOME/.fasd.log"

# COPYING

Fasd is originally written based on code from z (https://github.com/rupa/z) by
rupa deadwyler under the WTFPL license. Most if not all of the code has been
rewritten. Fasd is licensed under the "MIT/X11" license.

