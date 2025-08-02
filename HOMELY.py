import os
import platform
import shutil
import stat
import tarfile
import tempfile
import time

from io import BytesIO
from pathlib import Path

import requests

from homely.general import section
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

IS_MACOS = install_system == "Darwin"
IS_LINUX = install_system == "Linux"

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

HOMEBREW_INSTALL_SCRIPT = (
    "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
)

BASH_PREEXEC_URL = (
    "https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh"
)


@section
def homebrew():
    with head("homebrew"):
        if not haveexecutable("brew"):
            if IS_MACOS:
                note("need to install Mac homebrew")
                with tempfile.NamedTemporaryFile() as install_sh_tmp:
                    note(f"Downloading brew install script to: {install_sh_tmp}")
                    download(HOMEBREW_INSTALL_SCRIPT, install_sh_tmp)
                    note("Executing brew install script")
                    execute(["/bin/bash", "-c", install_sh_tmp])
            else:
                note("Not on a brew platform")
        else:
            note("homebrew already installed")

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


@section
def corepkgs():

    installpkg("emacs", apt="emacs-nox")
    installpkg("black")
    installpkg("htop")
    # installpkg("svn", apt="subversion")
    installpkg("ispell")
    installpkg("aspell")
    installpkg("tree")
    installpkg("fd", apt="fd-find")
    installpkg("ripgrep")
    installpkg("bat")
    installpkg("rustup")
    installpkg("direnv")

    if IS_LINUX:
        installpkg("net-tools")

    if IS_MACOS:
        installpkg("bash-preexec")
        installpkg("fzf")  # ubuntu has an ancient version
        installpkg("coreutils")


# On a fresh macos install, need to locate the cargo bin path
# Could make an assumption about /opt/homebrew/opt/rustup/bin
# But let's just ask rustup


def rustup_cargo_path():
    exitcode, output, _ = execute(["rustup", "which", "cargo"], stdout=True)
    if not exitcode:
        output = output.decode("ascii")
        outlines = [l.strip() for l in output.split("\n") if l.strip()]
        cargo_path = outlines[-1]
        note(f"rustup which cargo output: {output}")
        note(f"cargo path: {cargo_path}")
        return cargo_path
    else:
        raise Exception("Couldn't locate cargo using rustup")


@section
def cargo():
    with head("cargo"):
        CARGO_PATH = rustup_cargo_path()
        execute(["rustup", "toolchain", "install", "beta"])
        execute(["rustup", "update"])
        execute(["rustup", "default", "beta"])

        haveexecutable("zoxide") or execute(
            [CARGO_PATH, "install", "zoxide", "--locked"]
        )

        haveexecutable("starship") or execute(
            [CARGO_PATH, "install", "starship", "--locked"]
        )

        haveexecutable("atuin") or execute([CARGO_PATH, "install", "atuin", "--locked"])


@section
def pipx():
    with head("pipx"):
        installpkg("pipx")
        execute(["pipx", "install", "uv"])
        haveexecutable("httpie") or execute(["uv", "tool", "install", "httpie"])
        haveexecutable("xonsh") or execute(["uv", "tool", "install", "xonsh"])
        haveexecutable("cookiecutter") or execute(
            ["uv", "tool", "install", "cookiecutter"]
        )
        haveexecutable("black") or execute(["uv", "tool", "install", "black"])
        haveexecutable("pgcli") or execute(["uv", "tool", "install", "pgcli"])
        haveexecutable("ruff") or execute(["uv", "tool", "install", "ruff"])


@section
def infofetchers():
    with head("infofetchers"):
        if IS_MACOS:
            installpkg("fastfetch")
        installpkg("hyfetch")


@section
def fonts():
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


def install_latest_fzf(dest_dir="~/.local/bin"):
    # Expand and resolve the destination directory
    dest_path = Path(dest_dir).expanduser().resolve()
    dest_path.mkdir(parents=True, exist_ok=True)

    # Get latest release metadata from GitHub API
    url = "https://api.github.com/repos/junegunn/fzf/releases/latest"
    resp = requests.get(url)
    resp.raise_for_status()
    release = resp.json()

    # Find the right asset
    asset_url = next(
        asset["browser_download_url"]
        for asset in release["assets"]
        if "linux_amd64" in asset["name"] and asset["name"].endswith(".tar.gz")
    )

    note(f"Downloading: {asset_url}")
    tar_resp = requests.get(asset_url)
    tar_resp.raise_for_status()

    # Ensure destination directory exists
    os.makedirs(dest_dir, exist_ok=True)

    # Extract just the fzf binary
    with tarfile.open(fileobj=BytesIO(tar_resp.content), mode="r:gz") as tar:
        fzf_member = tar.getmember("fzf")
        fzf_member.name = os.path.basename(fzf_member.name)  # prevent path traversal
        tar.extract(fzf_member, path=dest_path)

    fzf_bin = dest_path / "fzf"
    fzf_bin.chmod(fzf_bin.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    print(f"fzf installed to {fzf_bin}")


@section
def fzf():
    with head("fzf"):
        if IS_LINUX and (not haveexecutable("fzf")):
            install_latest_fzf()


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


@section
def dotfiles():
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
