"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Copyright 2012 Mike Dreves
"
" All rights reserved. This program and the accompanying materials
" are made available under the terms of the Eclipse Public License v1.0
" which accompanies this distribution, and is available at:
"
"     http://opensource.org/licenses/eclipse-1.0.php
"
" By using this software in any fashion, you are agreeing to be bound
" by the terms of this license. You must not remove this notice, or any
" other, from this software. Unless required by applicable law or agreed
" to in writing, software distributed under the License is distributed
" on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
" either express or implied.
"
" @author Mike Dreves
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! ide#mikemode#Vars() abort " {{{
  " Source code file extensions
  let g:ide_code_files="
    \*.scala,*.java,*.clj,*.cljs,
    \*.hs,
    \*.go,
    \*.py,*.rb,
    \*.c,*.cpp,*.h,a
    \*.m
    \*.js,*.css,*.less,*.php,
    \*.xml,*.snippet,*.html,*.xhtml"

  " Source code filetypes
  let g:ide_code_filetypes=[
    \ "scala", "java", "clojure",
    \ "haskell",
    \ "go",
    \ "python", "ruby",
    \ "c", "cpp",
    \ "objc", "objcpp",
    \ "javascript", "css", "less", "php",
    \ "xml", "snippet", "html", "xhtml"
    \]

  " Special filetypes (qf is quickfix window)
  let g:ide_code_helper_filetypes=[
    \ "qf", "help", "nerdtree", "taglist", "conque_term"
    \]

  " Special buffer names
  let g:ide_code_helper_buftypes=[
    \ "quickfix", "help"
    \]

  let g:ide_colorschemes = [
    \ ["mikedreves", "light"],
    \ ["mikedreves", "dark"],
    \ ["plain", "light"],
    \ ["zenburn", "dark"],
  \]
    "\ ["solarized", "light"],
    "\ ["solarized", "dark"],
    "\ [default_colorscheme, "light", g:background_color],
    "\ ["mustang", "dark"],
    "\ ["rdark", "dark"],
    "\ ["darkspectrum", "dark"],
    "\ ["textpad", "light", g:background_color],
    "\ ["eclipse", "light", g:background_color],
    "\ ["railscasts", "dark"],

  let g:ide_filetype_settings = {
    \ 'default': {
    \     'colorscheme': -1,
    \     'local_settings':
      \       "expandtab shiftwidth=2 tabstop=2 softtabstop=2 " .
      \       "textwidth=80 linebreak wrapmargin=0 wrap " .
      \       "formatexpr=g:IdeFormatSelected('expr')",
    \     'margin': -1,
    \     'project': 'projux',
    \     'search': 'projux',
    \     'format': 'projux',
    \     'lint': 'projux',
    \     'build': 'projux',
    \     'test': 'projux',
    \     'coverage': 'projux',
    \     'run': 'projux',
    \     'sanity': 'projux',
    \     'fix': 'eclim',
    \     'gen': 'eclim',
    \     'move': 'eclim',
    \     'rename': 'eclim',
    \     'show': 'eclim',
    \  },
    \ 'diff': {
    \     'colorscheme': 2,
    \     'local_settings':  "wrap",
    \     'margin': 0,
    \  },
    \ 'help': {
    \     'colorscheme': -1,
    \     'local_settings':  "wrap",
    \     'margin': 0,
    \  },
    \ 'java': {
    \     'colorscheme': 1,
    \     'local_settings':
      \       "number expandtab shiftwidth=2 tabstop=2 softtabstop=2 " .
      \       "textwidth=90 linebreak wrapmargin=0 wrap " .
      \       "formatexpr=g:IdeFormatSelected('expr')",
    \     'margin': 1,
    \     'project': 'eclim',
    \     'search': 'eclim',
    \     'format': 'eclim',
    \     'lint': 'eclim',
    \     'build': 'eclim',
    \     'test': 'eclim',
    \     'coverage': 'eclim',
    \     'run': 'eclim',
    \     'sanity': 'eclim',
    \     'fix': 'eclim',
    \     'gen': 'eclim',
    \     'move': 'eclim',
    \     'rename': 'eclim',
    \     'show': 'eclim',
    \  },
    \ 'go': {
    \     'colorscheme': 1,
    \     'local_settings':
      \       "number noexpandtab shiftwidth=2 tabstop=2 softtabstop=2 " .
      \       "linebreak wrapmargin=0 wrap " .
      \       "formatexpr=g:IdeFormatSelected('expr')",
    \     'margin': 1,
    \  },
  \}

  for file_type in g:ide_code_filetypes
    if !has_key(g:ide_filetype_settings, file_type)
      let g:ide_filetype_settings[file_type] = {
        \     'colorscheme': 1,
        \     'local_settings':
          \       "number expandtab shiftwidth=2 tabstop=2 softtabstop=2 " .
          \       "textwidth=80 linebreak wrapmargin=0 wrap " .
          \       "formatexpr=g:IdeFormatSelected('expr')",
        \     'margin': 1,
        \  }
    endif
  endfor

  " Format on save
  if exists("g:ide_format_on_save") && g:ide_format_on_save
    autocmd BufWritePre *
      \ if index(g:ide_code_filetypes, &filetype) >= 0 |
      \   call g:IdeFormat(":buffer") |
      \ endif
  endif

  augroup ide_cpp_colors_augroup
    autocmd! BufWinEnter *.c,*.cc,*.h,*.cpp
    autocmd BufWinEnter *.c,*.cc,*.h,*.cpp call <SID>CustomCHighlights()
  augroup END
