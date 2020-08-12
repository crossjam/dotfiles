# dotfiles
[crossjam](https://github.com/crossjam) specific startup files for
various operating systems, shells, and applications.

This branch is specific to installing from a work environment login
with just enough support to install and maintain these dotfiles.

## Bootstrapping

Assuming there’s already an account setup `bdennis@host.example`, with the
`.ssh` directory existing.

```
# From the local machine, assume crossjam_host.pub auths as crossjam
scp ~/.ssh/crossjam_local_host.pub bdennis@remote_host.example:.ssh/

# Now to the remote machine
$ ssh -A bdennis@remote_host.example
$ mkdir venv
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

