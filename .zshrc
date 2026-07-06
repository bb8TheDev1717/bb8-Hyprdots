export PATH="$HOME/.local/bin:$PATH"

fastfetch

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="masters-shell"
plugins=(git)
source $ZSH/oh-my-zsh.sh

alias l="eza --icons --group-directories-first --no-permissions --no-filesize --no-user --no-time -l"
alias la="eza --icons --group-directories-first --no-permissions --no-filesize --no-user --no-time -la"
alias ll="eza --icons --group-directories-first -l --git"
alias lt="eza --icons --tree --level=2"

# alias
alias clauded='claude --dangerously-skip-permissions'
alias unpack='unar'
alias aurscan='~/.config/hypr/scripts/AUR-scanner.sh'

[[ -f ~/.local/share/zsh/fzf-tab/fzf-tab.plugin.zsh ]] && source ~/.local/share/zsh/fzf-tab/fzf-tab.plugin.zsh
source <(fzf --zsh)
eval "$(zoxide init zsh --cmd cd)"

# Plugins
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Wortweise Navigation & Löschen
WORDCHARS=${WORDCHARS//[-.\/]/}        # -, ., / als Wortgrenzen behandeln (nicht Teil des Wortes)
bindkey '^[[1;5C' forward-word        # Strg+Rechts
bindkey '^[[1;5D' backward-word       # Strg+Links
bindkey '^[[1;3C' forward-word        # Alt+Rechts (kitty)
bindkey '^[[1;3D' backward-word       # Alt+Links (kitty)
bindkey '^H'      backward-kill-word  # Strg+Backspace
bindkey '^[[3~'   delete-char         # Entf
bindkey '^[[3;5~' kill-word           # Strg+Entf

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

export PATH="$HOME/.npm-global/bin:$PATH"
