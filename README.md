# Fad

Fad (pronounced similar to "fast") is a command-line productivity booster.
Fad offers quick access to files and directories for POSIX shells. It is
inspired by tools like [autojump](https://github.com/joelthelion/autojump),
[z](http://github.com/rupa/z) and [v](https://github.com/rupa/v). Fad keeps
track of files and directories you have accessed, so that you can quickly
reference them in the command line.

The name fad comes from the default suggested aliases `f`(files),
`a`(files/directories), `s`(show/search/select), `d`(directories).

Fad ranks files and directories by "frecency," that is, by both "frequency" and
"recency." The term "frecency" was first coined by Mozilla and used in Firefox
([link](https://developer.mozilla.org/en/The_Places_frecency_algorithm)).

# Introduction

If you use your shell to navigate and launch applications, fad can help you do
it more efficiently. With fad, you can open files regardless of which
directory you are in. Just with a few key strings, fad can find a "frecent"
file or directory and open it with command you specify. Below are some
hypothetical situations, where you can type in the command on the left and fad
will "expand" your command into the right side. Pretty magic, huh?

```
  v def conf       =>     vim /some/awkward/path/to/type/default.conf
  j abc            =>     cd /hell/of/a/awkward/path/to/get/to/abcdef
  m movie          =>     mplayer /whatever/whatever/whatever/awesome_movie.mp4
  o eng paper      =>     xdg-open /you/dont/remember/where/english_paper.pdf
  vim `f rc lo`    =>     vim /etc/rc.local
  vim `f rc conf`  =>     vim /etc/rc.conf
```

Fad comes with some useful aliases by default:

```sh
alias a='fad -a'        # any
alias s='fad -si'       # show / search / select
alias d='fad -d'        # directory
alias f='fad -f'        # file
alias sd='fad -sid'     # interactive directory selection
alias sf='fad -sif'     # interactive file selection
alias z='fad_cd -d'     # cd, same functionality as j in autojump
alias zz='fad_cd -d -i' # cd with interactive selection
```

Fad will smartly detect when to display a list of files or just the best
match. For instance, when you call fad in a subshell with some search
parameters, fad will only return the best match. This enables you to do:

```sh
mv update.html `d www`
cp `f mov` .
```

# Install

Fad is available in various package managers. Please check
[the wiki page](https://github.com/clvv/fad/wiki/Installing-via-Package-Managers)
for an up-to-date list.

You can also manually obtain a copy of fad.

Download fad 1.0.1 from GitHub:
[zip](https://github.com/clvv/fad/zipball/1.0.1),
[tar.gz](https://github.com/clvv/fad/tarball/1.0.1).

Fad is a self-contained POSIX shell script that can be either sourced or
executed. A Makefile is provided to install `fad` and `fad.1` to desired
places.

System-wide install:

    make install

Install to $HOME:

    PREFIX=$HOME make install

Or alternatively you can just copy `fad` to anywhere you like (preferably
under some directory in `$PATH`).

To get fad working in a shell, some initialization code must be run. Put the
line below in your shell rc.

```sh
eval "$(fad --init auto)"
```

This will setup a command hook that executes on every command and advanced tab
completion for zsh and bash.

If you want more control over what gets into your shell environment, you can
pass customized set of arguments to `fad --init`.

```
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
```

Example for a minimal zsh setup (no tab completion):

```sh
eval "$(fad --init posix-alias zsh-hook)"
```

Note that this method will slightly increase your shell start-up time, since
calling binaries has overhead. You can cache fad init code if you want minimal
overhead. Example code for bash (to be put into .bashrc):

```sh
fad_cache="$HOME/.fad-init-bash"
if [ "$(command -v fad)" -nt "$fad_cache" -o ! -s "$fad_cache" ]; then
  fad --init posix-alias bash-hook bash-ccomp bash-ccomp-install >| "$fad_cache"
fi
source "$fad_cache"
unset fad_cache
```

Optionally, if you can also source `fad` if you want `fad` to be a shell
function instead of an executable.

You can tweak initialization code. For instance, if you want to use "c"
instead of "z" to do directory jumping, you can use the alias below:

```sh
alias c='fad_cd -d'
# `-d` option present for bash completion
# function fad_cd is defined in posix-alias
```

After you first installed fad, open some files (with any program) or `cd`
around in your shell. Then try some examples below.

# Examples

```sh
f foo           # list frecent files matching foo
a foo bar       # list frecent files and directories matching foo and bar
f js$           # list frecent files that ends in js
f -e vim foo    # run vim on the most frecent file matching foo
mplayer `f bar` # run mplayer on the most frecent file matching bar
z foo           # cd into the most frecent directory matching foo
open `sf pdf`   # interactively select a file matching pdf and launch `open`
```

You should add your own aliases to fully utilize the power of fad. Here are
some examples to get you started:

```sh
alias v='f -e vim' # quick opening files with vim
alias m='f -e mplayer' # quick opening files with mplayer
alias o='a -e xdg-open' # quick opening files with xdg-open
```

If you're using bash, you have to call `_fad_bash_hook_cmd_complete` to make
completion work. For instance:

    _fad_bash_hook_cmd_complete v m j o

You could select an entry in the list of matching files.

# Matching

Fad has three matching modes: default, case-insensitive, and fuzzy.

For a given set of queries (the set of command-line arguments passed to fad),
a path is a match if and only if:

1. Queries match the path *in order*.
2. The last query matches the *last segment* of the path.

If no match is found, fad will try the same process ignoring case. If still no
match is found, fad will allow extra characters to be placed between query
characters for fuzzy matching.

Tips:

* If you want your last query not to match the last segment of the path, append
  `/` as the last query.
* If you want your last query to match the end of the filename, append `$` to
  the last query.

# How It Works

When you run fad init code or source `fad`, fad adds a hook which will be
executed whenever you execute a command. The hook will scan your commands'
arguments and determine if any of them refer to existing files or directories.
If yes, fad will add them to the database.

# Compatibility

Fad's basic functionalities are POSIX compliant, meaning that you should be
able to use fad in all POSIX compliant shells. Your shell need to support
command substitution in `$PS1` in order for fad to automatically track your
commands and files. This feature is not specified by the POSIX standard, but
it's nonetheless present in many POSIX compliant shells. In shells without
prompt command or prompt command substitution (csh for instance), you can add
entries manually with `fad -A`. You are very welcomed to contribute shell
initialization code for not yet supported shells.

Fad has been tested on the following shells: bash, zsh, mksh, pdksh, dash,
busybox ash, FreeBSD 9 /bin/sh and OpenBSD /bin/sh.

# Synopsis

    fad [options] [query ...]
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

    fad [-A|-D] [paths ...]
        -A    add paths
        -D    delete paths

# Tab Completion

Fad offers two completion modes, command mode completion and word mode
completion. Command mode completion works in bash and zsh. Word mode
completion only works in zsh.

Command mode completion is just like completion for any other commands. It is
triggered when you hit tab on a `fad` command or its aliases. Under this mode
your queries can be separated by a space. Tip: if you find that the completion
result overwrites your queries, type an extra space before you hit tab.

Word mode completion can be triggered on *any* command. Word completion is
triggered by any command line argument that starts with `,` (all), `f,`
(files), or `d,` (directories), or that ends with `,,` (all), `,,f` (files), or
`,,d` (directories). Examples:

    $ vim ,rc,lo<Tab>
    $ vim /etc/rc.local

    $ mv index.html d,www<Tab>
    $ mv index.html /var/www/

There are also three zle widgets: `fad-complete`, `fad-complete-f`,
`fad-complete-d`. You can bind them to keybindings you like:

```sh
bindkey '^X^A' fad-complete    # C-x C-a to do fad-complete (fils and directories)
bindkey '^X^F' fad-complete-f  # C-x C-f to do fad-complete-f (only files)
bindkey '^X^D' fad-complete-d  # C-x C-d to do fad-complete-d (only directories)
```

# Backends

Fad can take advantage of different sources of recent / frequent files. Most
desktop environments (such as OS X and Gtk) and some editors (such as Vim) keep
a list of accessed files. Fad can use them as additional backends if the data
can be converted into fad's native format. Below is a list of available
backends.

```
`spotlight`
OSX spotlight, provides entries that are changed today or opened within the
past month

`recently-used`
GTK's recently-used file (Usually available on Linux)

`current`
Provides everything in $PWD (whereever you are executing `fad`)

`viminfo`
Vim's editing history, useful if you want to define an alias just for editing
things in vim
```

You can define your own backend by declaring a function by that name in your
`.fadrc`. You can set default backend with `_FASD_BACKENDS` variable in our
`.fadrc`.

Fad can mimic [v](http://github.com/rupa/v)'s behavior by this alias:

```sh
alias v='f -t -e vim -b viminfo'
```

# Tweaks

Some shell variables that you can set before sourcing `fad`. You can set them
in `$HOME/.fadrc`

```
$_FASD_DATA
Path to the fad data file, default "$HOME/.fad".

$_FASD_BLACKLIST
List of blacklisted strings. Commands matching them will not be processed.
Default is "--help".

$_FASD_SHIFT
List of all commands that needs to be shifted, defaults to "sudo busybox".

$_FASD_IGNORE
List of all commands that will be ignored, defaults to "fad ls echo".

$_FASD_TRACK_PWD
Fad defaults to track your "$PWD". Set this to 0 to disable this behavior.

$_FASD_AWK
Which awk to use. Fad can detect and use a compatible awk.

$_FASD_SINK
File to log all STDERR to, defaults to "/dev/null".

$_FASD_MAX
Max total score / weight, defaults to 2000.

$_FASD_SHELL
Which shell to execute. Some shells will run faster than others. fad
runs faster with dash and ksh variants.

$_FASD_BACKENDS
Default backends.

$_FASD_RO
If set to any non-empty string, fad will not add or delete entries from
database. You can set and export this variable from command line.

$_FASD_FUZZY
Level of "fuzziness" when doing fuzzy matching. More precisely, the number of
characters that can be skipped to generate a match. Set to empty or 0 to
disable fuzzy matching. Default value is 2.

$_FASD_VIMINFO
Path to .viminfo file for viminfo backend, defaults to "$HOME/.viminfo"

$_FASD_RECENTLY_USED_XBEL
Path to XDG recently-used.xbel file for recently-used backend, defaults to
"$HOME/.local/share/recently-used.xbel"

```

# Debugging

If fad does not work as expected, please file a bug report describing the
unexpected behavior along with your OS version, shell version, awk version, sed
version, and a log file.

You can set `_FASD_SINK` in your `.fadrc` to obtain a log.

```sh
_FASD_SINK="$HOME/.fad.log"
```

# COPYING

Fad is originally written based on code from [z](https://github.com/rupa/z) by
rupa deadwyler under the WTFPL license. Most if not all of the code has been
rewritten. Fad is licensed under the "MIT/X11" license.

