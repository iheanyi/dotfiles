# Install Homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"


# Install various libraries
brew install wget
brew install curl
brew install git # version control software

# Install Support for Various Languages
brew install elixir


# Install Node Version Manager (NVM)
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.26.1/install.sh | bash
# Install latest
nvm install stable
nvm alias default stable

# Install Neovim
brew install neovim

# Install and Move Vim Colors Stuff
mkdir ~/.vim/colors
curl https://raw.githubusercontent.com/chriskempson/tomorrow-theme/master/vim/colors/Tomorrow-Night-Eighties.vim
mv Tomorrow-Night-Eighties.vim ~/.vim/colors 


# Install Vundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

cp .nvimrc ~
cp .tmux.conf ~

# Install Pure
npm install --global pure-prompt
