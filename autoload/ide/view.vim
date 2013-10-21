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
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Variables
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Display settings
let s:gutter_width = 3  " Width of gutter (left line nums, right just display)
let s:extended_gutter_width = 2  " Extended gutter (displays signs), left only
let s:min_center_width =
  \ &textwidth + s:gutter_width + s:extended_gutter_width  " Main win

" Display state
let s:right_sidebar_width = 0  " Current width of right sidebar
let s:left_sidebar_width = 0  " Current width of left sidebar

" View state
let s:buffers_view_open = 0  " True if buffers view open
let s:projects_view_open = 0  " True if projects view open
let s:explorer_view_open = 0  " True if file/project explorer view open
let s:outline_view_open = 0  " True if outline view open
let s:terminal_view_open = 0  " True if terminal view open
let s:browser_view_open = 0  " True if browser view open
let s:quickfix_view_open = 0  " True if quickfix view open
let s:location_view_open = 0  " True if location view open
let s:help_view_open = 0  " True if help view open
let s:git_view_open = 0  " True if git view open
let s:diff_view_open = 0  " True if diff view open
let s:split_view_open = 0  " True if split view open
let s:mirror_view_open = 0  " True if mirror view open

let s:list_view_open = 0  " True if a list view open (general view)

let s:external_terminal = 0  " True if external terminal used
let s:external_browser = 0 " True is external browser used

let s:last_gvim_view = "" " Name of last internal gvim view opened
let s:cur_external_id = g:EXTERNAL_GVIM_ID  " Id of current external window

" Last window state
let s:return_to_win_num = 0  " Win used before a view opened
let s:return_to_win_x = 0  " X pos of win before views opened
let s:return_to_win_y = 0  " Y pos of win before views opened

" Stacks of currently open views by position. These contain alternating
" entries of [view_name, buf_num, view_name, buf_num, ...]
"
" NOTE: The current implementation does not require a stack be used as
"   only one item will ever be placed in the stack, but the code was already
"   working and tested when the reopen_stack was added so it remains as is.
let s:top_view_stack = []  " Stack of open top views
let s:bottom_view_stack = []  " Stack of open bottom views
let s:left_view_stack = []  " Stack of open left views
let s:right_view_stack = []  " Stack of open right views

" Stacks of views that were closed because another view using the same position
" was opened. These contain alternating entries of [view_name, buf_num,...]
" where buf_num is for the view that closed view_name, not view_name itself
let s:top_reopen_stack = []  " Stack of top views to reopen
let s:bottom_reopen_stack = []  " Stack of bottom views to reopen
let s:left_reopen_stack = []  " Stack of left views to reopen
let s:right_reopen_stack = []  " Stack of right views to reopen

" Ugly side-effecting state variables...
let s:processing_open_view = 0
let s:last_win_opened = 0  " Name of last window opened
let s:last_browser_url = ""  " Name of last url opened
let s:last_help_subject = ""  " Name of last help subject opened
let s:last_git_cmd = []  " Name of last fugative url in git view
let s:last_diff_file_name = ""  " Name of last file in diff view
let s:pre_diff_state = {}  " State of vars prior to diff
let s:last_split_file_name = ""  " Name of last file in split view
let s:last_mirror_buf_name = ""  " Name of last buffer mirrored


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" View Openers/Closers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Opens view.
"
" Args:
"   target: 'buffers', 'project', 'explorer', 'outline', 'terminal', 'browser',
"     'quickfix', 'location', 'help', 'git', 'diff', 'split', 'mirror'
"   a:1 : Additional args specific to target (e.g. browser url, help subject,
"     git url, diff file, split file, ...)
function! ide#view#OpenView(target, ...) abort " {{{
  if a:target ==# "buffers"
    call ide#view#OpenBuffersView()
  elseif a:target ==# "location"
    call ide#view#OpenLocationView()
  elseif a:target ==# "quickfix"
    call ide#view#OpenQuickfixView()
  elseif a:target ==# "projects" && exists("g:ide_projects_opener")
    call call("ide#util#EvalCall", [g:ide_projects_opener] + a:000)
  elseif a:target ==# "explorer" && exists("g:ide_explorer_opener")
    call call("ide#util#EvalCall", [g:ide_explorer_opener] + a:000)
  elseif a:target ==# "outline" && exists("g:ide_outline_opener")
    call ide#util#EvalCall(g:ide_outline_opener)
  elseif a:target ==# "terminal" && exists("g:ide_terminal_opener")
    call ide#util#EvalCall(g:ide_terminal_opener)
  elseif a:target ==# "browser" && exists("g:ide_browser_opener")
    if a:0 > 0
      let s:last_browser_url = a:1
      call ide#util#EvalCall(g:ide_browser_opener, a:1)
    else
      let s:last_browser_url = ""
      call ide#util#EvalCall(g:ide_browser_opener)
    endif
  elseif ide#view#IsVimSpecialView(a:target)
    " If special window already open then close it first
    let buf_num = <SID>FindViewNum(a:target)
    if buf_num != -1
      call ide#view#CloseVimSpecialView(a:target)
    endif

    if a:0 > 0
      if a:target ==# "help"
        let s:last_help_subject = a:1
      endif
      call ide#view#OpenVimSpecialView(a:target, a:1)
    else
      if a:target ==# "help"
        let s:last_help_subject = ""
      endif
      call ide#view#OpenVimSpecialView(a:target)
    endif
  elseif a:target ==# "git" && exists("g:ide_git_opener")
    let s:last_git_cmd = a:000
    call call("ide#util#EvalCall", [g:ide_git_opener] + a:000)
  elseif a:target ==# "diff"
    if a:0 > 0
      let s:last_diff_file_name = a:1
      call ide#view#OpenDiffView(a:1)
    else
      let s:last_diff_file_name = ""
      call ide#view#OpenDiffView()
    endif
  elseif a:target ==# "split"
    if a:0 > 0
      let s:last_split_file_name = a:1
      call ide#view#OpenSplitView(a:1)
    else
      let s:last_split_file_name = ""
      call ide#view#OpenSplitView()
    endif
  elseif a:target ==# "mirror"
    call ide#view#OpenMirrorView()
  endif
endfunction " }}}


