"set encoding=utf-8
augroup filetype
   au! BufRead,BufNewFile *.proto setfiletype proto
augroup end

let $NODE_ENV="test"
let test#strategy = "neovim"

set termguicolors
set nocp
set backspace=indent,eol,start
set nocompatible              " be iMproved, required
let mapleader=","
set clipboard=unnamed
" Display tabs and trailing spaces visually
set list listchars=tab:\ \ ,trail:·

let python_highlight_all=1
syntax on
"set nowrap       "Don't wrap lines
"set linebreak    "Wrap lines at convenient points
" set tab as 4 spaces
set background=dark
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

" Substitution settings (preview change)
if has('nvim')
  set inccommand=split
endif

call plug#begin('~/.config/nvim/plugged')
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
Plug 'majutsushi/tagbar'
Plug 'tpope/vim-rails'
Plug 'vim-ruby/vim-ruby'
Plug 'ambv/black'
Plug 'ruby-formatter/rufo-vim'
Plug 'mdempsky/gocode', { 'rtp': 'nvim/', 'do': '~/.config/nvim/plugged/gocode/nvim/symlink.sh' }
Plug 'deoplete-plugins/deoplete-go', { 'do': 'make'}
Plug 'rust-lang/rust.vim'
Plug 'scrooloose/syntastic'
Plug 'scrooloose/nerdtree'
Plug 'Valloric/YouCompleteMe', { 'do': './install.py' }
Plug 'ctrlpvim/ctrlp.vim'
Plug 'tpope/vim-surround'
Plug 'kchmck/vim-coffee-script'
Plug 'mattn/emmet-vim'
Plug 'Raimondi/delimitMate'
Plug 'janko-m/vim-test'
Plug 'airblade/vim-gitgutter'
Plug 'mustache/vim-mustache-handlebars'
Plug 'tpope/vim-fugitive'
Plug 'elixir-lang/vim-elixir'
Plug 'mileszs/ack.vim'
Plug 'flowtype/vim-flow', { 'do': 'npm install -g flow-bin' }
Plug 'heavenshell/vim-jsdoc'
Plug 'flazz/vim-colorschemes'
Plug 'bling/vim-airline'
Plug 'chriskempson/base16-vim'
Plug 'pangloss/vim-javascript'
Plug 'gcorne/vim-sass-lint'
Plug 'mxw/vim-jsx'
Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' }
Plug 'AndrewRadev/splitjoin.vim'
Plug 'captbaritone/better-indent-support-for-php-with-html'
Plug 'christoomey/vim-tmux-navigator'
Plug 'posva/vim-vue'
Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'
Plug 'jparise/vim-graphql'
Plug 'Quramy/tsuquyomi'
Plug 'leafgarland/typescript-vim'
Plug 'reedes/vim-pencil'
Plug 'machakann/vim-highlightedyank'
Plug 'Shougo/vimproc.vim', {'do' : 'make'}
Plug 'tpope/vim-markdown'
Plug 'junegunn/goyo.vim'
Plug 'mattly/vim-markdown-enhancements'
Plug 'prettier/vim-prettier', { 'do': 'yarn install' }
Plug 'ap/vim-css-color'
Plug 'nvie/vim-flake8'
" All of your Plugins must be added before the following line
call plug#end()

