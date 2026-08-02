import io
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
mkdir("~/.config/neofetch")
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
cmake
"""

HOMEBREW_INSTALL_SCRIPT = (
    "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
)

BASH_PREEXEC_URL = (
    "https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh"
)

RUSTUP_URL = "https://sh.rustup.rs"
RUSTUP_CMD = "rustup"

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
    ("neofetch_config_conf", "~/.config/neofetch/config.conf"),
    ("personal-fork.sh", "~/.local/bin/personal-fork"),
]

### Helper functions


def install_latest_fzf(dest_dir="~/.local/bin"):
    # Expand and resolve the destination directory
    dest_path = Path(dest_dir).expanduser().resolve()
    dest_path.mkdir(parents=True, exist_ok=True)

    machine = platform.machine()

    # Get latest release metadata from GitHub API
    url = "https://api.github.com/repos/junegunn/fzf/releases/latest"
    resp = requests.get(url)
    resp.raise_for_status()
    release = resp.json()

    if IS_MACOS:
        if machine == "arm64":
            target = "darwin_arm64"
        else:
            target = "darwin_amd64"
    elif IS_LINUX:
        if is_raspberry_pi():
            if machine in ("armv6l", "armv7l"):
                target = "linux_armv6"
            elif machine == "aarch64":
                target = "linux_arm64"
            else:
                raise RuntimeError(f"Unrecognized Raspberry Pi architecture: {machine}")
        else:
            if machine == "x86_64":
                target = "linux_amd64"
            elif machine == "aarch64":
                target = "linux_arm64"  # Could be a generic 64-bit ARM Linux server
            else:
                raise RuntimeError(f"Unsupported Linux architecture: {machine}")
    else:
        raise RuntimeError(f"Unsupported system: {system}")

    # Find matching asset
    for asset in release["assets"]:
        name = asset["name"]
        if target in name and name.endswith(".tar.gz"):
            asset_url = asset["browser_download_url"]
            note(f"Found matching asset_url: {asset_url}")
            break

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


def is_raspberry_pi():
    # Check ARM architecture
    arch = platform.machine()
    if arch not in ("armv6l", "armv7l", "aarch64"):
        return False

    # Check /proc/cpuinfo for Raspberry Pi hardware string
    try:
        with open("/proc/cpuinfo") as f:
            for line in f:
                if line.startswith("Hardware") and "BCM" in line:
                    return True
                if "Raspberry Pi" in line:
                    return True
    except FileNotFoundError:
        return False

    # Fallback: check presence of Pi-specific device tree
    model_path = Path("/proc/device-tree/model")
    if model_path.exists():
        model = model_path.read_text(errors="ignore")
        if "Raspberry Pi" in model:
            return True

    return False


def detect_arch():
    machine = platform.machine()
    if machine == "armv7l":
        return "armv7-unknown-linux-musl"
    elif machine == "aarch64":
        return "aarch64-unknown-linux-musl"
    else:
        raise RuntimeError(f"Unsupported architecture: {machine}")


def install_starship():
    target_dir = Path("~/.cargo/bin").expanduser()
    target_dir.mkdir(parents=True, exist_ok=True)

    arch = detect_arch()
    note(f"Detected architecture: {arch}")

    api_url = "https://api.github.com/repos/starship/starship/releases/latest"
    release = requests.get(api_url).json()

    asset_url = next(
        asset["browser_download_url"]
        for asset in release["assets"]
        if arch in asset["name"] and asset["name"].endswith(".tar.gz")
    )

    note(f"Downloading: {asset_url}")
    response = requests.get(asset_url)
    with tarfile.open(fileobj=io.BytesIO(response.content), mode="r:gz") as tar:
        for member in tar.getmembers():
            if member.name.endswith("starship"):
                member.name = "starship"
                tar.extract(member, path=target_dir)
                starship_path = target_dir / "starship"
                starship_path.chmod(0o755)
                note(f"Installed to: {starship_path}")
                return

    raise RuntimeError("Starship binary not found in archive")


def detect_atuin_arch():
    machine = platform.machine()
    if machine == "armv7l":
        return "armv7-unknown-linux-gnu"
    elif machine == "aarch64":
        return "aarch64-unknown-linux-gnu"
    else:
        raise RuntimeError(f"Unsupported architecture: {machine}")


def install_atuin():
    target_dir = Path("~/.cargo/bin").expanduser()
    target_dir.mkdir(parents=True, exist_ok=True)

    arch = detect_atuin_arch()
    note(f"Detected architecture: {arch}")

    api_url = "https://api.github.com/repos/atuinsh/atuin/releases/latest"
    release = requests.get(api_url).json()

    asset_url = next(
        asset["browser_download_url"]
        for asset in release["assets"]
        if arch in asset["name"] and asset["name"].endswith(".tar.gz")
    )

    note(f"Downloading: {asset_url}")
    response = requests.get(asset_url)
    with tarfile.open(fileobj=io.BytesIO(response.content), mode="r:gz") as tar:
        for member in tar.getmembers():
            if member.name.endswith("/atuin"):
                member.name = "atuin"  # flatten path
                tar.extract(member, path=target_dir)
                atuin_path = target_dir / "atuin"
                atuin_path.chmod(0o755)
                note(f"Installed to: {atuin_path}")
                return

    raise RuntimeError("Atuin binary not found in archive")


# On a fresh macos install, need to locate the cargo bin path
# Could make an assumption about /opt/homebrew/opt/rustup/bin
# But let's just ask rustup


def rustup_cargo_path():
    exitcode, output, _ = execute([RUSTUP_CMD, "which", "cargo"], stdout=True)
    if not exitcode:
        output = output.decode("ascii")
        outlines = [l.strip() for l in output.split("\n") if l.strip()]
        cargo_path = outlines[-1]
        note(f"rustup which cargo output: {output}")
        note(f"cargo path: {cargo_path}")
        return cargo_path
    else:
        raise Exception("Couldn't locate cargo using rustup")


### Homely sections


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


@section
def ubuntu():
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
def userpkgs():

    installpkg("screen")
    installpkg("emacs", apt="emacs-nox")
    installpkg("black")
    installpkg("htop")
    installpkg("ispell")
    installpkg("aspell")
    installpkg("tree")
    installpkg("fd", apt="fd-find")
    installpkg("ripgrep")
    installpkg("bat")
    installpkg("direnv")
    installpkg("duf")

    if IS_LINUX:
        installpkg("net-tools")
        if not is_raspberry_pi():
            installpkg("rustup")
        elif haveexecutable("rustup"):
            note("rustup alread installed")
        else:
            # Grab the rustup script and execute it with -y
            note(f"Installing rustup via: {RUSTUP_URL}")
            download(RUSTUP_URL, "~/dotfiles/rustup.sh")
            rustup_script = Path("~/dotfiles/rustup.sh").expanduser()
            execute(["sh", str(rustup_script), "-y"])
            RUSTUP_CMD = Path("~").expanduser() / ".cargo" / "bin" / "rustup"
            note(f"RUSTUP_CMD: {RUSTUP_CMD}")

        with head("fzf"):
            not haveexecutable("fzf") and install_latest_fzf()

    if IS_MACOS:
        installpkg("rustup")
        installpkg("bash-preexec")
        installpkg("fzf")  # ubuntu has an ancient version
        installpkg("coreutils")


@section
def cargo():
    with head("cargo"):
        execute([RUSTUP_CMD, "toolchain", "install", "beta"])
        execute([RUSTUP_CMD, "update"])
        execute([RUSTUP_CMD, "default", "beta"])

        CARGO_PATH = rustup_cargo_path()
        EXTRA_ARGS = []

        if is_raspberry_pi():
            haveexecutable("starship") or install_starship()
            haveexecutable("atuin") or install_atuin()

        else:
            haveexecutable("starship") or execute(
                [CARGO_PATH, "install", "starship", "--locked"] + EXTRA_ARGS
            )

            haveexecutable("atuin") or execute(
                [CARGO_PATH, "install", "atuin", "--locked"] + EXTRA_ARGS
            )

        haveexecutable("zoxide") or execute(
            [CARGO_PATH, "install", "zoxide", "--locked", "-j", "1"] + EXTRA_ARGS
        )


@section
def pipx():
    with head("pipx"):

        # probably don't need these if we've made it this far
        # to actually get homely running pipx, uv, and homely (crossjam specific)
        # should be bootstrapped externally

        # but just in case
        haveexecutable("pipx") or installpkg("pipx")
        haveexecutable("uv") or execute(["pipx", "install", "uv"])

        haveexecutable("httpie") or execute(["uv", "tool", "install", "httpie"])
        haveexecutable("xonsh") or execute(["uv", "tool", "install", "xonsh"])
        haveexecutable("cookiecutter") or execute(
            ["uv", "tool", "install", "cookiecutter"]
        )
        haveexecutable("black") or execute(["uv", "tool", "install", "black"])
        haveexecutable("pgcli") or execute(["uv", "tool", "install", "pgcli"])
        haveexecutable("ruff") or execute(["uv", "tool", "install", "ruff"])


@section
def consoleinfo():
    with head("consoleinfo"):
        if IS_MACOS:
            installpkg("fastfetch")
        elif is_raspberry_pi():
            haveexecutable("neowofetch") or execute(
                ["uv", "tool", "install", "--managed-python", "hyfetch"]
            )
        else:
            installpkg("hyfetch")


@section
def fonts():
    with head("nerdfonts"):
        if IS_MACOS and haveexecutable("brew"):
            installpkg("font-3270-nerd-font")
            installpkg("font-droid-sans-mono-for-powerline")
            installpkg("font-fira-code")
            installpkg("font-fira-sans")
            installpkg("font-fira-mono")
            installpkg("font-fira-mono-for-powerline")
        elif IS_LINUX:
            installpkg("fonts-powerline")
            installpkg("fonts-firacode")


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