" Closes view.
"
" Args:
"   target: 'buffers', 'project', 'explorer', 'outline', 'terminal', 'browser',
"     'quickfix', 'location', 'help', 'git', 'diff', 'split', 'mirror'
"   a:1: True if close should exit terminal/browser (default is false)
function! ide#view#CloseView(target, ...) abort " {{{
  if a:target ==# "buffers"
    call ide#view#CloseBuffersView()
  elseif a:target ==# "location"
    call ide#view#CloseLocationView()
  elseif a:target ==# "quickfix"
    call ide#view#CloseQuickfixView()
  elseif a:target ==# "projects" && exists("g:ide_projects_closer")
    call ide#util#EvalCall(g:ide_projects_closer)
  elseif a:target ==# "explorer" && exists("g:ide_explorer_closer")
    call ide#util#EvalCall(g:ide_explorer_closer)
  elseif a:target ==# "outline" && exists("g:ide_outline_closer")
    call ide#util#EvalCall(g:ide_outline_closer)
  elseif a:target ==# "terminal" && exists("g:ide_terminal_closer")
    if a:0 > 0
      call ide#util#EvalCall(g:ide_terminal_closer, a:1)
    else
      call ide#util#EvalCall(g:ide_terminal_closer)
    endif
  elseif a:target ==# "browser" && exists("g:ide_browser_closer")
    if a:0 > 0
      call ide#util#EvalCall(g:ide_browser_closer, a:1)
    else
      call ide#util#EvalCall(g:ide_browser_closer)
    endif
  elseif ide#view#IsVimSpecialView(a:target)
    call ide#view#CloseVimSpecialView(a:target)
  elseif a:target ==# "git" && exists("g:ide_git_closer")
    call ide#util#EvalCall(g:ide_git_closer)
  elseif a:target ==# "diff"
    call ide#view#CloseDiffView()
  elseif a:target ==# "split"
    call ide#view#CloseSplitView()
  elseif a:target ==# "mirror"
    call ide#view#CloseMirrorView()
  elseif a:target ==# "list"
    let buf_num = <SID>FindViewNum(a:target)
    if buf_num != -1
      ide#util#CloseWindow(bufname(buf_num))
    endif
  endif
endfunction " }}}


" Closes all views.
function! ide#view#CloseAllViews() abort " {{{
  if s:buffers_view_open == 1
    call ide#view#CloseView("buffers")
  endif
  if s:projects_view_open == 1
    call ide#view#CloseView("projects")
  endif
  if s:explorer_view_open == 1
    call ide#view#CloseView("explorer")
  endif
  if s:outline_view_open == 1
    call ide#view#CloseView("outline")
  endif
  if s:terminal_view_open == 1 && ! s:external_terminal
    call ide#view#CloseView("terminal")
  endif
  if s:browser_view_open == 1 && ! s:external_browser
    call ide#view#CloseView("browser")
  endif
  if s:quickfix_view_open == 1
    call ide#view#CloseView("quickfix")
  endif
  if s:location_view_open == 1
    call ide#view#CloseView("location")
  endif
  if s:help_view_open == 1
    call ide#view#CloseView("help")
  endif
  if s:git_view_open == 1
    call ide#view#CloseView("git")
  endif
  if s:git_view_open == 1
    call ide#view#CloseView("diff")
  endif
  if s:git_view_open == 1
    call ide#view#CloseView("split")
  endif
  if s:git_view_open == 1
    call ide#view#CloseView("mirror")
  endif
  if s:git_view_open == 1
    call ide#view#CloseView("list")
  endif
endfunction " }}}


" Toggles view.
"
" Args:
"   target: 'buffers', 'project', 'explorer', 'outline', 'terminal', 'browser',
"     'quickfix', 'location', 'help', 'git', 'diff', 'split', 'mirror'
function! ide#view#ToggleView(target) abort " {{{
  let pos = <SID>GetViewPos(a:target)
  let view_stack = <SID>GetViewStack(pos)
  if len(view_stack) > 0 && view_stack[-2] !=# a:target
    " If view currently open in this position ignore toggle (unless this view)
    let buf_num = <SID>FindViewNum(a:target)
    if bufwinnr(buf_num) == winnr()
      return
    endif
  endif

  " If trying to toggle from a view ignore unless same view
  let view_name = <SID>FindViewName(bufnr("%"))
  if !empty(view_name) && view_name !=# a:target
    return
  endif

  " If in a re-open stack, then remove it
  let reopen_stack = <SID>GetReopenStack(pos)
  let offset = index(reopen_stack, a:target)
  if offset != -1
    call remove(reopen_stack, string(offset + 1))
    call remove(reopen_stack, string(offset + 0))
  endif

  let var_name = "s:" . a:target . "_view_open"
  if eval('exists("' . var_name . '") && ' . var_name . " == 0")
    if a:target ==# "browser" && !empty(s:last_browser_url)
      call ide#view#OpenView(a:target, s:last_browser_url)
    elseif a:target ==# "help" && !empty(s:last_help_subject)
      call ide#view#OpenView(a:target, s:last_help_subject)
    elseif a:target ==# "git" && len(s:last_git_cmd) > 0
      call call("ide#view#OpenView", [a:target] + s:last_git_cmd)
    elseif a:target ==# "diff" && !empty(s:last_diff_file_name)
      call ide#view#OpenView(a:target, s:last_diff_file_name)
    elseif a:target ==# "split" && !empty(s:last_split_file_name)
      call ide#view#OpenView(a:target, s:last_split_file_name)
    else
      call ide#view#OpenView(a:target)
    endif
  else
    call ide#view#CloseView(a:target)
  endif
endfunction " }}}


" Sets view window width
"
" Args:
"   target: 'buffers', 'project', 'explorer', 'outline', 'terminal', 'browser',
"     'quickfix', 'location', 'help', 'git', 'diff', 'split', 'mirror'
"   width: Width to set (in columns).
function! ide#view#SetViewWidth(target, width) abort " {{{
  let buf_num = <SID>FindViewNum(a:target)
  if buf_num > 0 && (bufnr("%") == buf_num || winnr() == bufwinnr(buf_num))
      \ || (a:target ==# "help" && !empty(s:last_help_subject))
    " TODO: Help is strange, first time it is opened it works as expected, but
    "   second openings don't match the cur buf win. The above hack fixes it
    exec ":vertical resize " . a:width
  else
    " +1 for splitter
    exec ":vertical resize " . (&columns - (a:width + 1))
  endif
endfunction " }}}


" Sets view window height
"
" Args:
"   target: 'buffers', 'project', 'explorer', 'outline', 'terminal', 'browser',
"     'quickfix', 'location', 'help', 'git', 'diff', 'split', 'mirror'
"   height: Height to set (in lines).
function! ide#view#SetViewHeight(target, height) abort " {{{
  let buf_num = <SID>FindViewNum(a:target)
  if buf_num > 0 && (bufnr("%") == buf_num || winnr() == bufwinnr(buf_num))
      \ || (a:target ==# "help" && !empty(s:last_help_subject))
    " TODO: Help is strange, first time it is opened it works as expected, but
    "   second openings don't match the cur buf win. The above hack fixes it
    exec ":resize " . a:height
  else
    " +1 for splitter
    exec ":resize " . (&lines - (a:height + 1))
  endif
endfunction " }}}


" Opens buffers view.
function! ide#view#OpenBuffersView() abort " {{{
  call ide#util#ChooseBuffer(
    \ 1, "buffers", g:ide_buffers_view_pos, g:ide_buffers_view_size,
    \ "ide#view#BufferChosenCb")
endfunction " }}}


" Callback for when buffer chosen from temp window.
function! ide#view#BufferChosenCb(action, buf_num, buf_name) abort " {{{
  if empty(a:buf_name)
    if a:action ==# 'e'
      exec "buffer " . a:buf_num
    endif
  elseif a:action ==# 't'
    exec "tabe " . a:buf_name
  elseif a:action ==# 's'
    call ide#view#OpenView("split", a:buf_name)
  elseif a:action ==# 'e'
    exec "edit " . a:buf_name
  elseif a:action ==# 'E'
    silent exec "!gvim " . a:buf_name
  elseif a:action ==# 'd'
    call ide#view#OpenView("diff", a:buf_name)
  elseif a:action ==# 'D'
    silent exec "!gvimdiff -R " . expand("%") . " " . a:buf_name
  endif
endfunction " }}}


" Closes buffers view.
function! ide#view#CloseBuffersView() abort " {{{
  call ide#util#CloseWindow('buffers')
endfunction " }}}


" Opens location view.
function! ide#view#OpenLocationView() abort " {{{
  call ide#util#ShowLocations(
    \ "location", "location", g:ide_location_view_pos, g:ide_location_view_size)
