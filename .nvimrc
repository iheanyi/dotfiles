let $NODE_ENV="test" " When running tests in the Node app, use NODE_ENV=test, haha
let test#strategy = "neovim"

set nocp
set backspace=indent,eol,start
set nocompatible              " be iMproved, required
let mapleader=","
set clipboard=unnamed
" Display tabs and trailing spaces visually
set list listchars=tab:\ \ ,trail:·

"set nowrap       "Don't wrap lines
"set linebreak    "Wrap lines at convenient points
filetype off                  " required
" set tab as 4 spaces
set shiftwidth=2
set expandtab
set softtabstop=2
set textwidth=80
set number
set smarttab
"let $NVIM_TUI_ENABLE_TRUE_COLOR=0
"set t_Co=256
"set t_AB=^[[48;5;%dm
"set t_AF=^[[38;5;%dm
colorscheme Tomorrow-Night-Eighties
" ================ Folds ============================

set foldmethod=indent   "fold based on indent
set foldnestmax=3       "deepest fold is 3 levels
set nofoldenable        "dont fold by default

" ================ Search ===========================

set incsearch       " Find the next match as we type the search
set hlsearch        " Highlight searches by default
set ignorecase      " Ignore case when searching...
set smartcase       " ...unless we type a capital

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'scrooloose/syntastic'
Plugin 'scrooloose/nerdtree.git'
Plugin 'Valloric/YouCompleteMe'
Plugin 'kien/ctrlp.vim'
Plugin 'tpope/vim-surround'
Plugin 'kchmck/vim-coffee-script'
Plugin 'mattn/emmet-vim'
Plugin 'Raimondi/delimitMate'
Plugin 'janko-m/vim-test'
Plugin 'airblade/vim-gitgutter'
Plugin 'mustache/vim-mustache-handlebars'
Plugin 'tpope/vim-fugitive'
Plugin 'elixir-lang/vim-elixir'
" All of your Plugins must be added before the following line
call vundle#end()            " required
syntax on
filetype plugin indent on    " required
" set term=xterm
syntax on
