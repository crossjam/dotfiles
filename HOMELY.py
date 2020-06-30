import shutil
import time

from pathlib import Path

from homely.files import symlink, mkdir
from homely.ui import head, note

home_dir = Path.home()
emacs_init_dir = home_dir / ".emacs.d"
dotfiles_old_dir = home_dir / "dotfiles.old"

mkdir("~/.emacs.d")

if not dotfiles_old_dir.exists():
    dotfiles_old_dir.mkdir()

INSTALL_DOTFILES = [
    ("screenrc", ".screenrc"),
    ("bashrc", ".bashrc"),
    ("bash_profile", ".bash_profile"),
    ("gitconfig", ".gitconfig"),
    ("gitignore", ".gitignore"),
    ("emacs_init.el", "~/.emacs.d/init.el"),
]

with head("Processing potentially preexisting targets."):
    for dot_file, orig_file in INSTALL_DOTFILES:
        orig_file_path = Path(orig_file).expanduser()
        dot_file_path = Path("~/dotfiles").expanduser() / dot_file
        note(f"Checking {orig_file_path}")
        if orig_file_path.exists() and not (orig_file_path.samefile(dot_file_path)):
            dst_file_path = (dotfiles_old_dir / f"{orig_file_path.name}_{int(time.time())}")            
            note(f"Original file: {orig_file_path} -> {dst_file_path}")
            shutil.move(orig_file_path, dst_file_path)

with head("Installing dotfiles."):
    for dot_file, orig_file in INSTALL_DOTFILES:
        symlink(dot_file, orig_file)

