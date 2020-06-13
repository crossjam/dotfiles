import shutil

from pathlib import Path

from homely.files import symlink, mkdir

symlink("screenrc", ".screenrc")
symlink("bashrc", ".bashrc")
symlink("bash_profile", ".bash_profile")
symlink("gitignore", ".gitignore")

home_dir = Path.home()
emacs_init_dir = home_dir / ".emacs.d"

if not emacs_init_dir.exists():
    mkdir(str(emacs_init_dir))

symlink("emacs_init.el", str(emacs_init_dir / "init.el"))

if not (home_dir / ".gitconfig").exists():
    symlink("gitconfig", ".gitconfig")

if not (home_dir / ".gitconfig.crossjam").exists():
    shutil.copy2(
        str(home_dir / "dotfiles" / "gitconfig.crossjam"),
        str(home_dir / ".gitconfig.crossjam"),
    )
