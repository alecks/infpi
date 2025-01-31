# `infpi`

`infpi` is a script for the University of Edinburgh's [DICE](https://computing.help.inf.ed.ac.uk/what-is-dice) system that makes installing programs from a tarball easier. The `pi` stands for 'program installer' rather than 'package manager' because it doesn't manage versioning, dependencies, uninstallation of programs, or anything really other than installation. 

## Installation

This command creates your `~/.local` directory where per-user programs are stored, installs infpi to that directory and makes it executable.

```sh
mkdir -p ~/.local/bin && curl -L "https://raw.githubusercontent.com/alecks/infpi/refs/heads/main/infpi.sh" -o ~/.local/bin/infpi && chmod +x ~/.local/bin/infpi
```

#### **IMPORTANT**: Add `~/.local/bin` to PATH.

DICE seems to have a [setpath](https://computing.help.inf.ed.ac.uk/FAQ/how-do-i-add-directory-bash-command-search-path-dice) command, but I haven't used this.

Add the following to your `~/.brc` if you use bash, the default shell for DICE, or `~/.zshrc` if you use zsh:

```sh
PATH=$HOME/.local/bin:$PATH
```

This allows you to call programs directly like `my-program` rather than `~/.local/bin/my-program`.

## Usage

Copy the URL of a package tarball and run `infpi <url>`. This will download the archive and extract it into the relevant directories.

For DICE, you are looking for an x86-64 or amd64 Linux tarball.

Here is an example which replaces DICE's default [kitty](https://github.com/kovidgoyal/kitty) terminal with the latest version:

```sh
infpi https://github.com/kovidgoyal/kitty/releases/download/v0.39.0/kitty-0.39.0-x86_64.txz
```

Or to download the latest version of [neovim](https://neovim.io):

```sh
infpi https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
```
#### Package structure

The script expects the archive to have at least a `bin` directory or at least one executable in the root. In the case that there is a bin directory, the entire archive is copied into your `~/.local` folder. If there isn't, and root executable(s) are found, they are moved to the `~/.local/bin` directory and you will be asked about the rest. 

#### Overwrites

If there are conflicts, infpi will ask you whether to overwrite **a**ll files (a), select **s**ome files interactively (s), or overwrite **n**one (n).

### Uninstalling 

If you wish to uninstall a program, infpi writes a log file to `~/.infpi/logs` which you can use to see what was installed. You can then manually delete these files (but be careful not to delete anything shared by other programs).

