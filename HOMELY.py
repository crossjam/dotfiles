import os
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
iterm2_dir = home_dir / ".iterm2"

mkdir("~/.emacs.d")
mkdir(str(iterm2_dir))

if not dotfiles_old_dir.exists():
    dotfiles_old_dir.mkdir()

install_system = platform.system()

PYDEV_PACKAGES = """
make build-essential libssl-dev zlib1g-dev
libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm
libncursesw5-dev xz-utils libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev tk-dev
"""

if install_system == "Linux":
    note("printing sudo environment")
    execute(["sudo", "DEBIAN_FRONTEND=noninteractive", "printenv"])
    note("custom install tzdata")
    execute(
        [
            "sudo",
            "DEBIAN_FRONTEND=noninteractive",
            "apt-get",
            "install",
            "-y",
            "--quiet",
            "tzdata",
        ]
    )
    for pkg in PYDEV_PACKAGES.split():
        installpkg(pkg.strip(), brew=False)

installpkg("emacs", apt="emacs-nox")
installpkg("black")
installpkg("htop")
installpkg("svn", apt="subversion")
installpkg("pgcli")

HOMEBREW_INSTALL_SCRIPT = (
    "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
)


def brew_executable():
    brew_dirs = [
        Path("~/.linuxbrew").expanduser(),
        Path("/home/linuxbrew/.linuxbrew"),
    ]

    for brew_dir in brew_dirs:
        brew_binary = brew_dir / "bin" / "brew"

        if brew_binary.exists() and brew_binary.is_file():
            return str(brew_binary)
    return ""


with head("homebrew"):
    if not (haveexecutable("brew") or brew_executable()):
        if install_system == "Linux":
            note("need to install personal Linux homebrew, executing install script")
            execute(
                [
                    "/bin/bash",
                    Path("~/dotfiles/install_personal_linuxbrew.sh").expanduser(),
                ]
            )
        elif install_system == "Darwin":
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
    note("Installing pyenv")
    pyenv_root = Path(os.environ["HOME"]) / ".pyenv"
    if not pyenv_root.exists():
        note("Installing pyenv")
        execute(["git", "clone", "https://github.com/pyenv/pyenv.git", str(pyenv_root)])
    else:
        note(f"pyenv dir: {pyenv_root} already exists. Skipping clone.")

    pyenv_virtualenv_root = pyenv_root / "plugins" / "pyenv-virtualenv"
    if not (pyenv_virtualenv_root.exists()):
        note("Installing pyenv-virtualenv")
        execute(
            [
                "git",
                "clone",
                "https://github.com/pyenv/pyenv-virtualenv.git",
                str(pyenv_virtualenv_root),
            ]
        )
    else:
        note(
            f"pyenv plugin dir: {pyenv_virtualenv_root} already exists. Skipping clone."
        )

with head("pipx"):
    installpkg("pipx")
    execute(["pipx", "install", "httpie"])
    execute(["pipx", "install", "xonsh"])
    execute(["pipx", "install", "cookiecutter"])
    execute(
        [
            str(home_dir / ".local" / "bin" / "xonsh"),
            "-c" "xpip install -U 'xonsh[full]'",
        ]
    )
    execute(
        [
            str(home_dir / ".local" / "bin" / "xonsh"),
            "-c",
            "xpip install vox",
        ]
    )
    execute(
        [
            str(home_dir / ".local" / "bin" / "xonsh"),
            "-c",
            "xpip install packaging xontrib-powerline2 xontrib-homebrew",
        ]
    )

with head("neofetch"):
    installpkg("neofetch")

with head("nerdfonts"):
    if haveexecutable("brew") and install_system == "Darwin":
        execute(["brew", "tap", "homebrew/cask-fonts"])
        execute(["brew", "install", "font-3270-nerd-font"])
        execute(["brew", "install", "font-droid-sans-mono-for-powerline"])
        execute(["brew", "install", "font-fira-code"])
        execute(["brew", "install", "font-fira-sans"])
        execute(["brew", "install", "font-fira-mono"])
        execute(["brew", "install", "font-fira-mono-for-powerline"])


INSTALL_DOTFILES = [
    ("screenrc", ".screenrc"),
    ("bashrc", ".bashrc"),
    ("bash_profile", ".bash_profile"),
    ("gitconfig", ".gitconfig"),
    ("gitignore", ".gitignore"),
    ("emacs_init.el", "~/.emacs.d/init.el"),
    ("xonshrc", ".xonshrc"),
    ("xonsh_iterm2.json", "~/.iterm2/xonsh.json"),
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
