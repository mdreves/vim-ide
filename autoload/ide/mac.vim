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

let s:external_terminal_id = 0  " Id of external terminal
let s:external_browser_id = 0  " Id of external browser
let s:cur_external_win_id = 0  " Id of current external window


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" MacVim Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! ide#mac#ActivateMacVim() abort " {{{
  if ide#util#Os() ==# "mac"
    call system("osascript" .
      \ " -e " . "'tell app " . '"' . "MacVim" . '"' . "'" .
      \ " -e " . "'activate'" .
      \ " -e " . "'end tell'")
  endif
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ITerm Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Expands ITerm window.
function! ide#mac#ExpandItermWin() abort " {{{
  if ide#util#Os() ==# "mac"
   echom "osascript" .
      \ " -e " . "'tell application " . '"'. "System Events" . '"' . "'" .
      \ " -e " . "'to keystroke return using {shift down, command down}'" .
      \ " -e " . "'end tell'"
    call system("osascript" .
      \ " -e " . "'tell application " . '"'. "System Events" . '"' . "'" .
      \ " -e " . "'to keystroke return using {shift down, command down}'" .
      \ " -e " . "'end tell'")
  endif
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Terminal Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Opens terminal.
"
" Args:
"   pos: 'right', 'left', 'top', 'bottom'
"   size: Chars (if pos right/left) or lines (if pos bottom/top)
"   a:1: Optional command to run in terminal
function! ide#mac#OpenTerminal(pos, size, ...) abort " {{{
  if s:external_terminal_id > 0
    call ide#mac#SelectTerminal()
  else
    if a:pos ==# "right" || a:pos ==# "left"
      " Approx chars to pixels seems to be 80 chars = 570 pixels
      let calc_size = (a:size / 80) * 570
    else
      " Approx lines to pixels seems to be 24 lines = 388 pixels (if tabs) or
      " 366 pixels (no tabs)
      let calc_size = (a:size / 24) * 388
    endif

    " Create terminal and save its id
    let pre_cmd = ""
    "if a:0 > 0
    "  let pre_cmd = 'do script ' . '"' . a:1 . '"'
    "else
    "  let pre_cmd = 'do script "cd ' . expand("%:p:h") . '; clear"'
    "endif
    " Bug in osascript where it won't send enter to command, this fixes it
    "let pre_cmd .= "' -e 'do script " . '";"' . " in window 1"

    let post_cmd = "get id of front window"
    let s:external_terminal_id = split(
      \ <SID>PositionAppRelativeToMacVim(
      \   g:ide_mac_terminal, pre_cmd, post_cmd, a:pos, calc_size,
      \   g:ide_mac_terminal_min_bounds, g:ide_mac_terminal_max_bounds
      \ ), '\n')[0]
  endif
  let s:cur_external_win_id = s:external_terminal_id
endfunction " }}}


" Closes terminal.
function! ide#mac#CloseTerminal() abort " {{{
  call <SID>ExecScript(
    \ g:ide_mac_terminal, s:external_terminal_id, 'close window win_id')
  if s:cur_external_win_id == s:external_terminal_id
    let s:cur_external_win_id = s:external_browser_id
  endif
  let s:external_terminal_id = 0
endfunction " }}}


" Detach terminal.
function! ide#mac#DetachTerminal() abort " {{{
  if s:cur_external_win_id == s:external_terminal_id
    let s:cur_external_win_id = s:external_browser_id
  endif
  let s:external_terminal_id = 0
endfunction " }}}


" Checks if terminal attached.
function! ide#mac#IsTerminalAttached() abort " {{{
  return s:external_terminal_id != 0
endfunction " }}}


" Opens terminal tab.
function! ide#mac#OpenTerminalTab() abort " {{{
  let cmd = 'tell application "System Events"' .
    \ ' to keystroke "t" using {command down}'
  call <SID>ExecScript(g:ide_mac_terminal, s:external_terminal_id, cmd)
  let s:cur_external_win_id = s:external_terminal_id
endfunction " }}}


" Closes terminal tab.
function! ide#mac#CloseTerminalTab() abort " {{{
  let cmd = 'tell application "System Events"' .
    \ ' to keystroke "w" using {command down}'
  call <SID>ExecScript(g:ide_mac_terminal, s:external_terminal_id, cmd)
  let s:cur_external_win_id = s:external_terminal_id
endfunction " }}}


" Minimize terminal.
function! ide#mac#MinimizeTerminal() abort " {{{
  call <SID>ExecScript(
    \ g:ide_mac_terminal, s:external_terminal_id,
    \ 'set miniaturized of window win_id to true')
  let s:cur_external_win_id = s:external_terminal_id
endfunction " }}}


" Maximize terminal.
function! ide#mac#MaximizeTerminal() abort " {{{
  call <SID>ExecScript(
    \ g:ide_mac_terminal, s:external_terminal_id,
    \ 'set miniaturized of window win_id to false')
  let s:cur_external_win_id = s:external_terminal_id
endfunction " }}}


" Selects terminal.
function! ide#mac#SelectTerminal() abort " {{{
  call <SID>ActivateExternalWindow(g:ide_mac_terminal, s:external_terminal_id)
  let s:cur_external_win_id = s:external_terminal_id
endfunction " }}}


" Select terminal tab.
"
" Args:
"   offset: Tab offset (1 based).
function! ide#mac#SelectTerminalTab(offset) abort " {{{
  let cmd = "set selected of tab " . a:offset . " of window 1 to true"
  call <SID>ExecScript(g:ide_mac_terminal, s:external_terminal_id, cmd)
  let s:cur_external_win_id = s:external_terminal_id
endfunction " }}}


" Select next terminal tab.
function! ide#mac#SelectNextTerminalTab() abort " {{{
  let cmd = 'tell application "System Events"' .
    \ ' to keystroke "}" using {command down}'
  call <SID>ExecScript(g:ide_mac_terminal, s:external_terminal_id, cmd)
  let s:cur_external_win_id = s:external_terminal_id
endfunction " }}}


" Select prev terminal tab.
function! ide#mac#SelectPrevTerminalTab() abort " {{{
  let cmd = 'tell application "System Events"' .
    \ ' to keystroke "{" using {command down}'
  call <SID>ExecScript(g:ide_mac_terminal, s:external_terminal_id, cmd)
  let s:cur_external_win_id = s:external_terminal_id
endfunction " }}}


" Position terminal relative to MacVim.
"
" Args:
"   pos: 'right', 'left', 'top', 'bottom'
"   a:1: True to force alignment of any term even if no term open
function! ide#mac#PositionTerminalRelativeToMacVim(pos, ...) abort " {{{
  if s:external_terminal_id != 0 || (a:0 > 0 && a:1)
    if s:external_terminal_id != 0
      let bounds = <SID>GetExternalWindowBounds(
        \ g:ide_mac_terminal, s:external_terminal_id)
    else
      let bounds = <SID>GetExternalWindowBounds(g:ide_mac_terminal)
    endif

    if a:pos ==# "right" || a:pos ==# "left"
      let size = bounds[2] - bounds[0]
    else
      let size = bounds[3] - bounds[1]
    endif
    call <SID>PositionAppRelativeToMacVim(
      \ g:ide_mac_terminal, '', '', a:pos, size,
      \ g:ide_mac_terminal_min_bounds, g:ide_mac_terminal_max_bounds)

    " Reset window id
    let s:external_terminal_id = <SID>GetExternalWindowId(g:ide_mac_terminal)
    let s:cur_external_win_id = s:external_terminal_id
  endif
endfunction " }}}


" Runs command in terminal
function! ide#mac#RunTerminalCmd(cmd) abort " {{{
  let term_cmd = 'do script ' . '"' . a:cmd . '" in window 1'
  call <SID>ExecScript(g:ide_mac_terminal, s:external_terminal_id, term_cmd)
  let s:cur_external_win_id = s:external_terminal_id
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Browser Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Opens browser.
"
" Args:
"   pos: 'right', 'left', 'top', 'bottom'
"   a:1 : Size of browser window (in pixels). A value less than or equals to 0
"     will use the remainder of the screen minus that value.
function! ide#mac#OpenBrowser(pos, ...) abort " {{{
  if s:external_browser_id > 0
    call ide#mac#SelectBrowser()
  else
    let size = a:0 > 0 ? a:1 : 0

    " Create browser and save its id
    let pre_cmd = "make new window"
    let post_cmd = "get id of front window"
    let s:external_browser_id = split(<SID>PositionAppRelativeToMacVim(
      \   g:ide_mac_browser, pre_cmd, post_cmd, a:pos, size,
      \   g:ide_mac_browser_min_bounds, g:ide_mac_browser_max_bounds
      \ ), '\n')[0]
  endif
  let s:cur_external_win_id = s:external_browser_id
endfunction " }}}


" Closes browser.
function! ide#mac#CloseBrowser() abort " {{{
  let cmd = 'tell application "System Events"' .
    \ ' to keystroke "w" using {command down, shift down}'
  call <SID>ExecScript(
    \ g:ide_mac_browser, s:external_browser_id, cmd)
  if s:cur_external_win_id == s:external_browser_id
    let s:cur_external_win_id = s:external_terminal_id
  endif
  let s:external_browser_id = 0
endfunction " }}}


" Detaches browser.
function! ide#mac#DetachBrowser() abort " {{{
  if s:cur_external_win_id == s:external_browser_id
    let s:cur_external_win_id = s:external_terminal_id
  endif
  let s:external_browser_id = 0
endfunction " }}}


" Checks if browser attached.
function! ide#mac#IsBrowserAttached() abort " {{{
  return s:external_browser_id != 0
endfunction " }}}


" Opens browser tab.
function! ide#mac#OpenBrowserTab() abort " {{{
  let cmd = 'tell application "System Events"' .
    \ ' to keystroke "t" using {command down}'
  call <SID>ExecScript(g:ide_mac_browser, s:external_browser_id, cmd)
  let s:cur_external_win_id = s:external_browser_id
endfunction " }}}


" Closes browser tab.
function! ide#mac#CloseBrowserTab() abort " {{{
  let cmd = 'tell application "System Events"' .
    \ ' to keystroke "w" using {command down}'
  call <SID>ExecScript(g:ide_mac_browser, s:external_browser_id, cmd)
  let s:cur_external_win_id = s:external_browser_id
endfunction " }}}


" Opens url.
"
" Args:
"   url: URL to open
"   a:1: Number of tab to open on (1 based). 0 means active tab, not set means
"     override tab with same host if exists or create a new tab if it doesn't.
function! ide#mac#OpenUrl(url, ...) abort " {{{
  if a:0 == 0
    let tab_idx = 0
    let host = ide#util#GetUrlHost(a:url)
    let urls = ide#mac#GetBrowserUrls()
    for i in range(1, len(urls))
      if host ==# ide#util#GetUrlHost(urls[i - 1]) ||
          \ urls[i - 1] == "chrome://newtab/"
        let tab_idx = i
      endif
    endfor
    if tab_idx == 0
      call ide#mac#OpenBrowserTab()
    endif
  else
    let tab_idx = a:1
  endif

  if tab_idx == 0
    let cmd = 'set URL of active tab of window 1 to "' . a:url . '"'
  else
    let cmd = 'set URL of tab ' . tab_idx . ' of window 1 to "' . a:url . '"'
  endif

  call <SID>ExecScript(g:ide_mac_browser, s:external_browser_id, cmd)

  if tab_idx != 0
    call ide#mac#SelectBrowserTab(tab_idx)
  endif
  let s:cur_external_win_id = s:external_browser_id
endfunction " }}}


" Gets current list of URLs displayed in browser
function! ide#mac#GetBrowserUrls() abort " {{{
  let urls = []
  for url in split(split(system("osascript" .
      \ " -e " . "'set urlString to " . '""' . "'" .
      \ " -e " . "'tell app " . '"' . g:ide_mac_browser . '"' . "'" .
      \ " -e " . "'repeat with i from 1 to (count of tabs of window 1)'" .
      \ " -e " . "'set tabUrl to URL of tab i of window 1'" .
      \ " -e " . "'set urlString to urlString & tabUrl & " . '","' . "'" .
      \ " -e " . "'end repeat'" .
      \ " -e " . "'end tell'" .
      \ " -e " . "'return text 1 thru -1 of urlString'"), '\n')[0], ',')
    " Strip spaces and convert to int
    call add(urls, url)
  endfor
  return urls
endfunction " }}}


" Minimize browser.
function! ide#mac#MinimizeBrowser() abort " {{{
  call <SID>ExecScript(
    \ g:ide_mac_browser, s:external_browser_id,
    \ 'set minimized of window win_id to true')
  let s:cur_external_win_id = s:external_browser_id
endfunction " }}}


" Maximize browser.
function! ide#mac#MaximizeBrowser() abort " {{{
  call <SID>ExecScript(
    \ g:ide_mac_browser, s:external_browser_id,
    \ 'set minimized of window win_id to false')
  let s:cur_external_win_id = s:external_browser_id
endfunction " }}}


" Selects browser.
function! ide#mac#SelectBrowser() abort " {{{
  call <SID>ActivateExternalWindow(
    \ g:ide_mac_browser, s:external_browser_id)
  let s:cur_external_win_id = s:external_browser_id
endfunction " }}}


" Selects browser tab.
"
" Args:
"   offset: Tab offset (1 based).
function! ide#mac#SelectBrowserTab(offset) abort " {{{
  let cmd = "set active tab index of first window to " . a:offset
  call <SID>ExecScript(g:ide_mac_browser, s:external_browser_id, cmd)
  let s:cur_external_win_id = s:external_browser_id
endfunction " }}}


" Selects next browser tab.
function! ide#mac#SelectNextBrowserTab() abort " {{{
  let cmd = 'tell application "System Events"' .
    \ ' to keystroke "}" using {command down}'
  call <SID>ExecScript(g:ide_mac_browser, s:external_browser_id, cmd)
  let s:cur_external_win_id = s:external_browser_id
endfunction " }}}


" Selects prev browser tab.
function! ide#mac#SelectPrevBrowserTab() abort " {{{
  let cmd = 'tell application "System Events"' .
    \ ' to keystroke "{" using {command down}'
  call <SID>ExecScript(g:ide_mac_browser, s:external_browser_id, cmd)
  let s:cur_external_win_id = s:external_browser_id
endfunction " }}}


" Position browser relative to MacVim.
"
" Args:
"   pos: 'right', 'left', 'top', 'bottom'
"   a:1: True to force alignment of any term even if no term open
function! ide#mac#PositionBrowserRelativeToMacVim(pos, ...) abort " {{{
  if s:external_browser_id != 0 || (a:0 > 0 && a:1)
    if s:external_browser_id != 0
      let bounds = <SID>GetExternalWindowBounds(
        \ g:ide_mac_terminal, s:external_browser_id)
    else
      let bounds = <SID>GetExternalWindowBounds(g:ide_mac_browser)
    endif

    let bounds = <SID>GetExternalWindowBounds(g:ide_mac_browser)
    if a:pos ==# "right" || a:pos ==# "left"
      let size = bounds[2] - bounds[0]
    else
      let size = bounds[3] - bounds[1]
    endif
    call <SID>PositionAppRelativeToMacVim(
      \ g:ide_mac_browser, '', '', a:pos, size,
      \ g:ide_mac_browser_min_bounds, g:ide_mac_browser_max_bounds)

    " Reset window id
    let s:external_browser_id = <SID>GetExternalWindowId(g:ide_mac_browser)
    let s:cur_external_win_id = s:external_browser_id
  endif
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Internal helper functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Positions an application relative to the current MacVim window.
"
" Args:
"   app_name: Application name
"   pre_cmd: Script to call before bounds set
"   post_cmd: Script to call after bounds set
"   pos: 'right', 'left', 'top', or 'bottom'.
"   size: Width (if pos left/right) or height (if pos bottom/top) in pixels. If
"     a value less than or equals to 0 is passed then the size is calculated
"     based on remaining screen width (if left/right) or height (if top/bottom)
"     minus the passed in size (e.g. size = 0 will fill remaining space)
"   min_bounds: List of min [width, height]
"   max_bounds: List of max [width, height]
"
" Returns:
"   Returns result of call to post_cmd.
function! s:PositionAppRelativeToMacVim(
  \ app_name, pre_cmd, post_cmd, pos, size, min_bounds, max_bounds) abort " {{{
  if ide#util#Os() ==# "mac"
    " Read bounds for MacVim
    let macvim_bounds = <SID>GetExternalWindowBounds('MacVim')

    if a:size > 0
      let calc_size = a:size
    else
      let resolution = <SID>GetScreenResolution()
      if a:pos ==# "right"
        let calc_size = resolution[0] - macvim_bounds[2] - a:size
      elseif a:pos ==# "left"
        let calc_size = resolution[0] - macvim_bounds[0] - a:size
      elseif a:pos ==# "bottom"
        let calc_size = resolution[1] - macvim_bounds[3] - a:size
      else
        let calc_size = resolution[1] - macvim_bounds[1] - a:size
      endif

    endif

    " Set bounds for app
    let app_bounds = [0, 0, 0, 0]
    if a:pos ==# "right" || a:pos ==# "left"
      if a:pos ==# "right"
        let app_bounds[0] = macvim_bounds[2]
        let app_bounds[2] = macvim_bounds[2] + calc_size
      else
        let app_bounds[0] = macvim_bounds[0] - calc_size
        let app_bounds[2] = macvim_bounds[0]
      endif
      let app_bounds[1] = macvim_bounds[1]
      let app_bounds[3] = macvim_bounds[3]
    else
      if a:pos ==# "top"
        let app_bounds[1] = macvim_bounds[1] - calc_size
        let app_bounds[3] = macvim_bounds[1]
      else
        let app_bounds[1] = macvim_bounds[3]
        let app_bounds[3] = macvim_bounds[3] + calc_size
      endif
      let app_bounds[0] = macvim_bounds[0]
      let app_bounds[2] = macvim_bounds[2]
    endif

    " Limit our bounds to min specs
    if app_bounds[2] - app_bounds[0] < a:min_bounds[0]
      let app_bounds[2] = app_bounds[0] + a:min_bounds[0]
    endif
    if app_bounds[3] - app_bounds[1] < a:min_bounds[1]
      let app_bounds[3] = app_bounds[1] + a:min_bounds[1]
    endif

    " Limit our bounds to max specs
    if app_bounds[2] - app_bounds[0] > a:max_bounds[0]
      let app_bounds[2] = app_bounds[0] + a:max_bounds[0]
    endif
    if app_bounds[3] - app_bounds[1] > a:max_bounds[1]
      let app_bounds[3] = app_bounds[1] + a:max_bounds[1]
    endif

    " Position app
    if !empty(a:pre_cmd)
      return system("osascript" .
        \ " -e " . "'tell app " . '"' . a:app_name . '"' . "'" .
        \ " -e " . "'" . a:pre_cmd . "'" .
        \ " -e " . "'set bounds of window 1 to {" .
          \ app_bounds[0] . "," . app_bounds[1] . "," .
          \ app_bounds[2] . "," . app_bounds[3] . "}'" .
        \ " -e " . "'" . a:post_cmd . "'" .
        \ " -e " . "'end tell'")
    else
      return system("osascript" .
        \ " -e " . "'tell app " . '"' . a:app_name . '"' . "'" .
        \ " -e " . "'set bounds of window 1 to {" .
          \ app_bounds[0] . "," . app_bounds[1] . "," .
          \ app_bounds[2] . "," . app_bounds[3] . "}'" .
        \ " -e " . "'" . a:post_cmd . "'" .
        \ " -e " . "'end tell'")
    endif
  endif
endfunction " }}}


" Executes apple script within given app and window id
"
" Within the script the window ID will be available as the var 'win_id'.
"
" Args:
"   app_name: Name of app ("Terminal", etc).
"   win_id: ID of window of app to select.
"   cmd, a:1...n: Scripts to execute (executed using -e '<cmd>').
"
" Returns:
"   Result of executing cmd.
function! s:ExecScript(app_name, win_id, cmd, ...) abort " {{{
  if ide#util#Os() ==# "mac"
    let cmds = [" -e '" . a:cmd . "'"]
    for item in a:000
      call add(cmd, " -e '" . item . "'")
    endfor
    let cmd = join(cmds, '')

    " Exec script
    let result = system("osascript" .
      \ " -e " . "'tell app " . '"' . a:app_name . '"' . "'" .
      \ " -e " . "'set win_id to get index of window id " . a:win_id . "'" .
      \ " -e " . "'activate win_id'" .
      \ cmd .
      \ " -e " . "'end tell'")

    " Reset focus to previous window (e.g. MacVim) using cmd-ta
    " TODO: annoying flicker, disabling for now
    "call system("osascript" .
    "  \ " -e " . "'tell application " . '"System Events"' .
    "    \ " to keystroke tab using {command down}'")

    return result
  endif
endfunction " }}}


" Gets app's external window id
"
" Args:
"   app_name: Name of app ("Terminal", etc).
"
" Returns:
"   Apps external window id.
function! s:GetExternalWindowId(app_name) abort " {{{
  if ide#util#Os() ==# "mac"
    return split(system("osascript" .
      \ " -e " . "'tell app " . '"' . a:app_name . '"' . "'" .
      \ " -e " . "'get id of front window'" .
      \ " -e " . "'end tell'"), '\n')[0]
  endif
endfunction " }}}


" Activates app's external window.
"
" Args:
"   app_name: Name of app ("Terminal", etc).
"   win_id: External window id for app.
function! s:ActivateExternalWindow(app_name, win_id) abort " {{{
  if ide#util#Os() ==# "mac"
    call system("osascript" .
      \ " -e " . "'tell app " . '"' . a:app_name . '"' . "'" .
      \ " -e " . "'set win_id to get index of window id " . a:win_id . "'" .
      \ " -e " . "'activate window id win_id'" .
      \ " -e " . "'end tell'")
  endif
endfunction " }}}


" Get external window bounds
"
" Args:
"   app_name: App name.
function! s:GetExternalWindowBounds(app_name, ...) abort " {{{
  if ide#util#Os() ==# "mac"
    let bounds = []
    if a:0 > 0
      let activate_cmds =
        \ " -e " . "'set win_id to get index of window id " . a:1 . "'" .
        \ " -e " . "'activate window id win_id'"
    else
      let activate_cmds = ""
    endif

    " Bounds returned as 'start_x, start_y, end_x, end_y\n'
    for item in split(split(system("osascript" .
        \ " -e " . "'tell app " . '"' . a:app_name . '"' . "'" .
        \ activate_cmds .
        \ " -e " . "'get bounds of front window'" .
        \ " -e " . "'end tell'"), '\n')[0], ',')
      " Strip spaces and convert to int
      call add(bounds, substitute(item, ' ', '', 'g') + 0)
    endfor
    return bounds
  endif
endfunction " }}}


" Gets screen resolution size
function! s:GetScreenResolution() abort " {{{
  if ide#util#Os() ==# "mac"
    if !exists("s:screen_resolution")
      let s:screen_resolution = []

      for item in split(split(system(
          \   'system_profiler SPDisplaysDataType | grep Resolution | ' .
          \   'head -1 | ' .
          \   "sed -ne 's/[^0-9]*\\([0-9]*\\) x \\([0-9]*\\).*/\\1,\\2/p'"
          \ ), '\n')[0], ',')
        call add(s:screen_resolution, item + 0)  " convert to int
      endfor
    endif
    return s:screen_resolution
  endif
endfunction " }}}
