export PATH="./bin:$HOME/.local/bin:$PATH"

export PATH="$PATH:./node_modules/.bin"
export PATH="$PATH:$HOME/go/bin"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.bin:$PATH"
export PATH="$PATH:$HOME/.emacs.d/bin"

export LC_ALL=en_US.UTF-8

export FZF_DEFAULT_COMMAND='ag -g ""'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS=""

export EDITOR=nvim

export BAT_THEME=base16

#export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
#export ANDROID_HOME=${HOME}/Library/Android/sdk
#export PATH=${PATH}:${ANDROID_HOME}/emulator
#export PATH=${PATH}:${ANDROID_HOME}/tools/bin
#export PATH=${PATH}:${ANDROID_HOME}/tools
#export PATH=${PATH}:${ANDROID_HOME}/platform-tools

export PATH=${PATH}:/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin
export GPG_TTY=$(tty)

CARGO_ENV=~/.cargo/env
if [[ -e $CARGO_ENV ]]; then
    source $CARGO_ENV
fi

DOCKER_HOST="unix://$HOME/.colima/docker.sock"
