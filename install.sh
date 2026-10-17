git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions.git ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

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
