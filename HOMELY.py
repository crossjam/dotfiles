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
mkdir("~/.emacs.d/snippets")
mkdir("~/.pip")
mkdir("~/.config/direnv")
mkdir("~/.config/atuin")
mkdir(str(iterm2_dir))

if not dotfiles_old_dir.exists():
    dotfiles_old_dir.mkdir()

install_system = platform.system()

PYDEV_PACKAGES = """
make build-essential libssl-dev zlib1g-dev
libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm
libncursesw5-dev xz-utils libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev tk-dev
"""

PG_PACKAGES = """
libpq-dev python3-dev python3-pip python3-psycopg2
"""

RUST_PACKAGES = """
cmake rustup
"""

IS_MACOS = platform.system() == "Darwin"
IS_LINUX = platform.system() == "Linux"
BASH_PREEXEC_URL = (
    "https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh"
)

if IS_LINUX:
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

    for pkg in PG_PACKAGES.split():
        installpkg(pkg.strip(), brew=False)

    for pkg in RUST_PACKAGES.split():
        installpkg(pkg.strip(), brew=False)

    download(BASH_PREEXEC_URL, "~/.bash-preexec.sh")

installpkg("emacs", apt="emacs-nox")
installpkg("black")
installpkg("htop")
installpkg("svn", apt="subversion")
installpkg("ispell")
installpkg("aspell")
installpkg("tree")
installpkg("fd", apt="fd-find")
installpkg("ripgrep")
installpkg("bat")
if IS_MACOS:
    installpkg("bash-preexec")
    installpkg("rustup")
    installpkg("fzf")  # ubuntu has an ancient version

installpkg("direnv")

# installpkg("atuin")

if install_system == "Darwin":
    installpkg("coreutils")

if install_system == "Linux":
    installpkg("net-tools")

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


execute(["rustup", "toolchain", "install", "beta"])
execute(["rustup", "update"])
execute(["rustup", "default", "beta"])

haveexecutable("cargo") and (
    haveexecutable("zoxide") or execute(["cargo", "install", "zoxide", "--locked"])
)

haveexecutable("cargo") and (
    haveexecutable("starship") or execute(["cargo", "install", "starship", "--locked"])
)

haveexecutable("cargo") and (
    haveexecutable("atuin")
    or execute(["cargo", "install", "atuin", "--locked", "--version", "stable"])
)

with head("homebrew"):
    if not (haveexecutable("brew") or brew_executable()):
        if IS_MACOS:
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

with head("pipx"):
    installpkg("pipx")
    execute(["pipx", "install", "uv"])
    haveexecutable("httpie") or execute(["uv", "tool", "install", "httpie"])
    haveexecutable("xonsh") or execute(["uv", "tool", "install", "xonsh"])
    haveexecutable("cookiecutter") or execute(["uv", "tool", "install", "cookiecutter"])
    haveexecutable("black") or execute(["uv", "tool", "install", "black"])
    haveexecutable("pgcli") or execute(["uv", "tool", "install", "pgcli"])
    haveexecutable("ruff") or execute(["uv", "tool", "install", "ruff"])

with head("infofetchers"):
    if IS_MACOS:
        installpkg("fastfetch")
    installpkg("hyfetch")

with head("nerdfonts"):
    if IS_MACOS and haveexecutable("brew"):
        execute(["brew", "install", "font-3270-nerd-font"])
        execute(["brew", "install", "font-droid-sans-mono-for-powerline"])
        execute(["brew", "install", "font-fira-code"])
        execute(["brew", "install", "font-fira-sans"])
        execute(["brew", "install", "font-fira-mono"])
        execute(["brew", "install", "font-fira-mono-for-powerline"])
    elif IS_LINUX:
        installpkg("fonts-powerline")
        installpkg("fonts-firacode")


INSTALL_DOTFILES = [
    # We use plain names for dot files so they
    # show up in directory listings
    ("screenrc", ".screenrc"),
    ("bashrc", ".bashrc"),
    ("bash_profile", ".bash_profile"),
    ("bash_logout", ".bash_logout"),
    ("bash_aliases", ".bash_aliases"),
    ("gitconfig", ".gitconfig"),
    ("gitignore", ".gitignore"),
    ("emacs_init.el", "~/.emacs.d/init.el"),
    ("xonshrc", ".xonshrc"),
    ("xonsh_iterm2.json", "~/.iterm2/xonsh.json"),
    ("pelicandev", "~/.local/bin/pelicandev"),
    ("dircolors_emacs", "~/.dircolors.emacs"),
    ("pip.conf", "~/.pip/pip.conf"),
    ("atuin_config.toml", "~/.config/atuin/config.toml"),
    ("direnvrc", "~/.config/direnv/direnvrc"),
    ("direnv_toml", "~/.config/direnv/direnv.toml"),
    ("starship.toml", "~/.config/starship.toml"),
]


with head("Saving potential preexisting targets."):
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
