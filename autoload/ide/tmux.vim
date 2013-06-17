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
"
" This code relies on the following global variables being set:
"   g:ide_tmux_host     - host running tmux server (e.g. "localhost")
"   g:ide_tmux_session  - name of tmux session
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tmux specific functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Sends text to tmux.
"
" Args:
"   text: Text to send.
"   a:1: Session (<session_name>[:<win_id>[.<pane_id>]]).
function! ide#tmux#Send(text, ...) abort " {{{
  if a:0 > 0
    let session = a:1
  else
    let session = ide#tmux#GetSession()
  endif

  let buffer_text = "'" . substitute(a:text, "'", "'\\\\''", 'g') . "'"
  call <SID>RunTmuxCmd("set-buffer " . buffer_text)
  call <SID>RunTmuxCmd("paste-buffer -t " . session)
endfunction " }}}


" Sends range of text to tmux
"
" Args:
"   a:firstline: First line of text.
"   a:lastline: Last line of text.
function! ide#tmux#SendRange(...) range abort " {{{
  let text = ide#util#GetSelectedTextRange()
  return call("ide#tmux#Send", [text] + a:000)
endfunction " }}}


" Selects window
"
" Args:
"   win: Window name.
"   a:1: Session (<session_name>).
function! ide#tmux#CurWindow(...) abort " {{{
  let win = <SID>RunTmuxCmd('display-message -p "#W"')
  if ! empty(win)
    return split(win, "\n")[0]
  else
    return ""
  endif
endfunction " }}}


" Selects named window
"
" Args:
"   win: Window name.
"   a:1: Session (<session_name>).
function! ide#tmux#SelectWindow(win, ...) abort " {{{
  if a:0 > 0
    let session = a:1
  else
    let session = ide#tmux#GetSession()
  endif

  if empty(session)
    return
  endif

  let session = split(session, ":")[0]

  call <SID>RunTmuxCmd("select-window -t " . session . ':' . a:win)
endfunction " }}}


" Selects next tmux window
"
" Args:
"   a:1: Session (<session_name>).
function! ide#tmux#NextWindow(...) abort " {{{
  if a:0 > 0
    let session = a:1
  else
    let session = ide#tmux#GetSession()
  endif

  if empty(session)
    return
  endif

  let session = split(session, ":")[0]

  call <SID>RunTmuxCmd("next-window -t " . session)
endfunction " }}}


" Selects previous tmux window
"
" Args:
"   a:1: Session (<session_name>).
function! ide#tmux#PrevWindow(...) abort " {{{
  if a:0 > 0
    let session = a:1
  else
    let session = ide#tmux#GetSession()
  endif

  if empty(session)
    return
  endif

  let session = split(session, ":")[0]

  call <SID>RunTmuxCmd("previous-window -t " . session)
endfunction " }}}


" Rename current window
"
" Args:
"   new_name: New window name.
"   a:1: Session (<session_name>).
function! ide#tmux#RenameWindow(new_name, ...) abort " {{{
  if a:0 > 0
    let session = a:1
  else
    let session = ide#tmux#GetSession()
  endif

  if empty(session)
    return
  endif

  let session = split(session, ":")[0]

  call <SID>RunTmuxCmd("rename-window -t " . session . ' ' . a:new_name)
endfunction " }}}


" Creates new window
"
" Args:
"   a:name: Window name.
"   a:1: Session (<session_name>).
function! ide#tmux#NewWindow(name, ...) abort " {{{
  if a:0 > 0
    let session = a:1
  else
    let session = ide#tmux#GetSession()
  endif

  if empty(session)
    return
  endif

  let session = split(session, ":")[0]

  call <SID>RunTmuxCmd("new-window -t " . session . ' -d -n ' . a:name)
endfunction " }}}


" Gets window names
"
" Args:
"   a:1: Session (<session_name>).
function! ide#tmux#GetWindowNames(...) abort " {{{
  if a:0 > 0
    let session = a:1
  else
    let session = ide#tmux#GetSession()
  endif

  if empty(session)
    return
  endif

  let session = split(session, ":")[0]

  let results = []
  for name in split(<SID>RunTmuxCmd("list-windows -t " . session), "\n")
    let parts = split(name, " ")
    if len(parts) > 1
      call add(results, parts[1])
    else
      call add(results, name)
    endif
  endfor
  return results
endfunction " }}}


