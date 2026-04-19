# Homebrew (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)"

# User-local binaries (claude, etc.)
export PATH="$HOME/.local/bin:$PATH"

# Load secrets
if [[ -f ~/.secrets ]]; then                                                                                          
  source ~/.secrets                                                                                                   
else                                                                                                                  
  print -P "%F{red}⚠️   ~/.secrets missing%f" >&2
fi                                                                                                                 