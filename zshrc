# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Homebrew over ssh support
export PATH="/opt/homebrew/bin:$PATH"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="af-magic"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=()

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Helper: determine default base branch for gwa
_gwa_default_base() {
    # 1. Check git config
    local config_base
    config_base=$(git config worktree.defaultBase 2>/dev/null)
    if [[ -n "$config_base" ]]; then
        echo "$config_base"
        return
    fi

    # 2. Auto-detect from remote HEAD
    local remote_base
    remote_base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if [[ -n "$remote_base" ]]; then
        echo "$remote_base"
        return
    fi

    # 3. Fall back to main
    echo "main"
}

# Git Worktree Add
# Adds a worktree and makes sure all submodules are up to date
gwa() {
    local dir="$1"
    local base="${2:-$(_gwa_default_base)}"

    if git rev-parse --verify --quiet "refs/heads/$dir" >/dev/null; then
        git worktree add "$dir" "$dir" && \
        cd "$dir" && \
        git submodule update --init --recursive && \
        echo "✓ Worktree '$dir' (existing branch) ready" && \
        open MultiMic.xcodeproj
    else
        git worktree add "$dir" -b "$dir" "$base" && \
        cd "$dir" && \
        git submodule update --init --recursive && \
        echo "✓ Worktree '$dir' (branch from $base) ready" && \
        open MultiMic.xcodeproj
    fi
}

# Git Worktree Checkout
# Adds a worktree for an existing branch (local or remote)
gwc() {
    local branch="$1"
    # Default dir: use part after last slash (e.g., "andrii/pomodoro" -> "pomodoro")
    local dir="${2:-${branch##*/}}"

    if [[ -z "$branch" ]]; then
        echo "Usage: gwc <existing-branch> [directory]"
        return 1
    fi

    # Create worktree for existing branch
    git worktree add "$dir" "$branch" && \
    cd "$dir" && \
    git submodule update --init --recursive && \
    echo "✓ Worktree '$dir' (branch '$branch') ready"
}

# Git Worktree Remove
gwrm() {
    local force=""
    local branch_flag="-d"
    if [[ "$1" == "-f" ]]; then
        force="--force"
        branch_flag="-D"
        shift
    fi

    local dir="$1"

    # If no argument, use current worktree
    if [[ -z "$dir" ]]; then
        dir=$(git rev-parse --show-toplevel 2>/dev/null)
        if [[ -z "$dir" ]]; then
            echo "Not in a git repository"
            return 1
        fi

        local git_dir=$(git rev-parse --git-dir 2>/dev/null)
        if [[ "$git_dir" == ".git" ]]; then
            echo "You're in the main repository, not a worktree"
            return 1
        fi

        cd "$dir/.."
    fi

    # Get branch name before removing worktree
    local branch=$(cd "$dir" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)

    # Try the clean way first
    (cd "$dir" && git submodule deinit --all --force 2>/dev/null)

    if git worktree remove $force "$dir" 2>/dev/null; then
        # Also remove folder if git left it behind
        [[ -d "$dir" ]] && rm -rf "$dir"
        echo "✓ Removed worktree '$dir'"
    else
        # Nuclear option: just delete and prune
        rm -rf "$dir"
        git worktree prune
        echo "✓ Removed worktree '$dir' (forced)"
    fi

    # Delete the branch if we found one
    if [[ -n "$branch" && "$branch" != "HEAD" ]]; then
        if git branch $branch_flag "$branch" 2>/dev/null; then
            echo "✓ Deleted branch '$branch'"
        else
            echo "⚠ Could not delete branch '$branch' (may have unmerged changes, use -f)"
        fi
    fi
}

# Remote access to The Forge
alias forge='ssh arturs@the-forge.taild86a97.ts.net -t "tmux new-session -A -s dev"'

alias ls='ls -F'
alias ll='ls -l'
alias l='ls'
alias lal='ls -al'
alias c='clear'
alias u='cd ..' #Up

#Git aliases
alias g='git'
alias gs='git status'
alias gb='git branch'
alias gc='git commit'
alias gch='git checkout'
alias gl='git log'
alias ga='git add'
alias gss='git stash save'
alias gsl='git stash list'
alias gsp='git stash pop'
alias gps='git push'
alias gpl='git pull'
alias grs='git restore --staged'

alias gwl='git worktree list'
alias gwp='git worktree prune'

#Back
alias b='cd -'

#Work
alias reset-xcode='rm -rf ~/Library/Developer/Xcode/DerivedData'
alias list-sims="xcrun simctl list devices available"

#Final Cut Pro
alias reset-fcpx='rm ~/Library/Application\ Support/.ffulerdata'

# Logic Pro
alias reset-lpx='rm ~/Library/Application\ Support/.lpxuserdata' 