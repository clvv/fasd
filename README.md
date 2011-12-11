# F

`f` is a tool for quick access to files in bash and zsh. It is inspired by
tools like `autojump`, `z` and `v`. `f` keeps track of files you have accessed,
so that you can quickly reference them in the command line.

`f` ranks files by "frecency," that is, by both "frequency" and "recency." The
term "frecency" was first coined by Mozilla and used in Firefox
([link](https://developer.mozilla.org/en/The_Places_frecency_algorithm)). `f`
uses the ranking algorithm used by `z`. You can read more about it
[here](https://github.com/rupa/z/wiki/frecency).

# Introduction

If you're like me, you use your shell to navigate and launch applications. `f`
helps you do that more efficiently. With `f`, you can open files regardless of
which directory you are in. Just with a few key strings, `f` can find
a "frecent" file or directory and open it with command you specify. Below are
some hypothetical situations, where you can type in the command on the left and
`f` will "expand" your command into the right side. Pretty magic, huh?

```
  v def conf       =>     vim /some/awkward/path/to/type/default.conf
  j abc            =>     cd /hell/of/a/awkward/path/to/get/to/abcdef
  m movie          =>     mplayer /whatever/whatever/whatever/awesome_movie.mp4
  o eng paper      =>     xdg-open /you/dont/remember/where/english_paper.pdf
```

# Install

`f` can work with both `bash` and `zsh`. You will also need `gawk` or `nawk`
(`original-awk` for debian-like). Preferably, you should have `gawk` and GNU
version of `readlink`.

`f` should work out of the box on most Linux and BSD distros. But if `f` does
not work for you, please try installing `gawk` and updating your shell to
a newer version.

To use `f`, just source `f.sh`:

```sh
source f.sh
```

Of course, you should put it into your shell rc file once you've decided to use
it.

After you first installed `f`, open some files (with any program) and `cd`
around in your shell. Then try some examples below.

# Examples

```sh
f foo # list recent files mathcing foo
f foo bar # list recent files mathcing foo and bar
f -e vim foo # run vim on the most frecent file matching foo
f bar -e mplayer # run mplayer on the most frecent file matching bar
f -d -e cd foo # cd into the most frecent directory matching foo
```

You should add your own aliases to fully utilize the power of `f`. Here are
some examples to get you started:

```sh
alias v='f -f -e vim' # quick opening files with vim
alias m='f -f -e mplayer' # quick opening files with mplayer
alias j='f -d -e cd' # quick cd into directories, mimicking autojump and z
alias o='f -e xdg-open' # quick opening files with xdg-open
```

# Synopsis

```
f [options] [query ..]
  options:
    -s, --show       show list of files with their ranks
    -l, --list       list paths only
    -e, --exec CMD   set command to execute on the result file
    -a, --any        match files and directories
    -d, --directory  match directories only
    -f, --file       match files only
    -r, --rank       match by rank only
    -t, --recent     match by recent access only
    -h, --help       show a brief help message
```

# Tweaks

Some shell variables that you can set before sourcing `f`.

```
$_F_DATA
Path to the f data file, default "$HOME/.f".

$_F_CMD
Command to call f, default "f".

$_F_BLACKLIST
List of blacklisted strings. Commands matching them will not be processed.
Default is (--help).

$_F_SHIFT
List of all commands that needs to be shifted, defaults to (sudo busybox).

$_F_IGNORE
List of all commands that will be ignored, defaults to (_f $_F_CMD ls echo).

$_F_TRACK_PWD
If set to any non-empty string, f will track "$PWD". This is useful when you
want f to replace autojump or z with f.

$_F_AWK
Which awk to use. f can detect and use a compatible awk.
```

# TODO

1. Tests!
2. Zsh `alias -s` style execution, simply do `f arg`.
3. Multiple searches, parameters delimited by `-` or `--`.
4. More backends: `rencently-used.xbel`, `.viminfo`.
5. Code refactoring, more modular setup.

# Acknowledgements

`f` is written based on existing code from [z](https://github.com/rupa/z).

