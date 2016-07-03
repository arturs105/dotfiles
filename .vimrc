"Set up pathogen
execute pathogen#infect()
filetype plugin indent on

syntax on
set background=dark
colorscheme stereokai

set tabstop=4

set number "Show line numbers
set cursorline "Highlight current cursor line
set wildmenu "Shows files when e: ~/.vim<TAB>
set showmatch "Highlits matching parenthesies [](){}

set incsearch "Search as characters are entered
set hlsearch "Highlight search results

"Remove highlights after search with "\<space>"
nnoremap <leader><space> :nohlsearch<CR>
"Move vertically by visual line
nnoremap j gj
nnoremap k gk

map <leader>n :NERDTree<CR>