endfunction " }}}


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Closes current buffer unless last buffer and last buffer is a file, in which
" case quits.
function s:CustomQuit() abort " {{{
  let open_files = ide#util#GetOpenFileBuffers()
  if len(open_files) == 1
    if bufnr(open_files[0]) ==? bufnr('')
      call ide#view#CloseAllViews()
      :q
    else
      :bd
    endif
  else
    :bd
  endif
endfunction " }}}


" Highlight C++ class and function names (not provided by default)
function s:CustomCHighlights() abort " {{{
  syn match    cCustomParen    "?=(" contains=cParen,cCppParen
  syn match    cCustomFunc     "\w\+\s*(\@=" contains=cCustomParen
  syn match    cCustomScope    "::"
  syn match    cCustomClass    "\w\+\s*::" contains=cCustomScope

  hi def link cCustomScope Identifer
  hi def link cCustomFunc  Function
  hi def link cCustomClass Class
endfunction " }}}


function! s:TmuxOrSplitSwitch(wincmd, tmuxdir)
  let previous_winnr = winnr()
  execute "wincmd " . a:wincmd
  if previous_winnr == winnr()
    " The sleep and & gives time to get back to vim so tmux's focus
    " tracking can kick in and send us our ^[[O
    execute "silent !sh -c 'sleep 0.01; tmux select-pane -" .
       \ a:tmuxdir . "' &"
    redraw!
  endif
endfunction


let s:bundle = expand('<sfile>:h:h:h:h')

" Delayed loading of YCM.
"
" NOTE Must have g:loaded_youcompleteme = 0 in .vimrc for this to work.
function s:LoadYcm() abort " {{{
  if ! exists("g:loaded_youcompleteme") || ! g:loaded_youcompleteme
    unlet g:loaded_youcompleteme
    exec "source " . s:bundle . "/YouCompleteMe/plugin/youcompleteme.vim"
    call youcompleteme#Enable()
  endif
