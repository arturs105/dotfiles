"Set up pathogen
execute pathogen#infect()
filetype plugin on

syntax on
set background=dark
colorscheme stereokai

set tabstop=4

set relativenumber "Show relative line numbers
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
let g:OmniSharp_selector_ui = 'ctrlp'
let g:OmniSharp_host = "http://localhost:2000"
