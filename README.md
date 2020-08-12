# dotfiles
[crossjam](https://github.com/crossjam) specific startup files for
various operating systems, shells, and applications

## Bootstrapping

Assuming there’s already an account setup `bdennis@host.example`, with the
`.ssh` directory existing.

```
# From the local machine, assume crossjam\_host.pub auths as crossjam
scp ~/.ssh/crossjam\_local\_host.pub bdennis@remote\_host.example:.ssh/

# Now to the remote machine
$ ssh -A bdennis@remote\_host.example
$ mkdir venv
$ GIT\_SSH\_COMMAND="ssh -i ~/.ssh/crossjam\_host.pub -o IdentitiesOnly=yes" git clone git@githb.com:crossjam/dotfiles.git
$ cd dotfiles
$GIT\_SSH\_COMMAND="ssh -i ~/.ssh/crossjam\_host.pub -o IdentitiesOnly=yes" git checkout -b bmdmc origin/bmdmc
$ cd ..
$ python3 -m venv ~/venv/homely
$ source ~/venv/homely/bin/activate
$ python3 -m pip install homely
$ GIT\_SSH\_COMMAND="ssh -i ~/.ssh/crossjam_host.pub -o IdentitiesOnly=yes" homely add dotfiles

# edit .gitconfig.crossjam to point to the crossjam\_host.pub key
```