endfunction " }}}


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! ide#mikemode#Mappings() abort " {{{
  " Navigation
  """""""""""""""""

  " Page forward/back with ctrl-{j,k}
  noremap <c-j> <c-d>
  noremap <c-k> <c-u>

  " Wildmenu up/down keys (ctrl-n, ctrl-p) with {j,k}
  if ! ide#plugin#PluginExists("YouCompleteMe")
    inoremap <expr> j ((pumvisible())?("\<c-n>"):("j"))
    inoremap <expr> k ((pumvisible())?("\<c-p>"):("k"))
  endif

  " Start/End of file/line with f{k,j,h,l}
  noremap <silent> fj GG
  noremap <silent> fk :0<cr>
  noremap <silent> fh ^
  noremap <silent> fl $

  " ff to return to previous position
  noremap <silent> ff ''

  " gg to switch to previous buffer
  nnoremap gg :e#<CR>

  " Tag forward/back with gj/k (e.g. ctrl-], ctrl-t)
  nnoremap <silent> gj <c-]>
  nnoremap <silent> gk <c-t>

  " Moving between windows with w{j,k,h,l}
  if exists('$TMUX')
    " Re-enable if needed (system call costs too much on startup)
    "let previous_title = substitute(system(
    "   \ "tmux display-message -p '#{pane_title}'"), '\n', '', '')
    let &t_ti = "\<Esc>]2;vim\<Esc>\\" . &t_ti
    "let &t_te = "\<Esc>]2;". previous_title . "\<Esc>\\" . &t_te

    noremap <silent> fwj :call <SID>TmuxOrSplitSwitch('j', 'D')<cr>
    noremap <silent> fwk :call <SID>TmuxOrSplitSwitch('k', 'U')<cr>
    noremap <silent> fwh :call <SID>TmuxOrSplitSwitch('h', 'L')<cr>
    noremap <silent> fwl :call <SID>TmuxOrSplitSwitch('l', 'R')<cr>
  else
    noremap <silent> fwj <c-w>j
    noremap <silent> fwk <c-w>k
    noremap <silent> fwh <c-w>h
    noremap <silent> fwl <c-w>l
  endif

  " Moving between windows and maximizing window with alt-{j,k,h,l}
  noremap <silent> <a-j> <c-w>j<c-w>_
  noremap <silent> <a-k> <c-w>k<c-w>_
  noremap <silent> <a-h> <c-w>h<c-w><bar>
  noremap <silent> <a-l> <c-w>l<c-w><bar>

  " Ctrl-w in insert mode means delete line, remap to mean change window
  inoremap <silent> <c-w> <c-o><c-w>

  " Resize windows with z{j/k/h/l} (zoom in/out/left/right)
  nnoremap zk <c-w>+
  nnoremap zj <c-w>-
  nnoremap zh <c-w><
  nnoremap zl <c-w>>

  " Map ctrl-space to ctrl-x ctrl-u auto completion window
  if ! ide#plugin#PluginExists("YouCompleteMe")
    inoremap <c-space> <c-x><c-u>
    inoremap <c-@> <c-space>
  else
    noremap <silent> <leader>y :call <SID>LoadYcm()<cr>
  endif


  " Tabbing (cycling) Mappings
  """""""""""""""""

  " Tabbing between windows with w<space> (next), w<space><space> (previous)
  noremap <silent> w<space> <c-w>w
  noremap <silent> w<space><space> <c-w>p

  " Tabbing between ext wins with e<space> (next), e<space><space> (previous)
  noremap <silent> e<space> :call g:IdeNextExternalView()<cr>
  noremap <silent> e<space><space> :call g:IdePrevExternalView()<cr>

  " Tabbing between tabs with t<space> (next), t<space><space> (previous)
  noremap <silent> t<space> :tabnext<cr>
  noremap <silent> t<space><space> :tabprev<cr>

  " Tabbing between tmux windows with ctrl-a n (next), ctrl-a p (previous)
  noremap <silent> <c-a>n :call ide#tmux#NextWindow()<cr>
  noremap <silent> <c-a>p :call ide#tmux#PrevWindow()<cr>

  " Tabbing between colorschemes with c<space> (next), c<space><space> (prev)
  noremap <silent> c<space> :call g:IdeNextColorscheme()<cr>
  noremap <silent> c<space><space> :call g:IdePrevColorscheme()<cr>


  " Quit mappings
  """""""""""""""""

  " Custom quit
  noremap <silent> q :call <SID>CustomQuit()<cr>
endfunction " }}}
