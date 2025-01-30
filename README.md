# `infpi`

`infpi` is a script for the University of Edinburgh's [DICE](https://computing.help.inf.ed.ac.uk/what-is-dice) system that makes installing programs from a tarball easier. The `pi` stands for 'program installer' rather than 'package manager' because it doesn't manage versioning, dependencies, uninstallation of programs, or anything really other than installation. 

## Installation

```sh
curl -L "https://raw.githubusercontent.com/alecks/infpi/refs/heads/main/infpi.sh" -o ~/.local/bin/infpi && chmod +x ~/.local/bin/infpi
```

#### **IMPORTANT**: Add `~/.local/bin` to PATH.

DICE seems to have a [setpath](https://computing.help.inf.ed.ac.uk/FAQ/how-do-i-add-directory-bash-command-search-path-dice) command, but I haven't used this.

Add the following to your `~/.brc` if you use bash, the default shell for DICE, or `~/.zshrc` if you use zsh:

```sh
PATH=$HOME/.local/bin:$PATH
```

This allows you to call programs directly like `my-program` rather than `~/.local/bin/my-program`.

## Usage

Copy the URL of a package tarball and run `infpi <url>`. This will download the archive and extract it into the relevant directories, overwriting if there are any changes in existing files.

For DICE, you are looking for an x86-64 or amd64 Linux tarball.

Here is an example which replaces DICE's default [kitty](https://github.com/kovidgoyal/kitty) terminal with the latest version:

```sh
infpi https://github.com/kovidgoyal/kitty/releases/download/v0.39.0/kitty-0.39.0-x86_64.txz
```

Or to download the latest version of [neovim](https://neovim.io):

```sh
infpi https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
```

### Uninstalling 

If you wish to uninstall a program, `infpi` writes a log file to `~/.infpi/logs` which you can use to see what was installed. You can then manually delete these files (but be careful not to delete anything shared by other programs).

## Safety

This is designed to aid installation of a small number of programs onto DICE machines, as you usually don't need to install *that* many on top of what is provided. It overwrites everything it can see, so if two programs share the same libraries, it will simply replace the old files with the new ones.

