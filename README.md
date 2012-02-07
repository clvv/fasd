# Fasd

`fasd` is a tool for quick access to files for POSIX shells. It is inspired by
tools like `autojump`, `z` and `v`. `fasd` keeps track of files you have accessed,
so that you can quickly reference them in the command line.

The name `fasd` comes from the defualt suggested aliases `fasd`(files),
`a`(files/directories), `s`(show/search), `d`(directories).

`fasd` ranks files and directories by "frecency," that is, by both "frequency" and
"recency." The term "frecency" was first coined by Mozilla and used in Firefox
([link](https://developer.mozilla.org/en/The_Places_frecency_algorithm)).

`fasd` uses [Bayesian Inference](https://en.wikipedia.org/wiki/Bayesian_inference)
and [Bayesian Ranking](https://github.com/clvv/f/wiki/Bayesian-Ranking) to rank
files and directories for a set of given matching patterns. "Frecency" is used
as the prior probability distribution, and a simple algorithm is used to
calculate the likelihood of the given set of patterns.

# Introduction

If you're like me, you use your shell to navigate and launch applications.
`fasd` helps you do that more efficiently. With `fasd`, you can open files
regardless of which directory you are in. Just with a few key strings, `fasd`
can find a "frecent" file or directory and open it with command you specify.
Below are some hypothetical situations, where you can type in the command on
the left and `fasd` will "expand" your command into the right side. Pretty
magic, huh?

```
  v def conf       =>     vim /some/awkward/path/to/type/default.conf
  j abc            =>     cd /hell/of/a/awkward/path/to/get/to/abcdef
  m movie          =>     mplayer /whatever/whatever/whatever/awesome_movie.mp4
  o eng paper      =>     xdg-open /you/dont/remember/where/english_paper.pdf
  vim `f rc lo`    =>     vim /etc/rc.local
  vim `f rc conf`  =>     vim /etc/rc.conf
```

`fasd` comes with four useful aliases by default:

```sh
alias a='fasd -a' # any
alias s='fasd -s' # show / search
alias d='fasd -d' # directory
alias f='fasd -f' # file
```

`fasd` will smartly detect when to display a list of files or just the best
match. For instance, when you call `fasd` in a subshell with some search
parameters, `fasd` will only return the best match. This enables you to do:

```sh
mv update.html `d www`
cp `f mov` .
```

# Install

There are two ways to get `fasd` working in your shell.

1. You can directly source `fasd` in your POSIX complaint shell.

```sh
source fasd
```

This will set some variable options, add default aliases to your shell as well
as set up a prompt command to be executed after every command you type. It will
also set up advanced tab completion if you're using zsh or bash.

2. You can use `fasd` as an external executable.

Put `fasd` in your $PATH, for instance:

```
ln -s /path/to/fasd ~/bin/fasd
```

Then put lines below in your shell rc depending on which shell you're using.

```sh
# .bashrc
eval "$(fasd --init-bash)"
eval "$(fasd --init-alias)"
```

```sh
# .zshrc
eval "$(fasd --init-zsh)"
eval "$(fasd --init-alias)"
```

```sh
# .profile
# for other posix compliant shells: ksh, mksh, busybox sh, etc.
eval "$(fasd --init-posix)"
eval "$(fasd --init-alias)"
```

These will setup advanced tab completion and a command hook that will be
executed on every command.

After you first installed `fasd`, open some files (with any program) or `cd`
around in your shell. Then try some examples below.

# Examples

```sh
f foo # list recent files mathcing foo
a foo bar # list recent files and directories mathcing foo and bar
f -e vim foo # run vim on the most frecent file matching foo
f bar -e mplayer # run mplayer on the most frecent file matching bar
d -e cd foo # cd into the most frecent directory matching foo
```

You should add your own aliases to fully utilize the power of `fasd`. Here are
some examples to get you started:

```sh
alias v='f -e vim' # quick opening files with vim
alias m='f -e mplayer' # quick opening files with mplayer
alias o='a -e xdg-open' # quick opening files with xdg-open
```

If you're using bash, you have to call `_f_bash_hook_cmd_complete` to make
completion work. For instance:

```bash
_f_bash_hook_cmd_complete v m j o
```

# How It Works

When you source `fasd`, `fasd` adds a hook which will be executed whenever
you execute a command. The hook will scan your commands' arguments and
determine if any of them refer to existing files or directories. If yes, `fasd`
will add them to the database.

When you run `fasd` with search arguments, `fasd` uses [Bayesian
Ranking](https://github.com/clvv/f/wiki/Bayesian-Ranking) to find the best
match.

# Compatibility

`fasd`'s basic functionalities are POSIX compliant, meaning that you should be
able to use `fasd` in all POSIX compliant shells. Your shell need to support
command substitution in `$PS1` in order for `fasd` to automatically track your
commands and files. This feature is not specified by the POSIX standard, but
it's nonetheless present in many POSIX compliant shells. If you use some shell
other than `bash`, `zsh` or `ksh` and `fasd` does not work out of the box for
you, you can try calling `_f_ps1_install` to manually install the hook to your
`$PS1`.

# Synopsis

```
fasd [options] [query ...]
  options:
    -s        show list of files with their ranks
    -l        list paths only
    -i        interactive mode
    -e <cmd>  set command to execute on the result file
    -b <name> only use <name> backend
    -B <name> add addition backend <name>
    -a        match files and directories
    -d        match directories only
    -f        match files only
    -r        match by rank only
    -t        match by recent access only
    -h        show a brief help message
```

# Tab Completion

`fasd` offers two completion modes, command mode completion and word mode
completion.

Command mode completion is just like completion for any other commands. It is
triggered when you hit tab on a `fasd` command or its aliases. Under this mode
your queries can be separated by a space. Tip: if you find that the completion
result overwrites your queries, type an extra space before you hit tab.

Word mode completion can be triggered on *any* command. This can be a powerful
feature if you make good use of it. Word completion is triggered by any command
line argument that starts with `,`(a comma). Example:

```sh
$ vim ,rc,lo<Tab>
$ vim /etc/rc.local
```

If you use zsh, word completion is enabled by default. There're also three zle
widgets: `f-complete`, `f-complete-f`, `f-complete-d`. You can bind them to
keybindings you like:

```sh
bindkey '^X^A' f-complete    # C-x C-a to do f-complete (fils and directories)
bindkey '^X^F' f-complete-f  # C-x C-f to do f-cmplete-f (only files)
bindkey '^X^D' f-complete-d  # C-x C-d to do f-complete-d (only directories)
```

If you use bash, you can turn on this *experimental feature* by calling
`_f_bash_hook_word_complete_wrap_all` after sourcing `fasd` *and* after any
bash completion setup. This will alter your existing completion setup, so you
might get a *broken* completion system.

# Backends

Fasd can take advantage of different sources of recent / frequent files. Most
desktop environments (like Gtk) and some editors (like Vim) keep a list of
accessed files. Fasd can use them as additional backends if the data can be
converted into fasd's native format. As of now, fasd supports Gtk's
`recently-used.xbel` and Vim's `viminfo` backends. You can define your own
backend by declaring a function by that name in your `.fasdrc`. You set defualt
backend with `_F_BACKENDS` variable in our `.fasdrc`.

Fasd can mimic [v](http://github.com/rupa/v)'s behavior by this alias:

```sh
alias v='f -e vim -b viminfo'
```

# Tweaks

Some shell variables that you can set before sourcing `fasd`. You can set them
in `$HOME/.fasdrc`

```
$_F_DATA
Path to the f data file, default "$HOME/.f".

$_F_BLACKLIST
List of blacklisted strings. Commands matching them will not be processed.
Default is "--help".

$_F_SHIFT
List of all commands that needs to be shifted, defaults to "sudo busybox".

$_F_IGNORE
List of all commands that will be ignored, defaults to "fasd cd ls echo".

$_F_TRACK_PWD
f defaults to track your "$PWD". Set this to 0 to disable this behavior.

$_F_AWK
Which awk to use. f can detect and use a compatible awk.

$_F_SINK
File to log all STDERR to, defaults to "/dev/null".

$_F_MAX
Max total score / weight, defaults to 2000.

$_F_SHELL
Which shell to execute. Some shells will run faster than others. fasd
is faster with ksh variants.

$_F_BACKENDS
Defualt backends.
```

# Debugging

If `fasd` does not work as expected, please file a bug report describing the
unexpected behavior along with your OS version, shell version, awk version, sed
version, and a log file.

You can set `_F_SINK` to obtain a log.

```sh
export _F_SINK="$HOME/.f.log"
```

# TODO

1. Tests!
2. Multiple searches, parameters separated by `-`.
3. More backends: `rencently-used.xbel`, `.viminfo`, etc.
4. Code refactoring, more modular setup.

# Acknowledgements

`fasd` is written based on existing code from [z](https://github.com/rupa/z).