endfunction " }}}


" Closes location view.
function! ide#view#CloseLocationView() abort " {{{
  call ide#util#CloseWindow("location")
endfunction " }}}


" Opens quickfix view.
function! ide#view#OpenQuickfixView(...) abort " {{{
  call ide#util#ShowLocations(
    \ "quickfix", "quickfix", g:ide_quickfix_view_pos, g:ide_quickfix_view_size)
endfunction " }}}


" Closes quickfix view.
function! ide#view#CloseQuickfixView() abort " {{{
  call ide#util#CloseWindow("quickfix")
endfunction " }}}


" Opens browser view.
"
" Args:
"   url: URL to open.
function! ide#view#OpenBrowserView(url) abort " {{{
  call ide#view#OpenView("browser", a:url)
endfunction " }}}


" Checks if target is a VIM special view (quickfix, location, help).
"
" Args:
"   target: 'buffers', 'project', 'explorer', 'outline', 'terminal', 'browser',
"     'quickfix', 'location', 'help', 'git', 'diff', 'split', 'mirror'
function! ide#view#IsVimSpecialView(target) abort " {{{
  " NOTE: We could support 'quickfix' and 'location' here as well, but we
  "   want to have a specially formatted window
  if a:target ==# "help"
    return 1
  else
    return 0
  endif
endfunction " }}}


" Opens VIM special view (quickfix, location, help).
"
" NOTE: Although quickfix and location list are supported here, they
"   are not used. A specially formatted window is used instead.
"
" Args:
"   target: 'quickfix', 'location', 'help'
"   a:1 : Additional args specific to window (e.g. subject for help)
function! ide#view#OpenVimSpecialView(target, ...) abort " {{{
  if a:target ==# "quickfix"
    " If want to hide filename:
    "   set conceallevel=2 concealcursor=nc
    "   syntax match qfFileName /^[^|]*/ transparent conceal
    let cmd = "copen"
  elseif a:target ==# "location"
    if len(getloclist(0)) == 0
      return ide#util#EchoError("Location list is empty")
    endif
    " If want to hide filename:
    "   set conceallevel=2 concealcursor=nc
    "   syntax match qfFileName /^[^|]*/ transparent conceal
    let cmd = "lopen"
  elseif a:target ==# "help"
    if a:0 > 0
      let cmd = "help " . a:1
    else
      let cmd = "help"
    endif
  endif

  let pos = <SID>GetViewPos(a:target)
  let size = <SID>GetViewSize(a:target)
  let modifier = ide#util#GetVimOpenModifiers(pos)
  if pos ==# "top" || pos ==# "bottom"
    exec modifier . " " . cmd . " | " . size
  else
    exec modifier . " " . cmd
  endif

  if a:target ==# "quickfix" || a:target ==# "location"
    setlocal cursorline
    setlocal statusline=""
  endif
endfunction " }}}


" Closes VIM special view (quickfix, location, help).
"
" Args:
"   target: 'quickfix', 'location', 'help'
function! ide#view#CloseVimSpecialView(target) abort " {{{
  if a:target ==# "quickfix"
    cclose
  elseif a:target ==# "location"
    lclose
  elseif a:target ==# "help"
    let buf_num = <SID>FindViewNum(a:target)
    let buf_win_num = bufwinnr(buf_num)
    if buf_win_num != -1
      exec buf_win_num . " wincmd w"
      exec "bd " . buf_num
    endif
  else
    return
  endif
endfunction " }}}


