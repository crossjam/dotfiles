# dotfiles
[crossjam](https://github.com/crossjam) specific startup files for
various operating systems, shells, and applications.

This branch is specific to installing from a work environment login
with just enough support to install and maintain these dotfiles.

## Bootstrapping

Assuming `ssh -T git@github.com` auths as `crossjam`

```
# Make sure we only use the github identity
$ git clone git@github.com:crossjam/dotfiles.git
$ dotfiles/install_dotfiles.sh
```

## Bootstrapping to a remote machine

Assuming there’s already an account setup `crossjam@remote_host.example.com`, with the
`.ssh` directory existing.

```
# From the local machine, assume crossjam_local_host.pub auths as crossjam
ssh-add ~/.ssh/crossjam_local_host.ecdsa
scp ~/.ssh/crossjam_local_host.pub crossjam@remote_host.example:.ssh/dotfiles.pub

# Now to the remote machine
$ ssh -A crossjam@remote_host.example.com
$ export GIT_SSH_COMMAND="ssh -i ~/.ssh/dotfiles.pub -o IdentitiesOnly=yes"
$ git clone git@github.com:crossjam/dotfiles.git
$ /bin/bash ./dotfiles/install_dotfiles.sh
```
