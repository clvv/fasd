# f

`f` is a tool for quick access to files in bash and zsh. It is inspired by
tools like autojump, z and v. `f` keeps track of files you have accessed, so
that you can quickly reference them in the command line.

`f` ranks file by "frecency." `f` uses the same rank algorithm used by `z`. You
can read more about it [here](https://github.com/rupa/z/wiki/frecency)

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
with mawk at the moment).

To use `f`, just source `f.sh` somewhere in your shell with:

```sh
  source f.sh
```

Of course, you should put it into your shell rc once you've decided to use it.

# Examples

```sh
  f foo # list recent files mathcing foo
  f foo bar # list recent files mathcing foo and bar
  f -e vim foo # run vim on the most frecent file matching foo
  f bar -e mplayer # run mplayer on the most frecent file matching bar
  f -d foo -e cd # cd into the most frecent directory matching foo
```

The power of f is that you can add your own useful aliases:

```sh
  alias v='f -f -e vim' # quick opening files with vim
  alias m='f -f -e mplayer' # quick opening files with mplayer
  alias j='f -d -e cd' # quick cd into directories, mimicing autojump and z
  alias o='f -e xdg-open' # quick opening files with xdg-open
```

# Options

```
  -h show a brief help message
  -l list only
  -e set command to execute on the result file
  -a match files and directories
  -d match directories only
  -f match files only
  -r match by rank only
  -t match by recent access only
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