" Opens diff view.
"
" Args:
"   a:1: Optional file to open in diff view (default is to diff unsaved).
function! ide#view#OpenDiffView(...) abort " {{{
  " If diff with self return
  if a:0 > 0 && fnamemodify(a:1, ":p") ==# expand("%:p")
    return ide#util#EchoError("Cannot diff with self")
  endif

  let pos = <SID>GetViewPos('diff')
  let size = <SID>GetViewSize('diff')
  let modifier = ide#util#GetVimOpenModifiers(pos)

  let s:pre_diff_state = {
    \ 'number': &number, 'foldenable': &foldenable, 'foldlevel': &foldlevel,
    \ 'syntax': exists("g:syntax_on"), 'background': g:background,
    \ 'colorscheme': g:colors_name }
  let s:processing_open_view = 1
  syntax off

  " If cur buffer is closed close the diff as well
  augroup ide_diff_view_augroup1
    autocmd!
    autocmd BufWinLeave <buffer>
      \ :if ! s:processing_open_view |
      \   call ide#view#CloseDiffView() |
      \ endif |
  augroup END

  let w:ide_diff_view = 1

  if a:0 == 0

    " Diffing unsaved
    let file_type = &filetype
    diffthis
    setlocal nofoldenable
    setlocal number

    if pos ==# "top" || pos ==# "bottom"
      exec modifier . ' new | r # | ' . size
    else
      exec modifier . ' new | r #'
    endif

    silent 1,1delete _
    exec "setlocal filetype =" . file_type
    setlocal readonly
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal nobuflisted
    setlocal noswapfile
    diffthis

    " Like OpenSplitView, we have no way of knowing if diff closed so we will
    " use a w:ide_diff_view=1 flag for differ and w:ide_diff_view=2 for diffee.
    let w:ide_diff_view = 2

  else

    let cur_win = winnr()

    " Diffing file
    if pos ==# "top" || pos ==# "bottom"
      exec modifier . ' diffsplit ' . a:1 . ' | ' . size
    else
      exec modifier . ' diffsplit ' . a:1
    endif

    " Like OpenSplitView, we have no way of knowing if diff closed so we will
    " use a w:ide_diff_view=1 flag for differ and w:ide_diff_view=2 for diffee.
    for win_num in range(1, winnr("$"))
      let buf_name = bufname(winbufnr(win_num))
      if !empty(buf_name) &&
          \ (buf_name ==# a:1 || fnamemodify(buf_name, ":p") ==# a:1)
        exec win_num . " winc w"
        setlocal nofoldenable
        setlocal number
        let w:ide_diff_view = 2
        break
      endif
    endfor

    exec cur_win . " winc w"
    setlocal nofoldenable
    setlocal number
    exec win_num . " winc w"

  endif

  " Vim position modifiers don't work for horizontal if diffopt set to
  " vertical, so just move the window
  call ide#view#PositionViewWindow("diff")

  augroup ide_diff_view_augroup2
    autocmd!
    exec "autocmd WinEnter * call ide#view#CheckDiffViewWindow()"
  augroup END

  let s:processing_open_view = 0

  call ide#view#WindowOpenedCb(g:DIFF_VIEW_ID)
endfunction " }}}


" Closes diff view.
function! ide#view#CloseDiffView() abort " {{{
  for win_num in range(1, winnr("$"))
    if getwinvar(win_num, "ide_diff_view") == 2
      autocmd! ide_diff_view_augroup1
      augroup! ide_diff_view_augroup1
      autocmd! ide_diff_view_augroup2
      augroup! ide_diff_view_augroup2
      let s:last_diff_file_name = ide#view#GetDiffViewFilename()
      call ide#view#WindowClosedCb(g:DIFF_VIEW_ID)
      if winnr() != win_num
        exec win_num . " wincmd w"
      endif
      call ide#util#InvokeLater('exec ":q"')
      return
    endif
  endfor
endfunction " }}}


" Gets name of current file opened in diff view
function! ide#view#GetDiffViewFilename() abort " {{{
  for win_num in range(1, winnr("$"))
    if getwinvar(win_num, "ide_diff_view") == 2
      let buf_name = bufname(winbufnr(win_num))
      if !empty(buf_name)
        return fnamemodify(buf_name, ":p")
      else
        return ""
      endif
    endif
  endfor
endfunction " }}}


" Ugly hack to check if diff view window was closed
function! ide#view#CheckDiffViewWindow() abort " {{{
  if s:diff_view_open == 1
    let found = 0
    for win_num in range(1, winnr("$"))
      if getwinvar(win_num, "ide_diff_view") == 1 ||
          \ getwinvar(win_num, "ide_diff_view") == 2
        let found += 1
      endif
    endfor
    if found == 1
      for win_num in range(1, winnr("$"))
        if getwinvar(win_num, "ide_diff_view") == 1 ||
            \ getwinvar(win_num, "ide_diff_view") == 2
          call setwinvar(win_num, "ide_diff_view", 0)
        endif
      endfor
      call ide#view#WindowClosedCb(g:DIFF_VIEW_ID)
    endif
  endif
endfunction " }}}


" Opens split view.
"
" Args:
"   a:1: Optional file to open in split view.
function! ide#view#OpenSplitView(...) abort " {{{
  if a:0 > 0
    " Close any other windows showing this file (so we can track window
    " closing based on buffer)
    for win_num in ide#util#GetOpenWindows(bufnr(a:1))
      exec win_num . " wincmd w"
      exec "q"
    endfor
  endif

  let pos = <SID>GetViewPos('split')
  let size = <SID>GetViewSize('split')
  let modifier = ide#util#GetVimOpenModifiers(pos)
  if pos ==# "top" || pos ==# "bottom"
    exec modifier . ' split "[Split]" | ' . size
  else
    exec modifier . ' split "[Split]"'
  endif

  if a:0 > 0
    exec "edit " . a:1
  else
    exec "enew"
  endif

  call ide#view#WindowOpenedCb(g:SPLIT_VIEW_ID)

  " VIM sucks. It does not have events for when a window is created or closed
  " it only has events for buffers. The window numbers also change whenever
  " new windows are opened, old are closed, or the focus changes. The window
  " numbers are just a stacking order for tabbing. There is also no way to
  " determine a windows relative position. To try to track the window, we will
  " tag the window with a window specific variable w:ide_split_view=1. We will
  " then check this flag during view events and if we can't find any windows
  " with this tag we will indicate that the split view was closed.
  let w:ide_split_view = 1
  augroup ide_split_view_augroup
    autocmd!
    exec "autocmd WinEnter * call ide#view#CheckSplitViewWindow()"
  augroup END

endfunction " }}}


" Closes split view.
function! ide#view#CloseSplitView() abort " {{{
  for win_num in range(1, winnr("$"))
    if getwinvar(win_num, "ide_split_view") == 1
      let s:last_split_file_name = ide#view#GetSplitViewFilename()
      exec win_num . " wincmd w"
      silent! exec "q"
      autocmd! ide_split_view_augroup
      augroup! ide_split_view_augroup
      call ide#view#WindowClosedCb(g:SPLIT_VIEW_ID)
      return
    endif
  endfor
endfunction " }}}


" Gets name of current file opened in split view
function! ide#view#GetSplitViewFilename() abort " {{{
  for win_num in range(1, winnr("$"))
    if getwinvar(win_num, "ide_split_view") == 1
      let buf_name = bufname(winbufnr(win_num))
      if !empty(buf_name)
        return fnamemodify(buf_name, ":p")
      else
        return ""
      endif
    endif
  endfor
endfunction " }}}


" Ugly hack to check if split view window was closed
function! ide#view#CheckSplitViewWindow() abort " {{{
  if s:split_view_open == 1
    let found = 0
    for win_num in range(1, winnr("$"))
      if getwinvar(win_num, "ide_split_view") == 1
        let found = 1
        break
      endif
    endfor
    if found == 0
      call ide#view#WindowClosedCb(g:SPLIT_VIEW_ID)
    endif
  endif
endfunction " }}}


" Opens mirror view.
function! ide#view#OpenMirrorView() abort " {{{
  if bufname('') == ''
    return ide#util#EchoError("Mirroring only supported for named buffers")
  endif

  let buf_num = bufnr("%")
  let buf_name = bufname(buf_num)

  let pos = <SID>GetViewPos('mirror')
  let size = <SID>GetViewSize('mirror')
  let modifier = ide#util#GetVimOpenModifiers(pos)
  if pos ==# "top" || pos ==# "bottom"
    exec modifier . ' split "[Mirror]" | ' . size
  else
    exec modifier . ' split "[Mirror]"'
  endif

  let s:last_mirror_buf_name = buf_name

  " VIM doesn't send close events if a buffer is open in another window. This
  " checks for a window enter event associated with this buffer, if it is the
  " only remaining window and last_mirror_buf_name isn't cleared, then we fire
  " the missing close event
  augroup ide_mirror_view_augroup
    autocmd!
    silent! exec "autocmd WinEnter <buffer> |"
       \ "if len(ide#util#GetOpenWindows(" . buf_num . ")) == 1 && "
       \     "!empty(s:last_mirror_buf_name) && s:mirror_view_open == 1 |"
       \   "call ide#view#WindowClosedCb(" . buf_num . ") |"
       \ "endif"
  augroup END

  call ide#view#WindowOpenedCb(buf_num)
endfunction " }}}


" Closes mirror view.
function! ide#view#CloseMirrorView() abort " {{{
  if !empty(s:last_mirror_buf_name)
    let buf_num = bufnr(s:last_mirror_buf_name)
    let buf_win_num = bufwinnr(buf_num)
    if buf_win_num != -1
      exec buf_win_num . " wincmd w"
      silent! exec "q"
    endif
  endif
endfunction " }}}


" Generic window open handling for a view.
"
" This method is meant to be used by specialized view handling code (e.g. git
" view, etc) in order to process the open for the window itself. This function
" only opens the window, any other view related processing is up to the caller.
"
" Args:
"   view_name: Name of view window will be associated with (e.g. 'git', etc).
"   buf_name: Name of buffer to associated with the view (may be changed by cmd).
"   cmd: Command to execute after window opened (e.g. 'GEdit <rev>', etc)
"   a:1: Function called when action (e/E, s, etc) used on a chosen
"     line in buffer. It is passed the action used ('e', 'E', 't', etc), the
"     line and the full name of the previous file in the buffer as args.
"   a:2: Default action on enter.
function! ide#view#OpenViewWindow(view, buf_name, cmd, ...) abort " {{{
  let buf_num = <SID>FindViewNum(a:view)
  let buf_win_num = bufwinnr(buf_num)
  if buf_win_num != -1
    " Window already open, select it
    exec buf_win_num . " wincmd w"
  else
    let pos = <SID>GetViewPos(a:view)
    let size = <SID>GetViewSize(a:view)
    let modifier = ide#util#GetVimOpenModifiers(pos)
    if pos ==# "top" || pos ==# "bottom"
      exec modifier . ' split "' . a:buf_name . '" | ' . size
    else
      exec modifier . ' split "' . a:buf_name . '"'
    endif
  endif

  exec a:cmd

  if a:0 > 0
    let w:action_cb = a:1

    let w:default_action = "e"
    if a:0 > 1
      let w:default_action = a:2
    endif

    " map enter to default action
    nnoremap <silent> <buffer> <cr> :call feedkeys(w:default_action)<CR>

    " map t to open tab
    nnoremap <silent> <buffer> t
      \ :call <SID>InvokeActionOnViewWindow('t', w:action_cb)<CR>

    " map s to open split view
    nnoremap <silent> <buffer> s
      \ :call <SID>InvokeActionOnViewWindow('s', w:action_cb)<CR>

    " map e to edit in current window
    nnoremap <silent> <buffer> e
      \ :call <SID>InvokeActionOnViewWindow('e', w:action_cb)<CR>

    " map E to edit in current window
    nnoremap <silent> <buffer> E
      \ :call <SID>InvokeActionOnViewWindow('E', w:action_cb)<CR>

    " map d to open diff
    nnoremap <silent> <buffer> d
      \ :call <SID>InvokeActionOnViewWindow('d', w:action_cb)<CR>

    " map D to edit in current window
    nnoremap <silent> <buffer> D
      \ :call <SID>InvokeActionOnViewWindow('D', w:action_cb)<CR>

    " map ctrl-] to go forward
    nnoremap <silent> <buffer> <c-]>
      \ :call <SID>InvokeActionOnViewWindow('e', w:action_cb)<CR>

    " map ctrl-t to go back
    nnoremap <silent> <buffer> <c-t>
      \ :call <SID>InvokeActionOnViewWindow("c-t", w:action_cb)<CR>

    if g:ide_mike_mode
      " map gj to ctrl-]
      nnoremap <silent> <buffer> gj :call feedkeys("\<c-]>")<CR>

      " map gk ctrl-t to go back
      nnoremap <silent> <buffer> gk :call feedkeys("\<c-t>")<CR>
    endif
  endif
