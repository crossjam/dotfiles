import platform
import shutil
import tempfile
import time

from pathlib import Path

from homely.files import symlink, mkdir, download
from homely.install import installpkg
from homely.system import execute, haveexecutable
from homely.ui import head, note

home_dir = Path.home()
emacs_init_dir = home_dir / ".emacs.d"
dotfiles_old_dir = home_dir / "dotfiles.old"

mkdir("~/.emacs.d")

if not dotfiles_old_dir.exists():
    dotfiles_old_dir.mkdir()

installpkg("curl")

HOMEBREW_INSTALL_SCRIPT = (
    "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
)

with head("homebrew"):
    if not haveexecutable("brew"):
        install_system = platform.system()
        if install_system == "Linux":
            note("need to install Linux homebrew")
            with tempfile.NamedTemporaryFile() as install_sh_tmp:
                note(f"Downloading brew install script to: {install_sh_tmp}")
                download(HOMEBREW_INSTALL_SCRIPT, install_sh_tmp)
                note("Executing brew install script")
                execute(["/bin/bash", "-c", install_sh_tmp])
                # execute(["curl", "-fsSL", "-o", install_sh_tmp, HOMEBREW_INSTALL_SCRIPT])
        elif install_sytem == "Darwin":
            note("need to install Mac homebrew")
            with tempfile.NamedTemporaryFile() as install_sh_tmp:
                note(f"Downloading brew install script to: {install_sh_tmp}")
                download(HOMEBREW_INSTALL_SCRIPT, install_sh_tmp)
                note("Executing brew install script")
                execute(["/bin/bash", "-c", install_sh_tmp])
        else:
            note("Unknown brew platform")
    else:
        note("homebrew already installed")

with head("pyenv"):
    if haveexecutable("brew"):
        execute(["brew", "install", "pyenv"])
        execute(["brew", "install", "pyenv-virtualenv"])


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
            dst_file_path = (
                dotfiles_old_dir / f"{orig_file_path.name}_{int(time.time())}"
            )
            note(f"Original file: {orig_file_path} -> {dst_file_path}")
            shutil.move(orig_file_path, dst_file_path)

with head("Installing dotfiles."):
    for dot_file, orig_file in INSTALL_DOTFILES:
        symlink(dot_file, orig_file)
