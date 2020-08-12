# dotfiles
[crossjam](https://github.com/crossjam) specific startup files for
various operating systems, shells, and applications.

This branch is specific to installing from a work environment login
with just enough support to install and maintain these dotfiles.

## Bootstrapping

Assuming `ssh -T git@github.com` auths as `crossjam`

```
$ GIT_SSH_COMMAND="ssh -i ~/.ssh/crossjam_host.pub -o IdentitiesOnly=yes" git clone git@githb.com:crossjam/dotfiles.git
$ cd dotfiles
$GIT_SSH_COMMAND="ssh -i ~/.ssh/crossjam_host.pub -o IdentitiesOnly=yes" git checkout -b bmdmc origin/bmdmc
$ cd ..
$ python3 -m venv ~/venv/homely
$ source ~/venv/homely/bin/activate
$ python3 -m pip install homely
$ GIT_SSH_COMMAND="ssh -i ~/.ssh/crossjam_host.pub -o IdentitiesOnly=yes" homely add dotfiles

# edit .gitconfig.crossjam to point to the crossjam_host.pub key
```

## Bootstrapping to a remote machine

Assuming there’s already an account setup `bdennis@remote_host.example.com`, with the
`.ssh` directory existing.

```
# From the local machine, assume crossjam_dotfiles.pub auths as
# crossjam on GitHub
$ scp ~/.ssh/crossjam_dotfiles.pub bdennis@remote_host.example.com:.ssh/

# Now to the remote machine
$ ssh -A bdennis@remote_host.example
$ export GIT_SSH_COMMAND="ssh -i ~/.ssh/crossjam_dotfiles.pub -o IdentitiesOnly=yes"
$ git clone git@github.com:crossjam/dotfiles.git
$ bash ./dotfiles/install_dotfiles.sh

# To support editing, push, and pull of the dotfiles repo
# edit .gitconfig.crossjam to point to the crossjam_dotfiles.pub key
```
