"Set up pathogen
execute pathogen#infect()
filetype plugin on

syntax on
set background=dark
colorscheme stereokai

set tabstop=4

set relativenumber "Show relative line numbers
set number "Show absolute number for current line
set cursorline "Highlight current cursor line
set wildmenu "Shows files when e: ~/.vim<TAB>
set showmatch "Highlits matching parenthesies [](){}

set ignorecase "Case insensitive search
set incsearch "Search as characters are entered
set hlsearch "Highlight search results

set mouse=a

"Remove highlights after search with "\<space>"
nnoremap <leader><space> :nohlsearch<CR>
"Move vertically by visual line
nnoremap j gj
nnoremap k gk

"Tab movement
nnoremap tn :tabnew
nnoremap tk :tabnext<CR>
nnoremap tj :tabprevious<CR>
nnoremap th :tabfirst<CR>
nnoremap tl :tablast<CR>

"\n opens NERDTree
map <leader>n :NERDTree<CR>
