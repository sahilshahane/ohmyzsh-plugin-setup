# install a package with whichever package manager is present; args are the package
# names for apt, dnf, pacman, zypper, apk and brew, in that order ("" skips that manager);
# a single name is used for all of them
pkg_install() {
  [ $# -eq 1 ] && set -- "$1" "$1" "$1" "$1" "$1" "$1"
  if command -v apt-get >/dev/null 2>&1; then
    [ -n "$1" ] && sudo apt-get update && sudo apt-get install -y "$1"
  elif command -v dnf >/dev/null 2>&1; then
    [ -n "$2" ] && sudo dnf install -y "$2"
  elif command -v pacman >/dev/null 2>&1; then
    [ -n "$3" ] && sudo pacman -S --needed --noconfirm "$3"
  elif command -v zypper >/dev/null 2>&1; then
    [ -n "$4" ] && sudo zypper install -y "$4"
  elif command -v apk >/dev/null 2>&1; then
    [ -n "$5" ] && sudo apk add "$5"
  elif command -v brew >/dev/null 2>&1; then
    [ -n "$6" ] && brew install "$6"
  fi
}

# everything below sets up zsh, and the oh-my-zsh installer exits early without it
if ! command -v zsh >/dev/null 2>&1; then
  pkg_install zsh
fi

# chsh is needed at the end to make zsh the login shell;
# dnf and zypper can install by file path, which avoids guessing the package name per release
if ! command -v chsh >/dev/null 2>&1; then
  pkg_install passwd /usr/bin/chsh util-linux /usr/bin/chsh shadow ""
fi

# install oh-my-zsh unless it's already there; RUNZSH=no stops the installer from exec'ing zsh and ending this script,
# CHSH=no leaves the shell change to the prompt at the end
if [ ! -d "${ZSH:-$HOME/.oh-my-zsh}" ]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

CUSTOM="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}"

# clone a repo, or update it if a previous run already cloned it
clone_or_update() {
  if [ -d "$2/.git" ]; then
    echo "Updating $2"
    git -C "$2" pull --ff-only --quiet
  else
    git clone --depth=1 "$1" "$2"
  fi
}

clone_or_update https://github.com/zsh-users/zsh-autosuggestions "$CUSTOM/plugins/zsh-autosuggestions"
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "$CUSTOM/plugins/zsh-syntax-highlighting"
clone_or_update https://github.com/zsh-users/zsh-completions.git "$CUSTOM/plugins/zsh-completions"
clone_or_update https://github.com/zsh-users/zsh-history-substring-search "$CUSTOM/plugins/zsh-history-substring-search"
clone_or_update https://github.com/Aloxaf/fzf-tab "$CUSTOM/plugins/fzf-tab"
clone_or_update https://github.com/romkatv/powerlevel10k.git "$CUSTOM/themes/powerlevel10k"

# fzf-tab needs the fzf binary; install it with the distro's package manager
if ! command -v fzf >/dev/null 2>&1; then
  pkg_install fzf
fi

# no known package manager (or the install failed): build from upstream without sudo
if ! command -v fzf >/dev/null 2>&1; then
  clone_or_update https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --bin
  mkdir -p "$HOME/.local/bin"
  ln -sf "$HOME/.fzf/bin/fzf" "$HOME/.local/bin/fzf"
fi

# sudo, docker, docker-compose and extract ship with oh-my-zsh; fzf-tab requires fzf to be installed
PLUGINS="plugins=(git sudo docker docker-compose extract zsh-completions fzf-tab zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting)"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

# rewrite from the backup with POSIX awk (always available, unlike perl); redirecting into
# "$ZSHRC" keeps it a symlink if it was one
cp "$ZSHRC" "$ZSHRC.bak"
if grep -q '^plugins=(' "$ZSHRC"; then
  # replace the first plugins=(...) block, even if it spans multiple lines
  PLUGINS="$PLUGINS" awk '
    skip { if (/\)/) skip = 0; next }
    !done && /^plugins=\(/ { print ENVIRON["PLUGINS"]; done = 1; if (!/\)/) skip = 1; next }
    { print }
  ' "$ZSHRC.bak" > "$ZSHRC"
else
  # plugins must be set before oh-my-zsh is sourced
  PLUGINS="$PLUGINS" awk '
    !done && /^source \$ZSH\/oh-my-zsh\.sh/ { print ENVIRON["PLUGINS"]; done = 1 }
    { print }
  ' "$ZSHRC.bak" > "$ZSHRC"
fi

# offer to make zsh the login shell; read from /dev/tty so this works under curl | sh
ZSH_BIN="$(command -v zsh)"
LOGIN_SHELL="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)"
if [ "${LOGIN_SHELL:-$SHELL}" != "$ZSH_BIN" ] && command -v chsh >/dev/null 2>&1; then
  printf 'Change your login shell to %s? [y/N] ' "$ZSH_BIN"
  read -r answer </dev/tty
  case "$answer" in
    [yY]*)
      # chsh refuses shells that aren't listed in /etc/shells
      grep -qx "$ZSH_BIN" /etc/shells || echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
      chsh -s "$ZSH_BIN"
      ;;
  esac
fi

# a script can't source .zshrc into the calling shell, so replace this process with a zsh that loads it
if [ -t 1 ]; then
  exec "$ZSH_BIN" -l
fi
