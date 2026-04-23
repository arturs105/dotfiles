# Homebrew (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)"

# User-local binaries (claude, etc.)
export PATH="$HOME/.local/bin:$PATH"

# For the PolyMic release automation
export ASC_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_7PSYZDA9BJ.p8"
export ASC_ISSUER_ID="f537215f-eaac-486f-be9e-c72cfab65e47"
export ASC_KEY_ID="7PSYZDA9BJ"
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

# Load secrets
if [[ -f ~/.secrets ]]; then                                                                                          
  source ~/.secrets                                                                                                   
else                                                                                                                  
  print -P "%F{red}⚠️   ~/.secrets missing%f" >&2
fi                                                                                                                 