endfunction " }}}


" Invokes action on currently selected item in view window.
"
" Args:
"   action: Action ('e', 'E', 't', 's', 'd', 'D').
"   action_cb: Action callback.
function! s:InvokeActionOnViewWindow(action, action_cb) abort " {{{
  let line = getline('.')
  let buf_name = bufname('')
  let full_name = expand("%:p")
  exec winnr("#") . " winc w"
  call ide#util#CloseWindow(buf_name)
  call call(a:action_cb, [a:action, line, full_name])
endfunction " }}}


" Generic window close handling for a view.
"
" This method is meant to be used by specialized view handling code (e.g. git
" view, etc) in order to process the close for the window itself. This function
" only closes the window, any other view related processing is up to the caller.
"
" Args:
"   view_name: Name of view window will be associated with (e.g. 'git', etc).
function! ide#view#CloseViewWindow(view) abort " {{{
  let buf_num = <SID>FindViewNum(a:view)
  let buf_win_num = bufwinnr(buf_num)
  if buf_win_num != -1
    exec buf_win_num . " wincmd w"
    exec "bd " . buf_num
  endif
endfunction " }}}


" Generic window positioning for a view.
"
" This method is meant to be used by specialized view handling code (e.g. git
" view, etc) in order to re-position a view that may have been opened in the
" wrong position. This function only positions the window, any other view
" related processing is up to the caller.
"
" Args:
"   view_name: Name of view current window is associated with (e.g. 'git', etc).
function! ide#view#PositionViewWindow(view) abort " {{{
  let pos = <SID>GetViewPos(a:view)
  if pos ==# 'left'
    call feedkeys("\<C-W>H")
  elseif pos ==# 'right'
    call feedkeys("\<C-w>L")
  elseif pos ==# 'top'
    call feedkeys("\<C-w>K")
  elseif pos ==# 'bottom'
    call feedkeys("\<C-w>J")
  endif
endfunction " }}}


" Selects next external view
function! ide#view#NextExternalView() abort " {{{
  let s:cur_external_id -= 1
  if s:cur_external_id < g:MIN_EXTERNAL_WIN
    let s:cur_external_id = g:MAX_EXTERNAL_WIN
  endif

  if s:cur_external_id == g:EXTERNAL_GVIM_ID
    " Open any previous internal gvim window
    let pos = <SID>GetViewPos("terminal")
    let reopen_stack = <SID>GetReopenStack(pos)
    for i in range(0, len(reopen_stack) - 1)
      if i % 2 == 0 && reopen_stack[i] !=? "terminal" &&
          \ reopen_stack[i] !=? "browser"
        return ide#view#OpenView(reopen_stack[i])
      endif
    endfor
    call ide#view#NextExternalView()
  elseif s:cur_external_id == g:EXTERNAL_BROWSER_ID
    call ide#view#OpenView("browser")
  elseif s:cur_external_id == g:EXTERNAL_TERMINAL_ID
    call ide#view#OpenView("terminal")
  endif
endfunction " }}}


