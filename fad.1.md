% FAD(1) fad user manual
% Wei Dai <x@wei23.net>
% Jul 16, 2012

# NAME

fad - quick access to files and directories

# SYNOPSIS

fad [options] [query ...]

[f|a|s|d|z] [options] [query ...]

fad [-A|-D] [paths ...]

# OPTIONS

    -s         list paths with ranks
    -l         list paths without ranks
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

Fad keeps track of files and directories you access in your shell and gives you
quick access to them. You can use fad to reference files or directories by just
a few key identifying characters. You can use fad to boost your command line
productivity by defining your own aliases to launch programs on files or
directories. Fad, by default, provides some basic aliases, including a shell
function "z" that resembles the functionality of "z" and "autojump."

The name "fad" comes from the default suggested aliases `f`(files),
`a`(files/directories), `s`(show/search/select), `d`(directories).

Fad ranks files and directories by "frecency," that is, by both "frequency"
and "recency." The term "frecency" was first coined by Mozilla and used in
Firefox.

# EXAMPLES

    z bundle
    f -e vim nginx conf
    f -i rc$
    vi `f nginx conf`
    cp update.html `d www`
    open `sf pdf`

# SHELL INITIALIZATION

To get fad working in a shell, some initialization code must be run. Put
lines below in your POSIX compatible shell rc.

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
    posix-alias          # define aliases that applies to all posix shells
    posix-hook           # setup $PS1 hook for shells that's posix compatible
    tcsh-alias           # define aliases for tcsh
    tcsh-hook            # setup tcsh precmd alias

Example for a minimal zsh setup (no tab completion):

    eval "$(fad --init posix-alias zsh-hook)"

Note that this method will slightly increase your shell start-up time, since
calling binaries has overhead. You can cache fad init code if you want
minimal overhead. Example code for bash (to be put into .bashrc):

    fad_cache="$HOME/.fad-init-bash"
    if [ "$(command -v fad)" -nt "$fad_cache" -o ! -s "$fad_cache" ]; then
      fad --init posix-alias bash-hook bash-ccomp bash-ccomp-install >| "$fad_cache"
    fi
    source "$fad_cache"
    unset fad_cache

Optionally, if you can also source `fad` if you want `fad` to be a shell
function instead of an executable.

You can tweak initialization code. For instance, if you want to use "c"
instead of "z" to do directory jumping, you can use the alias below:

    alias c='fad_cd -d'
    # `-d' option present for bash completion
    # function fad_cd is defined in posix-alias

# MATCHING

Fad has three matching modes: default, case-insensitive, and fuzzy.

For a given set of queries (the set of command-line arguments passed to fad),
a path is a match if and only if:

1. Queries match the path in order.
2. The last query matches the last segment of the path.

If no match is found, fad will try the same process ignoring case. If still no
match is found, fad will allow extra characters to be placed between query
characters for fuzzy matching.

Tips:

* If you want your last query not to match the last segment of the path, append
  `/' as the last query.
* If you want your last query to match the end of the filename, append `$' to
  the last query.

# COMPATIBILITY

Fad's basic functionalities are POSIX compliant, meaning that you should be
able to use fad in all POSIX compliant shells. Your shell need to support
command substitution in $PS1 in order for fad to automatically track your
commands and files. This feature is not specified by the POSIX standard, but
it's nonetheless present in many POSIX compliant shells. In shells without
prompt command or prompt command substitution (tcsh for instance), you can add
entries manually with "fad -A". You are very welcomed to contribute shell
initialization code for not yet supported shells.

# TAB COMPLETION

Fad offers two completion modes, command mode completion and word mode
completion. Command mode completion works in bash and zsh. Word mode
completion only works in zsh.

Command mode completion is just like completion for any other commands. It is
triggered when you hit tab on a fad command or its aliases. Under this mode
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

There are also three zle widgets: "fad-complete", "fad-complete-f",
"fad-complete-d". You can bind them to keybindings you like:

    bindkey '^X^A' fad-complete    # C-x C-a to do fad-complete (fils and directories)
    bindkey '^X^F' fad-complete-f  # C-x C-f to do fad-complete-f (only files)
    bindkey '^X^D' fad-complete-d  # C-x C-d to do fad-complete-d (only directories)

# BACKENDS

Fad can take advantage of different sources of recent / frequent files. Most
desktop environments (such as OS X and Gtk) and some editors (such as Vim) keep
a list of accessed files. Fad can use them as additional backends if the data
can be converted into fad's native format. Below is a list of available
backends.

* spotlight: OSX spotlight, provides entries that are changed today or opened
  within the past month

* recently-used: GTK's recently-used file (Usually available on Linux)

* current: Provides everything in $PWD (whereever you are executing `fad`)

* viminfo: Vim's editing history, useful if you want to define an alias just
  for editing things in vim

You can define your own backend by declaring a function by that name in your
`.fadrc`. You can set default backend with `_FAD_BACKENDS` variable in our
`.fadrc`.

# TWEAKS

Upon every execution, fad will source "/etc/fadrc" and "$HOME/.fadrc" if
they are present. Below are some variables you can set:

    $_FAD_DATA
    Path to the fad data file, default "$HOME/.fad".

    $_FAD_BLACKLIST
    List of blacklisted strings. Commands matching them will not be processed.
    Default is "--help".

    $_FAD_SHIFT
    List of all commands that needs to be shifted, defaults to "sudo busybox".

    $_FAD_IGNORE
    List of all commands that will be ignored, defaults to "fad ls echo".

    $_FAD_TRACK_PWD
    Fad defaults to track your "$PWD". Set this to 0 to disable this behavior.

    $_FAD_AWK
    Which awk to use. fad can detect and use a compatible awk.

    $_FAD_SINK
    File to log all STDERR to, defaults to "/dev/null".

    $_FAD_MAX
    Max total score / weight, defaults to 2000.

    $_FAD_SHELL
    Which shell to execute. Some shells will run faster than others. fad
    runs faster with dash and ksh variants.

    $_FAD_BACKENDS
    Default backends.

    $_FAD_RO
    If set to any non-empty string, fad will not add or delete entries from
    database. You can set and export this variable from command line.

    $_FAD_FUZZY
    Level of "fuzziness" when doing fuzzy matching. More precisely, the number of
    characters that can be skipped to generate a match. Set to empty or 0 to
    disable fuzzy matching. Default value is 2.

    $_FAD_VIMINFO
    Path to .viminfo file for viminfo backend, defaults to "$HOME/.viminfo"

    $_FAD_RECENTLY_USED_XBEL
    Path to XDG recently-used.xbel file for recently-used backend, defaults to
    "$HOME/.local/share/recently-used.xbel"

# DEBUGGING

Fad is hosted on GitHub: https://github.com/clvv/fad

If fad does not work as expected, please file a bug report on GitHub describing
the unexpected behavior along with your OS version, shell version, awk version,
sed version, and a log file.

You can set `_FAD_SINK` in your `.fadrc` to obtain a log.

    _FAD_SINK="$HOME/.fad.log"

# COPYING

Fad is originally written based on code from z (https://github.com/rupa/z) by
rupa deadwyler under the WTFPL license. Most if not all of the code has been
rewritten. Fad is licensed under the "MIT/X11" license.

