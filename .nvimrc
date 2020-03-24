set hidden
" Disable preview menu
set completeopt-=preview
set encoding=utf-8

augroup filetype
  au! BufRead,BufNewFile *.proto setfiletype proto
augroup end

let test#strategy = "neovim"

set nocp
set backspace=indent,eol,start
set backspace=2
set nocompatible              " be iMproved, required
let mapleader=","
set clipboard=unnamed
" Display tabs and trailing spaces visually
set list listchars=tab:\ \ ,trail:·

let python_highlight_all=1
let g:python3_host_prog="/usr/bin/python3"
let g:coc_node_path="/home/iheanyi/.nvm/versions/node/v13.8.0/bin/node"

syntax on
"set linebreak    "Wrap lines at convenient points
" set tab as 4 spaces
set nowrap       "Don't wrap lines
set background=dark
set textwidth=80
set colorcolumn=80
set number
set smarttab
set autoindent
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
Plug 'tpope/vim-commentary'
Plug 'vim-ruby/vim-ruby'
Plug 'python/black'
Plug 'ruby-formatter/rufo-vim'
Plug 'fatih/vim-hclfmt'
Plug 'mdempsky/gocode', { 'rtp': 'nvim/', 'do': '~/.config/nvim/plugged/gocode/nvim/symlink.sh' }
Plug 'rust-lang/rust.vim'
Plug 'dense-analysis/ale'
Plug 'scrooloose/nerdtree'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'tpope/vim-surround'
Plug 'Raimondi/delimitMate'
Plug 'jvirtanen/vim-hcl'
Plug 'janko-m/vim-test'
Plug 'mhinz/vim-signify'
Plug 'airblade/vim-rooter' " Determines the project root for NERDTree/fzf
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'elixir-lang/vim-elixir'
Plug 'mileszs/ack.vim'
Plug 'flazz/vim-colorschemes'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'chriskempson/base16-vim'
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' }
Plug 'AndrewRadev/splitjoin.vim'
Plug 'christoomey/vim-tmux-navigator'
Plug 'posva/vim-vue'
Plug 'junegunn/fzf', { 'do': './install --bin' }
Plug 'junegunn/fzf.vim'
Plug 'jparise/vim-graphql'
Plug 'HerringtonDarkholme/yats.vim'
Plug 'reedes/vim-pencil'
Plug 'machakann/vim-highlightedyank'
Plug 'Shougo/vimproc.vim', {'do' : 'make'}
Plug 'tpope/vim-markdown'
Plug 'junegunn/goyo.vim'
Plug 'mattly/vim-markdown-enhancements'
Plug 'ap/vim-css-color'
" All of your Plugins must be added before the following line
call plug#end()

" Ignoring files
set wildignore+=*/tmp/*,*.so,*.swp,*.zip     " MacOSX/Linux

" Ctrl-P Settings
let g:ctrlp_custom_ignore = 'DS_Store\|\.git\|tmp\|_build\|deps\|vendor'
let g:ctrlp_show_hidden = 1

" ALE Settings
let g:ale_fixers = {'html': ['html-beautify'], 'typescript': ['prettier','eslint'], 'python': ['black'], 'javascript': ['prettier', 'eslint'], 'ruby': ['rubocop', 'rufo'], 'vue': ['prettier', 'eslint'], 'scss': ['stylelint', 'prettier']}
let g:ale_linters = {'typescript': ['tsserver', 'prettier'], 'python': ['flake8'], 'javascript': ['prettier', 'eslint'], 'ruby': ['rubocop'], 'scss': ['stylelint'], 'vue': ['eslint', 'prettier', 'vls', 'tslint']}
let g:ale_fix_on_save = 1

" Airline Settings
let g:airline#extensions#ale#enabled = 1

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

" Go back to the old regex engine for now
set regexpengine=0
syntax enable
" let base16colorspace=256  " Access colors present in 256 colorspace
set termguicolors
set t_Co=256
set background=dark
colorscheme base16-ocean
let javascript_enable_domhtmlcss=1
let g:jsx_ext_required = 0


" Give more space for displaying messages.
" set cmdheight=2
" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=100

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
set signcolumn=yes

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
let g:go_metalinter_autosave = 0
let g:go_metalinter_enabled = ['vet', 'golint', 'errcheck', 'typecheck', 'staticcheck', 'deadcode', 'unused']
let g:go_metalinter_autosave_enabled=["vet", "golint", "errcheck", "typecheck", "staticcheck", "deadcode", "unused"]
let g:go_list_type = "quickfix"

"let g:syntastic_go_checkers = ['go', 'golint', 'govet', 'gometalinter']
"let g:syntastic_go_gometalinter_args = ['--disable-all', '--enable=errcheck']
"let g:syntastic_mode_map = { 'mode': 'active', 'passive_filetypes': ['go'] }

" Vim-Go Key Mappings
"autocmd FileType go nmap <leader>b  <Plug>(go-build)
autocmd FileType go nmap <leader>r  <Plug>(go-run)
autocmd FileType go nmap <leader>t  <Plug>(go-test)
autocmd FileType go nmap <Leader>c <Plug>(go-coverage-toggle)
autocmd FileType go nmap <Leader>i <Plug>(go-info)

" run :GoBuild or :GoTestCompile based on the go file
function! s:build_go_files()
  let l:file = expand('%')
  if l:file =~# '^\f\+_test\.go$'
    call go#test#Test(0, 1)
  elseif l:file =~# '^\f\+\.go$'
    call go#cmd#Build(0)
  endif
endfunction
augroup go
  autocmd!
  autocmd FileType go nmap <silent> <leader>b :<C-u>call <SID>build_go_files()<CR>
  autocmd BufWritePost *.go call <SID>build_go_files()
augroup END

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
  autocmd FileType text         call pencil#init()
augroup END

let g:prettier#config#bracket_spacing = 'true'
let g:prettier#config#parser = 'babylon'
" set rtp+=/usr/local/opt/fzf
" Run Flake8 on save
" autocmd BufWritePost *.py call Flake8()

" Deoplete Settings
let g:deoplete#enable_at_startup = 0
call deoplete#custom#option('omni_patterns', { 'go': '[^. *\t]\.\w*' })

" gopls for vim-go
let g:go_def_mode='gopls'
let g:go_info_mode='gopls'
" Override tab to autocomplete Go functions
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

let g:black_virtualenv = '/usr/local/bin/'
autocmd BufWritePre *.py execute ':Black'
let g:rustfmt_autosave = 1

" Some useful quickfix shortcuts for quickfix
map <C-n> :cn<CR>
map <C-m> :cp<CR>

nnoremap <leader>a :cclose<CR>
" DEBUG STUFF
let $NVIM_NODE_LOG_FILE='/tmp/nvim-node.log'
let $NVIM_NODE_LOG_LEVEL='info'
" Use relative path rather than absolute path for GoGuru
function! s:go_guru_scope_from_git_root()
  let gitroot = system("git rev-parse --show-toplevel | tr -d '\n'")
  let pattern = escape(go#util#gopath() . "/src/", '\ /')
  return substitute(gitroot, pattern, "", "") . "/... -vendor/"
endfunction

au FileType go silent exe "GoGuruScope " . s:go_guru_scope_from_git_root()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" coc.nvim bindings
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<CR>"
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

let g:ale_completion_tsserver_autoimport = 1
let g:coc_filetype_map = {
  \ "htmldjango": "html",
  \ }