" Selects prev external view
function! ide#view#PrevExternalView() abort " {{{
  let s:cur_external_id += 1
  if s:cur_external_id > g:MAX_EXTERNAL_WIN
    let s:cur_external_id = g:MIN_EXTERNAL_WIN
  endif

  if s:cur_external_id == g:EXTERNAL_GVIM_ID
    " Open any previous internal gvim window
    let pos = <SID>GetViewPos("terminal")
    let reopen_stack = <SID>GetReopenStack(pos)
    for i in range(0, len(reopen_stack) - 1)
      if i % 2 == 0 && reopen_stack[i] !=? "terminal" &&
          \ reopen_stack[i] !=? "browser"
        return ide#view#OpenView(reopen_stack[i])
      endif
    endfor
    call ide#view#NextExternalView()
  elseif s:cur_external_id == g:EXTERNAL_BROWSER_ID
    call ide#view#OpenView("browser")
  elseif s:cur_external_id == g:EXTERNAL_TERMINAL_ID
    call ide#view#OpenView("terminal")
  endif
endfunction " }}}


" Selects next external view
function! ide#view#GetCurExternalView() abort " {{{
  return s:cur_external_id
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" View Callbacks
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Callback handler for when a window is opened.
"
" Although this is called for any window that is opened, it's intented for use
" with handling 'view' based windows.
"
" NOTE: quickfix/help windows call Open twice, once with 'No Name' as the
"   buffer name and a second time with 'quickfix'
"
" Args:
"   buf_num: Number of buffer opened (1 based). The value -2 is reserved for
"     external terminal windows and the value -3 for external browser windows.
function! ide#view#WindowOpenedCb(buf_num) abort " {{{
  if s:processing_open_view
    return
  endif

  let s:processing_window_opened = 1

  let s:cur_external_id = g:EXTERNAL_GVIM_ID
  if a:buf_num == g:EXTERNAL_TERMINAL_ID
    let view_name = "terminal"
    let s:external_terminal = 1
    let s:cur_external_id = g:EXTERNAL_TERMINAL_ID
  elseif a:buf_num == g:EXTERNAL_BROWSER_ID
    let view_name = "browser"
    let s:external_browser = 1
    let s:cur_external_id = g:EXTERNAL_BROWSER_ID
  elseif a:buf_num == g:SPLIT_VIEW_ID
    let view_name = "split"
  elseif a:buf_num == g:DIFF_VIEW_ID
    let view_name = "diff"
  else
    call ide#view#CheckSplitViewWindow()

    " Check if have buf name for cur buffer (half opened buffers)
    let bufs = ide#util#GetBufferNamesByNum()
    if !has_key(bufs, a:buf_num)
      let s:processing_window_opened = 0
      return ide#util#EchoError(
          \ "no buf!!!!!: " . a:buf_num . " " . string(bufs))
    endif

    " Get view name for buffer
    let view_name = <SID>MatchViewName(bufs[a:buf_num], a:buf_num)
  endif

  if !empty(view_name)
    call <SID>SetViewOpen(view_name, 1)
    call <SID>AddView(view_name, a:buf_num)
  endif


  if a:buf_num > 1
    let s:last_win_opened = bufs[a:buf_num]
  else
    let s:last_win_opened = a:buf_num
  endif

  if a:buf_num == g:DIFF_VIEW_ID
    setlocal nofoldenable
    setlocal number
    exec "colorscheme " . g:colors_name
  endif

  let s:processing_window_opened = 0
endfunction " }}}


" Callback handler for when a window closed.
"
" Although this is called for any window that is closed, it's intented for use
" with handling 'view' based windows.
"
" Args:
"   buf_num: Number of buffer closed.
function! ide#view#WindowClosedCb(buf_num) abort " {{{
  " Try to find view matching current buffer (some events use cur...)
  let view_name = <SID>FindViewName(a:buf_num)

  if a:buf_num > 0
    call ide#view#CheckSplitViewWindow()
  endif

  if !empty(view_name)
    call <SID>SetViewOpen(view_name, 0)
    call <SID>RemoveView(a:buf_num)
  endif

  if a:buf_num == g:DIFF_VIEW_ID
    exec ":diffoff!"
    if s:pre_diff_state['foldenable']
      setlocal foldenable
    else
      setlocal nofoldenable
    endif
    if s:pre_diff_state['syntax']
      syntax enable
    else
      syntax off
    endif
    exec "setlocal foldlevel=" . s:pre_diff_state['foldlevel']
    if s:pre_diff_state['number']
      setlocal number
    else
      setlocal nonumber
    endif
    exec "set background=" . s:pre_diff_state['background']
    exec "colorscheme " . s:pre_diff_state['colorscheme']
  endif
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Internal helper functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Adds a new view to stack of open views.
"
" Args:
"   view_name: View name.
"   buf_num: View buffer number.
function! s:AddView(view_name, buf_num) abort " {{{
  let pos = <SID>GetViewPos(a:view_name)
  let view_stack = <SID>GetViewStack(pos)
  " Already added...
  if index(view_stack, a:view_name) != -1
    return
  endif

  " If opened from a non-view store information about how to reset window later
  if s:return_to_win_num == 0 && empty(<SID>FindViewName(winnr("#")))
    " Would like to move win pos to adjust left popouts, but col units in chars
    " and win units in pixels, so no way to determine size...so just restore pos
    let s:return_to_win_num = winnr("#")
    let s:return_to_win_x = getwinposx()
    let s:return_to_win_y = getwinposy()
  endif

  " Close any previous buffers open in this position
  if len(view_stack) > 0
    let reopen_stack = <SID>GetReopenStack(pos)
    let prev_view_name = view_stack[-2]
    let prev_buf_num = view_stack[-1]
    call add(reopen_stack, prev_view_name)
    call add(reopen_stack, string(a:buf_num + 0))
    call ide#view#CloseView(prev_view_name)
    if prev_view_name !=# "split" && prev_view_name !=# "diff"
      call ide#view#WindowClosedCb(prev_buf_num)  " Not auto fired, manual
    endif
  endif

  call add(view_stack, a:view_name)
  call add(view_stack, string(a:buf_num + 0))
  if pos ==# "left"
    call <SID>LeftSidebarOpened(a:view_name, a:buf_num)
  elseif pos ==# "right"
    call <SID>RightSidebarOpened(a:view_name, a:buf_num)
  endif
endfunction " }}}


" Removes a view from the stack of open views.
"
" Args:
"   buf_num: View buffer number.
function! s:RemoveView(buf_num) abort " {{{
  let view_name = <SID>FindViewName(a:buf_num)
  if empty(view_name)
    return
  endif

  if view_name ==# "mirror"
    let s:last_mirror_buf_name = ""
  endif

  let pos = <SID>GetViewPos(view_name)
  let view_stack = <SID>GetViewStack(pos)
  let offset = index(view_stack, view_name)

  if offset != -1
    call remove(view_stack, string(offset + 1))
    call remove(view_stack, string(offset + 0))
  endif

  if pos ==# "left"
    call <SID>LeftSidebarClosed(view_name, a:buf_num)
  elseif pos ==# "right"
    call <SID>RightSidebarClosed(view_name, a:buf_num)
  endif

  if s:return_to_win_num != 0
    exec "winpos " . s:return_to_win_x . " " . s:return_to_win_y
    exec s:return_to_win_num . " wincmd w"
    let s:return_to_win_num = 0
  endif

  " Reopen any previous buffers closed in this position
  let reopen_stack = <SID>GetReopenStack(pos)
  if len(reopen_stack) > 0 && !s:processing_window_opened
    let offset = index(reopen_stack, string(a:buf_num + 0))  " Find by closer
    if offset != -1
      let prev_view_name = reopen_stack[offset - 1]
      call remove(reopen_stack, string(offset + 0))
      call remove(reopen_stack, string(offset - 1))
      let cmd = 'call ide#view#ReopenView("' . prev_view_name . '")'
      call ide#util#InvokeLater(cmd)
    endif
  endif
