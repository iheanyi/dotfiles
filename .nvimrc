set softtabstop=2
set textwidth=80
set number
set smarttab
colorscheme Tomorrow-Night-Eighties
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'scrooloose/syntastic'
Plugin 'scrooloose/nerdtree.git'
Plugin 'Valloric/YouCompleteMe'
Plugin 'kien/ctrlp.vim'
Plugin 'tpope/vim-surround'
Plugin 'AutoClose'
" All of your plugins must be added before the following line
call vundle#end()   " required
syntax on
filetype plugin indent on   " required


