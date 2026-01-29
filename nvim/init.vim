set shiftwidth=4
set tabstop=4
set clipboard=unnamedplus
call plug#begin()
Plug 'ntk148v/vim-horizon'
Plug 'rebelot/kanagawa.nvim'
Plug 'preservim/nerdtree'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'f-person/git-blame.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'sindrets/diffview.nvim'
Plug 'lewis6991/gitsigns.nvim'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'ryanoasis/vim-devicons'
Plug 'RRethy/vim-illuminate'
Plug 'kevinhwang91/promise-async'
Plug 'kevinhwang91/nvim-ufo'
Plug 'folke/which-key.nvim'
Plug 'folke/todo-comments.nvim'
call plug#end()

" カラースキーム
colorscheme kanagawa

" fzf: カレントディレクトリ全体を検索（gitignoreを尊重）
let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --glob "!.git" 2>/dev/null'

" fzf: 履歴を保存（Ctrl+P/Ctrl+N または 上下キーで呼び出し）
let g:fzf_history_dir = '~/.local/share/fzf-history'

nnoremap <C-n> :NERDTreeToggle<CR>
nnoremap <C-h> :NERDTreeFocus<CR>
nnoremap <C-f> :NERDTreeFind<CR>
nnoremap <C-p> :FilesProject<CR>
nnoremap <C-g> :RgProject<CR>

" プラグイン管理
nnoremap <Leader>pi :PlugInstall<CR>
nnoremap <Leader>pu :PlugUpdate<CR>
nnoremap <Leader>pc :PlugClean<CR>

" バッファ操作
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprev<CR>
nnoremap <C-q> :bd<CR>

" ウィンドウ移動
nnoremap <C-e> :wincmd p<CR>

" ファイル内検索
nnoremap <C-l> :BLines<CR>

" NERDTree: 左に固定、幅30%
let g:NERDTreeWinPos = "left"
let g:NERDTreeWinSize = 31
let g:NERDTreeShowHidden = 1

" 起動時にNERDTreeを自動で開く + 最後に開いたファイルを復元
autocmd VimEnter * ++nested call s:RestoreLastFile() | NERDTree | wincmd p

function! s:RestoreLastFile()
  " 引数なしで起動した場合のみ
  if argc() == 0 && len(v:oldfiles) > 0
    let cwd = getcwd()
    for f in v:oldfiles
      " 現在のディレクトリ内のファイルのみを対象にする
      if stridx(f, cwd) == 0 && filereadable(f)
        execute 'edit' fnameescape(f)
        break
      endif
    endfor
  endif
endfunction

" gitsigns.nvim 設定
lua << EOF
require('gitsigns').setup({
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns
    local opts = {buffer = bufnr}
    -- 変更箇所にジャンプ
    vim.keymap.set('n', ']c', gs.next_hunk, opts)
    vim.keymap.set('n', '[c', gs.prev_hunk, opts)
    -- 変更内容をプレビュー
    vim.keymap.set('n', 'gp', gs.preview_hunk, opts)
  end
})

-- indent-blankline
require('ibl').setup()

-- which-key
require('which-key').setup()

-- todo-comments
require('todo-comments').setup()

-- nvim-ufo (折りたたみ)
vim.o.foldcolumn = '1'
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
require('ufo').setup({
  provider_selector = function(bufnr, filetype, buftype)
    return {'treesitter', 'indent'}
  end
})
vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

-- vim-illuminate (カーソル下の単語をハイライト)
require('illuminate').configure({
  delay = 100,
  filetypes_denylist = {'nerdtree', 'fugitive'},
})

-- diffview.nvim
vim.keymap.set('n', '<Leader>dd', ':DiffviewOpen develop<CR>', { desc = 'Diff with develop' })
vim.keymap.set('n', '<Leader>dm', ':DiffviewOpen main<CR>', { desc = 'Diff with main' })
vim.keymap.set('n', '<Leader>do', ':DiffviewOpen ', { desc = 'Diff with branch...' })
vim.keymap.set('n', '<Leader>dc', ':DiffviewClose<CR>', { desc = 'Close diffview' })

-- 相対パス:行番号 をクリップボードにコピー（NERDTree以外）
vim.keymap.set('n', 'yp', function()
  if vim.bo.filetype == 'nerdtree' then return end
  local path = vim.fn.expand('%')
  local line = vim.fn.line('.')
  local text = path .. ':' .. line
  vim.fn.setreg('+', text)
  vim.notify('Copied: ' .. text)
end, { desc = 'Copy relative path:line to clipboard' })

-- ビジュアルモード: path:start-end
vim.keymap.set('v', 'yp', function()
  local path = vim.fn.expand('%')
  local start_line = vim.fn.line('v')
  local end_line = vim.fn.line('.')
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local text = path .. ':' .. start_line .. '-' .. end_line
  vim.fn.setreg('+', text)
  vim.notify('Copied: ' .. text)
end, { desc = 'Copy relative path:lines to clipboard' })
EOF

" fzfで開いたファイルをNERDTree以外のウィンドウで開く
function! OpenInMainWindow(file)
  " NERDTreeウィンドウにいる場合は右に移動
  if exists('b:NERDTree')
    wincmd l
  endif
  execute 'edit' fnameescape(a:file)
endfunction

function! OpenRgResultInMainWindow(line)
  let file = split(a:line, ':')[0]
  call OpenInMainWindow(file)
endfunction

" Files: NERDTreeを維持してファイルを開く
command! -bang -nargs=? -complete=dir FilesProject
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'sink': function('OpenInMainWindow')}), <bang>0)

" RgProject: 結果をメインウィンドウで開く
command! -bang -nargs=* RgProject
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>),
  \   1, fzf#vim#with_preview({'sink': function('OpenRgResultInMainWindow')}), <bang>0)

" NERDTree: ファイルパスをクリップボードにコピー
function! NERDTreeYankRelativePath()
    let node = g:NERDTreeFileNode.GetSelected()
    if node != {}
        let @+ = fnamemodify(node.path.str(), ':.')
        echo "Copied: " . @+
    endif
endfunction

function! NERDTreeYankAbsolutePath()
    let node = g:NERDTreeFileNode.GetSelected()
    if node != {}
        let @+ = node.path.str()
        echo "Copied: " . @+
    endif
endfunction

autocmd FileType nerdtree nmap <buffer> yp :call NERDTreeYankRelativePath()<CR>
autocmd FileType nerdtree nmap <buffer> yP :call NERDTreeYankAbsolutePath()<CR>

