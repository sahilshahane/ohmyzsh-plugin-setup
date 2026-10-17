# install oh-my-zsh unless it's already there; RUNZSH=no stops the installer from exec'ing zsh and ending this script
if [ ! -d "${ZSH:-$HOME/.oh-my-zsh}" ]; then
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
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

# sudo, docker, docker-compose and extract ship with oh-my-zsh; fzf-tab requires fzf to be installed
PLUGINS="plugins=(git sudo docker docker-compose extract zsh-completions fzf-tab zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting)"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

cp "$ZSHRC" "$ZSHRC.bak"
if grep -q '^plugins=(' "$ZSHRC"; then
  # replace the existing plugins=(...) block, even if it spans multiple lines
  PLUGINS="$PLUGINS" perl -0pi -e 's/^plugins=\([^)]*\)/$ENV{PLUGINS}/m' "$ZSHRC"
else
  # plugins must be set before oh-my-zsh is sourced
  PLUGINS="$PLUGINS" perl -0pi -e 's/^(source \$ZSH\/oh-my-zsh\.sh)/$ENV{PLUGINS}\n$1/m' "$ZSHRC"
fi
