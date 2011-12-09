# f

`f` is a tool for quick access to files in bash and zsh. It is inspired by
tools like autojump, z and v. `f` keeps track of files you have accessed, so
that you can quickly reference them in the command line.

`f` ranks files by "frecency." `f` uses the same rank algorithm used by `z`.
You can read more about it [here](https://github.com/rupa/z/wiki/frecency)

# Introduction

In short, with `f` you can save yourself so much time typing. Below are some
hypothetical situations, where you can type in the left command and `f` will
translate into the right side. Pretty magic, huh?

```
  v whoa.conf      =>     vim /some/awkward/path/to/type/whoa.conf
  j awk path       =>     cd /hell/of/a/awkward/path/to/get/to
  m movie          =>     mplayer /whatever/whatever/whatever/awesome_movie.mp4
  o english paper  =>     xdg-open /you/dont/remember/where/english_paper.pdf
```

# Install

`f` can work with bash and zsh. You will also need gawk or nawk (original-awk
for debian-like). Optionally, readlink from GNU coreutils is also recommended.

`f` should work out of the box on most Linux and BSD distros, including OS X.
If you're on Debian, Ubuntu or Mint, please make sure that you have some other
`awk` installed other than the default `mawk` (unfortunately `f` does not work
with `mawk` at the moment).

To use `f`, just source `f.sh` somewhere in your shell with:

```sh
  source f.sh
```

Of course, you should put it into your shell rc once you've decided to use it.

After you first installed `f`, open some files (with any program) and cd around
in your shell. Then try some examples below.

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
  alias j='f -d -e cd' # quick cd into directories, mimicing autojump and z
  alias o='f -e xdg-open' # quick opening files with xdg-open
```

# Synopsis

```
f [options] [query ..]
  options:
    -l, --list       list only
    -e, --exec CMD   set command to execute on the result file
    -a, --any        match files and directories
    -d, --directory  match directories only
    -f, --file       match files only
    -r, --rank       match by rank only
    -t, --recent     match by recent access only
    -h, --help       show a brief help message
```

# Tweaks

Here are some shell variables that you can set before sourcing `f`.

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

$_F_TRACK_PWD
If set to any non-empty string, f will track "$PWD". This is useful when you
want to replace autojump or z with f.

$_F_AWK
Which awk to use. `f` can detact and use a compatible awk.
```

# TODO

Here are some features that I have thought of implementing.

0. Fix issue with space in path.
1. Tests!
2. zsh `alias -s` style execution, simply do `f arg`.
3. Option to just list matches without ranks (good for "piping").
4. Multiple searches, parameters delimited by `-` or `--`.
5. gtk `rencently-used.xbel` backend.
6. Code refactoring, more modulous setup.
7. Port `f` "into" other tools like vim (is it possible?).
8. Standalone version?

# Acknowledgements

`f` is written based on existing code from [z](https://github.com/rupa/z).

