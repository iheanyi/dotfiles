#!/bin/sh
# Software for provisioning up a Macbook Pro and all that good stuff.
brew_install() {
    if test ! $(brew list | grep $package); then
      brew install "$@"
    else
        echo '$package already installed, gonna skip that.'
    fi
}

cask_install() {
    if test ! $(brew cask list | grep $application); then
      brew install "$@"
    else
        echo '$application already installed, gonna skip that.'
    fi
}

copy_configs() {
    cp .nvimrc ~
    cp .tmux.conf ~
}

# Install Homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"


packages=(
    wget
    curl
    git
    jq
    autojump
    python3
    the_silver_searcher
    fzf
    tmate
    highlight
    hugo
    vim
    emacs-plus
    tmux
    neovim
)

for package in "$packages[@]"
  do brew_install $package
done

languages=(
    elixir
    go
    ruby
)

for package in "$languages[@]"
  do brew_install $package
done

# Install brew caskroom
brew tap caskroom/cask
brew tap caskroom/fonts

# Install applications
applications=(
    1password
    alfred
    dash
    caffeine
    google-chrome
    firefox
    fantastical
    spectacle
    skype
    iterm2
    figma
    cyberduck
    insomnia
    flux
    timing
    licecap
    atom
    the-unarchiver
    slack
    sketch
    docker
    spotify
    sequel-pro
    font-source-code-pro
    plex-media-server
)

for application in "$applications[@]"
  do cask_install $application
done

# Install Node Version Manager (NVM)
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.26.1/install.sh | bash

# Install latest
nvm install stable
nvm alias default stable

# Install Neovim

# Install and Move Vim Colors Stuff
mkdir ~/.vim/colors
curl https://raw.githubusercontent.com/chriskempson/tomorrow-theme/master/vim/colors/Tomorrow-Night-Eighties.vim
mv Tomorrow-Night-Eighties.vim ~/.vim/colors 

# Install Vundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

# Install Pure
npm install --global pure-prompt

# Install Spacemacs
git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