" Ignoring files
set wildignore+=*/tmp/*,*.so,*.swp,*.zip     " MacOSX/Linux

" Ctrl-P Settings
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|\.git\|tmp\|_build\|deps\|vendor'
let g:ctrlp_show_hidden = 1

" Syntastic Settings
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_python_python_exec = '/usr/local/bin/python3'
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_ruby_checkers = ['rubocop']
let g:syntastic_scss_checkers=["sass_lint"]
let g:syntastic_typescript_checkers = ['eslint', 'tslint', 'tsc']
let g:syntastic_javascript_eslint_exe='$(npm bin)/eslint'
" autofix with eslint
let g:syntastic_javascript_eslint_args = ['--fix']
function! SyntasticCheckHook(errors)
  checktime
endfunction

" Airline Settings
let g:airline#extensions#syntastic#enabled = 1

if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" Markdown Settings
let g:markdown_fenced_languages = ['html', 'python', 'bash=sh', 'go']
let g:markdown_minlines = 100

" Miscellaneous
syntax on
filetype on
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
nmap <leader>f :FZF<CR>

let g:syntastic_filetype_map = { 
      \ "html.handlebars": "handlebars",
      \ "handlebars.html": "handlebars",
      \ "vue": "javascript"
      \ }

if filereadable(expand("~/.vimrc_background"))
  let base16colorspace=256
  source ~/.vimrc_background
endif

" Vim-Go Configuration
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_fields = 1
let g:go_highlight_types = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_extra_types = 1
let g:go_fmt_command = "goimports"
let g:go_metalinter_autosave = 1
" let g:go_metalinter_command="golangci-lint"
let g:go_metalinter_enabled=["vet", "golint"]
let g:go_metalinter_autosave_enabled=["vet", "golint"]
let g:go_list_type = "quickfix"

"let g:syntastic_go_checkers = ['go', 'golint', 'govet', 'gometalinter']
"let g:syntastic_go_gometalinter_args = ['--disable-all', '--enable=errcheck']
"let g:syntastic_mode_map = { 'mode': 'active', 'passive_filetypes': ['go'] }

" Vim-Go Key Mappings
autocmd FileType go nmap <leader>b  <Plug>(go-build)
autocmd FileType go nmap <leader>r  <Plug>(go-run)
autocmd FileType go nmap <leader>t  <Plug>(go-test)
autocmd FileType go nmap <Leader>c <Plug>(go-coverage-toggle)
autocmd FileType go nmap <Leader>i <Plug>(go-info)
" autocmd Filetype go command! -bang A call go#alternate#Switch(<bang>0, 'edit')
" autocmd Filetype go command! -bang AV call go#alternate#Switch(<bang>0, 'vsplit')
" autocmd Filetype go command! -bang AS call go#alternate#Switch(<bang>0, 'split')
" autocmd Filetype go command! -bang AT call go#alternate#Switch(<bang>0, 'tabe')

"" Disable Arrow Keys so you can become a pro Vim user.
map  <up>    <nop>
map  <down>  <nop>
map  <left>  <nop>
map  <right> <nop>
imap <up>    <nop>
imap <down>  <nop>
imap <left>  <nop>
imap <right> <nop>

" Vim-Pencil initializer and configuration
let g:pencil#wrapModeDefault = 'soft'   " default is 'hard'
augroup pencil
  autocmd!
  autocmd FileType markdown,mkd call pencil#init()
  autocmd FileType text         call pencil#init({'wrap': 'hard'})
augroup END

" YouCompleteMe
let g:ycm_autoclose_preview_window_after_completion = 1
let g:ycm_autoclose_preview_window_after_insertion = 1
let g:ycm_key_list_accept_completion = ['<C-y>', '<CR>']
let g:loaded_youcompleteme = 1

let g:prettier#config#bracket_spacing = 'true'
let g:prettier#config#parser = 'babylon'
set rtp+=/usr/local/opt/fzf
" Run Flake8 on save
" autocmd BufWritePost *.py call Flake8()
let g:deoplete#enable_at_startup = 1
call deoplete#custom#option('omni_patterns', { 'go': '[^. *\t]\.\w*' })

" Override tab to autocomplete Go functions
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

autocmd BufWritePost *.py execute ':Black'
let g:rustfmt_autosave = 1

" Use relative path rather than absolute path for GoGuru
function! s:go_guru_scope_from_git_root()
  let gitroot = system("git rev-parse --show-toplevel | tr -d '\n'")
  let pattern = escape(go#util#gopath() . "/src/", '\ /')
  return substitute(gitroot, pattern, "", "") . "/... -vendor/"
endfunction

au FileType go silent exe "GoGuruScope " . s:go_guru_scope_from_git_root()