endfunction " }}}


" Reopens a view.
"
" This function primarily exists so we can package both OpenView and the
" firing of the event into one InvokeLater call.
"
" Args:
"   prev_view_name: Previous view name.
function! ide#view#ReopenView(prev_view_name) abort " {{{
  " Open previous view
  if a:prev_view_name ==# "help" && !empty(s:last_help_subject)
    call ide#view#OpenView(a:prev_view_name, s:last_help_subject)
  elseif a:prev_view_name ==# "browser" && !empty(s:last_browser_url)
    call ide#view#OpenView(a:prev_view_name, s:last_browser_url)
  elseif a:prev_view_name ==# "git" && len(s:last_git_cmd) > 0
    call call("ide#view#OpenView", [a:prev_view_name] + s:last_git_cmd)
  elseif a:prev_view_name ==# "split" && !empty(s:last_split_file_name)
    call ide#view#OpenView(a:prev_view_name, s:last_split_file_name)
  elseif a:prev_view_name ==# "diff" && !empty(s:last_diff_file_name)
    call ide#view#OpenView(a:prev_view_name, s:last_diff_file_name)
  else
    call ide#view#OpenView(a:prev_view_name)
  endif

  " Find if buf already opened and fire re-open event on that buffer
  let prev_buf_num = <SID>FindViewNum(a:prev_view_name)
  if prev_buf_num > 0
    " Not auto fired, manual req
    call ide#view#WindowOpenedCb(prev_buf_num)
  endif
endfunction " }}}


" Find view name associated with buffer number.
"
" Args:
"   buf_num: View buffer number.
"   a:1 : Optional position to search in.
"
" Returns:
"   View name or "".
function! s:FindViewName(buf_num, ...) abort " {{{
  if a:buf_num == g:EXTERNAL_TERMINAL_ID
    return "terminal"
  elseif a:buf_num == g:EXTERNAL_BROWSER_ID
    return "browser"
  elseif a:buf_num == g:SPLIT_VIEW_ID
    return "split"
  elseif a:buf_num == g:DIFF_VIEW_ID
    return "diff"
  elseif a:0 == 1
    if !empty(s:last_mirror_buf_name) &&
        \ bufnr(s:last_mirror_buf_name) == a:buf_num
      return "mirror"
    else
      let view_stack = <SID>GetViewStack(a:1)

      let i = 0
      while i < len(view_stack)
        if i % 2 == 1 && view_stack[i] ==# a:buf_num
          return view_stack[i - 1]
        endif
        let i += 1
      endwhile

      return ""
    endif
  else
    let view_name = <SID>FindViewName(a:buf_num, "right")  " Try right
    if !empty(view_name)
      return view_name
    endif
    let view_name = <SID>FindViewName(a:buf_num, "bottom")  " Try bottom
    if !empty(view_name)
      return view_name
    endif
    let view_name = <SID>FindViewName(a:buf_num, "left")  " Try left
    if !empty(view_name)
      return view_name
    endif
    return <SID>FindViewName(a:buf_num, "top")  " Try top
  endif
endfunction " }}}


