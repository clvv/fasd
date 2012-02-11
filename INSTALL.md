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

These will setup a command hook that executes on every command and advanced tab
completion for zsh and bash.

