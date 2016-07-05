export PATH=$PATH:/Users/Arturs/Library/Android/sdk/platform-tools/

alias ls='ls -F'
alias ll='ls -l'
alias lal='ls -al'

#Back
alias b='ls -'

#Cahnges the appearance of the prompt to “username@hostname:cwd $” and colorizes it
export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
#Enables colors
export CLICOLOR=1
#Adds colors to the ls command
export LSCOLORS=ExFxBxDxCxegedabagacad
