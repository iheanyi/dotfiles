"set encoding=utf-8
let $NODE_ENV="test"
let test#strategy = "neovim"

set nocp
set backspace=indent,eol,start
set nocompatible              " be iMproved, required
let mapleader=","
set clipboard=unnamed
" Display tabs and trailing spaces visually
set list listchars=tab:\ \ ,trail:·

syntax on
"set nowrap       "Don't wrap lines
"set linebreak    "Wrap lines at convenient points
" set tab as 4 spaces
" set background=dark
set textwidth=80
set colorcolumn=80
set number
set smarttab
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
filetype off                  " required
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
Plugin 'mileszs/ack.vim'
Plugin 'heavenshell/vim-jsdoc'
Plugin 'flazz/vim-colorschemes'
Plugin 'bling/vim-airline'
Plugin 'chriskempson/base16-vim'
Plugin 'pangloss/vim-javascript'
Plugin 'gcorne/vim-sass-lint'
Plugin 'mxw/vim-jsx'
Plugin 'fatih/vim-go'
Plugin 'captbaritone/better-indent-support-for-php-with-html'
Plugin 'christoomey/vim-tmux-navigator'
Plugin 'posva/vim-vue'
" All of your Plugins must be added before the following line
call vundle#end()            " required

" Ignoring files
set wildignore+=*/tmp/*,*.so,*.swp,*.zip     " MacOSX/Linux

" Ctrl-P Settings
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|\.git\|tmp\|_build\|deps\|vendor'
let g:ctrlp_show_hidden = 1

" Syntastic Settings
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_ruby_checkers = ['rubocop']
let g:syntastic_scss_checkers=["sass_lint"]
let g:syntastic_javascript_eslint_exe='$(npm bin)/eslint'

" Airline Settings
let g:airline#extensions#syntastic#enabled = 1

" Miscellaneous
syntax on

filetype plugin indent on    " required
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab

syntax on

set regexpengine=1
syntax enable
set t_Co=256
let base16colorspace=256  " Access colors present in 256 colorspace
set background=dark
colorscheme base16-ocean
let javascript_enable_domhtmlcss=1
let g:jsx_ext_required = 0

" Remapping
nmap <F1> :NERDTreeToggle<CR>

" Remap common key patterns to Mac OSX
inoremap <leader>s <Esc>:w<CR>i
nnoremap <leader>s :w<CR>

let g:syntastic_filetype_map = { 
      \ "html.handlebars": "handlebars",
      \ "handlebars.html": "handlebars",
      \ "vue": "javascript"
      \ }

if filereadable(expand("~/.vimrc_background"))
  let base16colorspace=256
  source ~/.vimrc_background
endif

let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_fields = 1
let g:go_highlight_types = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_fmt_command = "goimports"

let g:syntastic_go_checkers = ['golint', 'govet', 'errcheck']
let g:syntastic_mode_map = { 'mode': 'active', 'passive_filetypes': ['go'] }
let g:go_list_type = "quickfix"

let g:deoplete#enable_at_startup = 1
"" Disable Arrow Keys so you can become a pro Vim user.
map  <up>    <nop>
map  <down>  <nop>
map  <left>  <nop>
map  <right> <nop>
imap <up>    <nop>
imap <down>  <nop>
imap <left>  <nop>
imap <right> <nop>