" Find buffer number associated with a view name.
"
" Args:
"   view_name: View name.
"
" Returns:
"   Buffer number or -1.
function! s:FindViewNum(view_name) abort " {{{
  if a:view_name ==# "terminal" && s:external_terminal
    return g:EXTERNAL_TERMINAL_ID
  endif

  if a:view_name ==# "browser" && s:external_browser
    return g:EXTERNAL_BROWSER_ID
  endif

  if a:view_name ==# "split"
    return g:SPLIT_VIEW_ID
  endif

  if a:view_name ==# "diff"
    return g:DIFF_VIEW_ID
  endif

  " Try to find a view with a window
  for item in items(ide#util#GetBufferNamesByNum())
    " Dict keys are converted to strings, +0 to convert back to int
    if <SID>MatchViewName(item[1], item[0] + 0) ==# a:view_name &&
        \ bufwinnr(item[0] + 0) != -1
      return item[0] + 0
    endif
  endfor

  " Try to find any buffer matching view
  for item in items(ide#util#GetBufferNamesByNum())
    " Dict keys are converted to strings, +0 to convert back to int
    if <SID>MatchViewName(item[1], item[0] + 0) ==# a:view_name
      return item[0] + 0
    endif
  endfor

  if a:view_name ==# "mirror" && !empty(s:last_mirror_buf_name)
    return bufnr(s:last_mirror_buf_name)
  endif

  return -1
endfunction " }}}


" Gets view stack based on position.
"
" Args:
"   pos: view position.
"
" Returns:
"   s:xxx_view_stack.
function! s:GetViewStack(pos) abort " {{{
  exec "let view_stack = s:" . a:pos . "_view_stack"
  return view_stack
endfunction " }}}


" Gets reopen stack based on position.
"
" Args:
"   pos: view position.
"
" Returns:
"   s:xxx_reopen_stack.
function! s:GetReopenStack(pos) abort " {{{
  exec "let reopen_stack = s:" . a:pos . "_reopen_stack"
  return reopen_stack
endfunction " }}}


" Gets view position based on name.
"
" Args:
"   view_name: View name.
"
" Returns:
"   'left', 'right', 'top', or 'bottom'.
function! s:GetViewPos(view_name) abort " {{{
  if eval('exists("g:ide_' . a:view_name . '_view_pos")')
    exec "let pos = g:ide_" . a:view_name . "_view_pos"
    if pos ==# "left" || pos ==# "right" || pos ==# "bottom" || pos ==# "top"
      return pos
    else
      return eval(pos)
    endif
  else
    return ""
  endif
endfunction " }}}


" Gets view size based on name.
"
" Args:
"   view_name: View name.
"
" Returns:
"   width (if left/right positioned view) or height (if top/bottom).
function! s:GetViewSize(view_name) abort " {{{
  if eval('exists("g:ide_' . a:view_name . '_view_size")')
    exec "let size = g:ide_" . a:view_name . "_view_size"
    return eval(size)
  else
    return 0
  endif
endfunction " }}}


" Gets view buffer pattern.
"
" Args:
"   view_name: View name.
"
" Returns:
"   String buffer pattern or "".
function! s:GetViewBufferPattern(view_name) abort " {{{
  if eval('exists("g:ide_' . a:view_name . '_buf_pat")')
    exec "let pat = g:ide_" . a:view_name . "_buf_pat"
    return pat
  else
    return ""
  endif
endfunction " }}}


" Sets view open flag.
"
" Args:
"   view_name: View name.
"   value: 0 or 1.
function! s:SetViewOpen(view_name, value) abort " {{{
  exec "let s:" . a:view_name . "_view_open = " . a:value
endfunction " }}}


" Returns the number of open views.
"
" Args:
"   a:1 : 'left, 'right', 'top', 'bottom'  (optional position, no arg = all).
"
" Returns:
"   Number of open views for passed in position (or all if no args passed).
function! s:NumOpenViews(...) abort " {{{
  if a:0 == 1
    if a:1 ==# "top"
      return len(s:top_view_stack) / 2
    elseif a:1 ==# "bottom"
      return len(s:bottom_view_stack) / 2
    elseif a:1 ==# "left"
      return len(s:left_view_stack) / 2
    elseif a:1 ==# "right"
      return len(s:right_view_stack) / 2
    else
      return 0
    endif
  else
    let view_count = len(s:top_view_stack) / 2
    let view_count += len(s:bottom_view_stack) / 2
    let view_count += len(s:left_view_stack) / 2
    let view_count += len(s:right_view_stack) / 2
    return view_count
  endif
endfunction " }}}


" Matches view based on buffer name/number.
"
" Args:
"   buf_name: Buffer name.
"   buf_num: Buffer number.
"
" Returns:
"   View name.
function! s:MatchViewName(buf_name, buf_num) abort " {{{
  if a:buf_num == g:EXTERNAL_TERMINAL_ID
    return "terminal"
  elseif a:buf_num == g:EXTERNAL_BROWSER_ID
    return "browser"
  elseif a:buf_num == g:SPLIT_VIEW_ID
    return "split"
  elseif a:buf_num == g:DIFF_VIEW_ID
    return "diff"
  elseif a:buf_name =~ "^buffers$"
    return "buffers"
  elseif a:buf_name =~ "^location$"
    return "location"
  elseif a:buf_name =~ "^quickfix$"
    return "quickfix"
  elseif !empty(s:last_mirror_buf_name) && a:buf_name ==? s:last_mirror_buf_name
    return "mirror"
  elseif exists("g:ide_projects_buf_pat") &&
      \ ide#util#EvalPatternMatch(a:buf_name, g:ide_projects_buf_pat)
    return "projects"
  elseif exists("g:ide_explorer_buf_pat") &&
      \ ide#util#EvalPatternMatch(a:buf_name, g:ide_explorer_buf_pat)
    return "explorer"
  elseif exists("g:ide_outline_buf_pat") &&
      \ ide#util#EvalPatternMatch(a:buf_name, g:ide_outline_buf_pat)
    return "outline"
  elseif exists("g:ide_terminal_buf_pat") &&
      \ ide#util#EvalPatternMatch(a:buf_name, g:ide_terminal_buf_pat)
    return "terminal"
  elseif exists("g:ide_git_buf_pat") &&
      \ ide#util#EvalPatternMatch(a:buf_name, g:ide_git_buf_pat)
    return "git"
  elseif exists("g:ide_list_buf_pat") &&
      \ ide#util#EvalPatternMatch(a:buf_name, g:ide_list_buf_pat)
    return "list"
  elseif getbufvar(a:buf_num, "&buftype") ==# "help" ||
      \ (s:last_win_opened =~ "No Name" && a:buf_name =~ "\.txt")
    " Help is a bit weird, two events are fired, one with 'No Name'
    " and another with the help file name. Neither have the buftype set yet
    return "help"
  elseif a:buf_name =~ "Quickfix List"
    return "quickfix"
  elseif a:buf_name =~ "Location List"
    return "location"
  else
    return ""
  endif
endfunction " }}}


" Increases width of window based on view used.
"
" Args:
"   view_name: Name of view that caused left sidebar to be opened.
"   buf_num: View buffer number.
function! s:IncreaseWindowWidth(view_name, buf_num) abort " {{{
  if a:buf_num == g:EXTERNAL_TERMINAL_ID || a:buf_num == g:EXTERNAL_BROWSER_ID
    return
  endif

  let size = <SID>GetViewSize(a:view_name)
  let width = &columns + size + 1  " +1 for splitter
  " Hack to fix wierd errors with creeping width
  if width < s:min_center_width + 10
    let width = s:min_center_width + 2
  endif
  let &columns = width
  let cmd = ': call ide#view#SetViewWidth("' . a:view_name . '",' . size . ")"

  " TODO: Revisit this code. It was behaving badly, but YouCompleteMe increased
  "   the idle wait time so this issue doesn't show up anyore
  "if ide#view#IsVimSpecialView(a:view_name)
    " Vim windows behave strangely, invoke later to ensure things go smoothly
    "call ide#util#InvokeLater(cmd)
  "else
    exec cmd
  "endif
endfunction " }}}


" Decreases width of window based on view used.
"
" Args:
"   view_name: Name of view that caused left sidebar to be opened.
"   buf_num: View buffer number.
function! s:DecreaseWindowWidth(view_name, buf_num) abort " {{{
  if a:buf_num == g:EXTERNAL_TERMINAL_ID || a:buf_num == g:EXTERNAL_BROWSER_ID
    return
  endif

  let size = <SID>GetViewSize(a:view_name)
  let width = &columns - size + 1
  if width < s:min_center_width
    let width = s:min_center_width
  " Hack to fix wierd errors with creeping width
  elseif width < s:min_center_width + 10
    let width = s:min_center_width + 2
  endif
  let &columns = width
endfunction " }}}


" Callback for left sidebar opened (adjusts win width, etc).
"
" Args:
"   view_name: Name of view that caused left sidebar to be opened.
"   buf_num: View buffer number.
function! s:LeftSidebarOpened(view_name, buf_num) abort " {{{
  call <SID>IncreaseWindowWidth(a:view_name, a:buf_num)
endfunction " }}}


" Callback for left sidebar closed (adjusts win width, etc).
"
" Args:
"   view_name: Name of view that caused left sidebar to be closed.
"   buf_num: View buffer number.
function! s:LeftSidebarClosed(view_name, buf_num) abort " {{{
  call <SID>DecreaseWindowWidth(a:view_name, a:buf_num)
endfunction " }}}


" Callback for right sidebar opened (adjusts win width, etc).
"
" Args:
"   view_name: Name of view that caused right sidebar to be opened.
"   buf_num: View buffer number.
function! s:RightSidebarOpened(view_name, buf_num) abort " {{{
  call <SID>IncreaseWindowWidth(a:view_name, a:buf_num)
endfunction " }}}


" Callback for right sidebar closed (adjusts win width, etc).
"
" Args:
"   view_name: Name of view that caused right sidebar to be closed.
"   buf_num: View buffer number.
function! s:RightSidebarClosed(view_name, buf_num) abort " {{{
  call <SID>DecreaseWindowWidth(a:view_name, a:buf_num)
endfunction " }}}