" Gets command for attaching to session
"
" Args:
"   a:session: Session name
function! ide#tmux#GetAttachSessionCmd(session) abort " {{{
  if empty(g:ide_tmux_host) || g:ide_tmux_host == "localhost"
    return "tmux attach -t " . a:session . " || tmux new -s " . a:session
  else
    return "ssh -t -Y " . g:ide_tmux_host . ' \"' .
      \ "tmux attach -t " . a:session . " || tmux new -s " . a:session . '\"'
  endif
endfunction " }}}


" Gets current tmux host or default if not set.
function! ide#tmux#GetHost() abort " {{{
  if empty(g:ide_tmux_host)
    return "localhost"
  else
    return g:ide_tmux_host
  endif
endfunction " }}}


" Gets configures session, else current session.
function! ide#tmux#GetSession() abort " {{{
  if empty(g:ide_tmux_session)
    return ide#tmux#GetCurSession()
  else
    return g:ide_tmux_session
  endif
endfunction " }}}


" Gets opposite session to configured session.
"
" If 'foo' is configured then 'foo_2' is returned. If 'foo_2' then 'foo'.
function! ide#tmux#GetOppositeSession(...) abort " {{{
  if a:0 > 0
    let session = a:1
  else
    let session = ide#tmux#GetSession()
  endif
  if empty(session)
    return ""
  endif
  if session[-2:-1] == "_2"
    return session[:-3]
  else
    return session . "_2"
  endif
endfunction " }}}


" Gets current session.
function! ide#tmux#GetCurSession() abort " {{{
  let sessions = split(
    \ system("tmux display-message -p '#S' 2> /dev/null"), "\n")
  if len(sessions) != 0
    return sessions[0]
  endif
  return ""
endfunction " }}}


" Gets default (first) session
function! ide#tmux#GetFirstSession() abort " {{{
  let sessions = split(
    \ system("tmux list-sessions | sed -e 's/:.*$//'"), "\n")
  if len(sessions) != 0
    return sessions[0]
  endif
  return ""
endfunction " }}}


" Sets tmux host.
"
" If no args passed then user is prompted.
"
" Args:
"   a:1 host
function! ide#tmux#SetHost(...) abort " {{{
  if a:0 > 0
    let g:ide_tmux_host = a:1
  else
    let g:ide_tmux_host = input('Host: ', "")
  endif
endfunction " }}}


" Sets tmux session.
"
" If no args passed then user is prompted.
"
" Args:
"   a:1 session (<session_name>[:<win_id>[.<pane_id>]])
function! ide#tmux#SetSession(...) abort " {{{
  if a:0 > 0
    let g:ide_tmux_session = a:1
  else
    let g:ide_tmux_session = input(
      \ 'Session: ', "", "custom,ide#tmux#SessionComplete")
  endif
endfunction " }}}


" Completion support for tmux session.
function! ide#tmux#SessionComplete(argLead, cmdLine, cursorPos) abort " {{{
  let items = split(a:cmdLine, ":")
  if len(items) < 1
    return <SID>RunTmuxCmd("list-sessions | sed -e 's/:.*$//'")
  elseif len(items) == 1 && a:cmdLine[len(a:cmdLine) - 1] != ":"
    return a:cmdLine . ":"
  else
    let session = items[0]
    let next_items = len(items) > 1 ? split(items[1], "\\.") : []
    if len(next_items) < 1
      let results = []
      for entry in split(<SID>RunTmuxCmd(
          \ "list-windows -t " . session . " | cut -d' ' -f1"), "\n")
        call add(results, session . ":" . split(entry, ":")[0])
      endfor
      return join(results, "\n")
    elseif len(next_items) == 1 && a:cmdLine[len(a:cmdLine) - 1] != "."
      return a:cmdLine . "."
    else
      let results = []
      for entry in split(<SID>RunTmuxCmd(
          \ "list-panes -t " . session . ":" . next_items[0] .
          \ " | cut -d' ' -f1"), "\n")
        call add(results,
          \ session . ":" . next_items[0] . "." . split(entry, ":")[0])
      endfor
      return join(results, "\n")
    endif
  endif
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Internal helper functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Runs tmux command and returns results
"
" Args:
"   cmd: Tmux command.
"
" Returns:
"   Results of system call.
function! s:RunTmuxCmd(cmd) abort " {{{
  if empty(g:ide_tmux_host) || g:ide_tmux_host == "localhost"
    return system("tmux " . a:cmd)
  else
    return system("ssh -t -Y " . g:ide_tmux_host . ' "tmux ' . a:cmd . '"')
  endif
endfunction " }}}

