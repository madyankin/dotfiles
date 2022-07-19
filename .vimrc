" download vim-plug if missing
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()

" Appearance
Plug 'ayu-theme/ayu-vim'
Plug 'itchyny/lightline.vim'
Plug 'airblade/vim-gitgutter'
Plug 'dracula/vim', { 'as': 'dracula' }

" Editing
Plug 'editorconfig/editorconfig-vim'
Plug 'jiangmiao/auto-pairs'
Plug 'ervandew/supertab'
Plug 'godlygeek/tabular'
Plug 'scrooloose/nerdcommenter'
Plug 'djoshea/vim-autoread'

Plug 'sheerun/vim-polyglot'


" Navigation
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }

" Searching
Plug 'mileszs/ack.vim'

" Languages
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'maxmellon/vim-jsx-pretty', { 'for': 'javascript' } 
Plug 'mustache/vim-mustache-handlebars', { 'for': 'handlebars'  }
Plug 'soli/prolog-vim', { 'for': 'swiprolog' }
Plug 'l04m33/vlime', { 'rtp': 'vim/' }


" Rust
Plug 'racer-rust/vim-racer'
Plug 'rust-lang/rust.vim'

" Tools
Plug 'tpope/vim-fugitive'
Plug 'jceb/vim-orgmode'
Plug 'christoomey/vim-tmux-navigator'

" Local configs
Plug 'LucHermitte/lh-vim-lib'
Plug 'LucHermitte/local_vimrc'

Plug 'metakirby5/codi.vim' " scratchpad

call plug#end()

" Hack to switch to the left pane in tmux
nnoremap <silent> <BS> :TmuxNavigateLeft<cr>

" Appearance

if has("termguicolors")
 " set termguicolors
endif

" use 256 colors in terminal
if !has("gui_running")
    set t_Co=256
endif

syntax on
filetype plugin indent on
set autoindent

"let ayucolor="light"  " for light version of theme
let ayucolor="mirage" " for mirage version of theme
"let ayucolor="dark"   " for dark version of theme

colorscheme ayu

let g:airline_theme='base16_railscasts'

let g:lightline = {
  \ 'colorscheme': 'OldHope',
  \ }

set rnu " Relative line numbers


" Linting * building

filetype plugin on


" JavaScript

" pangloss/vim-javascript
let g:javascript_plugin_jsdoc = 1
let g:javascript_plugin_flow = 1

" mxw/vim-jsx
let g:jsx_ext_required = 0


" Required for operations modifying multiple buffers like rename.
set hidden

" omnifuncs
augroup omnifuncs
  autocmd!
  autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
  autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
  autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
  autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
  autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
augroup end

" Searching
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

"map <leader>s :FZF<space>
"map <leader>s :FZF<space>
"map <leader>s :FZF<space>


map <C-P> :FZF<CR>
imap <C-P> :FZF<CR>
vmap <C-P> :FZF<CR>



" UI
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

nnoremap <leader>fs :w!<CR>

map <C-T> :NERDTreeToggle<CR>
imap <C-T> :NERDTreeToggle<CR>
vmap <C-T> :NERDTreeToggle<CR>

" YCM
let g:ycm_autoclose_preview_window_after_insertion = 1
let g:ycm_autoclose_preview_window_after_completion = 1

" Misc
nnoremap <SPACE> <Nop>
let mapleader = " "

set nocompatible

set history=200			" keep 200 lines of command line history
set ruler			" show the cursor position all the time
set showcmd			" display incomplete commands
set wildmenu			" display completion matches in a status line

" Show a few lines of context around the cursor
"set scrolloff=5

" Editing
set clipboard=unnamed " Use system clipboard
set expandtab
set shiftwidth=2
set tabstop=2
set softtabstop=2
set backspace=indent,eol,start 	" Allow backspacing over everything in insert mode.

" Incremental searching is sexy
set incsearch

" Highlight things that we find with the search
set hlsearch

" Map quick shortcut to disable highlighting
map <silent> <Leader>h :nohl<CR>

" cycle through the buffers
map <C-h> :bprev<CR>
map <C-l> :bnext<CR>

" Ignoring case is a fun trick
set ignorecase
" And so is Artificial Intellegence!
set smartcase

" Highlighting the current line
set cursorline
" And keeping the cursor in the middle of the screen
"set scrolloff=7
" Don't move cursor to the start of the line on G and similar movements
set nostartofline

" CLI speed tweaks
set scrolljump=4 

" Mapping <C-W>d to deleting the buffer, but keeping current layout
map <silent> <C-W>d :BD<CR>

" Hiding Fugitive's buffers
autocmd BufReadPost fugitive://* set bufhidden=delete

" and custom ones per file type
autocmd FileType elm setlocal shiftwidth=4 tabstop=4 softtabstop=4
autocmd FileType rust setlocal shiftwidth=4 tabstop=4 softtabstop=4

autocmd BufNewFile,BufRead *Vagrantfile set filetype=ruby

set shell=zsh

" Folding settings
set foldmethod=manual

" commands recognition in RU keyboard layout
set langmap=ёйцукенгшщзхъфывапролджэячсмитьбюЁЙЦУКЕHГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ;`qwertyuiop[]asdfghjkl\\;'zxcvbnm\\,.~QWERTYUIOP{}ASDFGHJKL:\\"ZXCVBNM<>

" Ack word under cursor
noremap <Leader>aa :Ack! <cword><CR>
" and ack plugin switched to ag
let g:ackprg = 'ag --nogroup --nocolor --column'

" storing session data in viminfo
set viminfo='10,\"100,:20,%,n~/.viminfo
" and jump to the previous position in the file when it's open
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif

if has('mouse')
  set mouse=a
endif


" Tools
let g:markdownfmt_autosave=0


" Hide tildas
hi clear NonText 
hi link NonText Ignore 
au ColorScheme * hi clear NonText | hi link NonText Ignore 


" Automatically clean up trailing whitespaces for certain filetypes
fun! <SID>StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun

autocmd BufWritePre *.py :call <SID>StripTrailingWhitespaces()
autocmd BufWritePre *.rb :call <SID>StripTrailingWhitespaces()
autocmd BufWritePre *.erb :call <SID>StripTrailingWhitespaces()
autocmd BufWritePre *.haml :call <SID>StripTrailingWhitespaces()
autocmd BufWritePre *.hamlbars :call <SID>StripTrailingWhitespaces()
autocmd BufWritePre *.sass :call <SID>StripTrailingWhitespaces()
autocmd BufWritePre *.md :call <SID>StripTrailingWhitespaces()
autocmd BufWritePre *.js :call <SID>StripTrailingWhitespaces()
autocmd BufWritePre *.html :call <SID>StripTrailingWhitespaces()


" Format Markdown files.
function! MarkdownFormat()
   let save_pos = getpos(".")
   let query = getreg('/')
   execute ":0,$!tidy-markdown"
   call setpos(".", save_pos)
   call setreg('/', query)
endfunction

au BufWritePre *.md :call MarkdownFormat()

silent! source .vimlocal
