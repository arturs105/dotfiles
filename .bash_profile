export PATH=$PATH:/Users/Arturs/Library/Android/sdk/platform-tools/

alias ls='ls -F'
alias ll='ls -l'
alias lal='ls -al'
alias c='clear'

#Back
alias b='cd -'

alias zipalign='~/Library/Android/sdk/build-tools/24.0.1/zipalign'

alias ndk-build='/Users/Arturs/Library/Developer/Xamarin/android-ndk/android-ndk-r10e/ndk-build'

#Cahnges the appearance of the prompt to “username@hostname:cwd $” and colorizes it
export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
#Enables colors
export CLICOLOR=1
#Adds colors to the ls command
export LSCOLORS=ExFxBxDxCxegedabagacad
