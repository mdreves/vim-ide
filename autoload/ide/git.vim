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

let s:git_rev_history = []
let s:MAX_REV_HISTORY = 1000


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Git specific functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Opens git view.
"
" Args:
"   a:1: Optional url to open in git view (default opens head revision).
function! ide#git#OpenGitView(cmd, ...) abort " {{{
  if ide#util#NameRangeMatch(a:cmd, "l", "log")
    if a:0 > 0 && (ide#util#NameRangeMatch(a:1, "a", "all") || a:1 ==? "*")
      " git log all
      let results = ide#util#InvokeShellCmd("git log --pretty=oneline")
    else
      " git log
      let results = ide#util#InvokeShellCmd(
        \ "git log --pretty=oneline -- " . expand("%:p"))
    endif
    if len(results) > 0
      call ide#git#CloseGitView()

      call ide#util#ChooseFile(
        \ "git_log", g:ide_git_view_pos, g:ide_git_view_size, '',
        \ <SID>FormatLogs(results), "ide#git#IdeGitRevChosenCb", "e")
    else
      return ide#util#EchoError("No git logs found")
    endif
  elseif ide#util#NameRangeMatch(a:cmd, "s", "status")
    " git status
    call ide#git#CloseGitView()
    exec ":Gstatus"
    call ide#view#PositionViewWindow("git")
  elseif ide#util#NameRangeMatch(a:cmd, "c", "commit")
    " git commit
    call ide#git#CloseGitView()
    exec ":Gcommit"
    call ide#view#PositionViewWindow("git")
  elseif ide#util#NameRangeMatch(a:cmd, "r", "read")
    " git read
    exec ":Gread " . join(a:000, " ")
  elseif ide#util#NameRangeMatch(a:cmd, "w", "write")
    " git write
    exec ":Gwrite " . join(a:000, " ")
  elseif ide#util#NameRangeMatch(a:cmd, "m", "mv")
    " git mv
    exec ":Gmove " . join(a:000, " ")
  elseif ide#util#NameRangeMatch(a:cmd, "r", "rm")
    " git rm
    exec ":Gremove " . join(a:000, " ")
  elseif ide#util#NameRangeMatch(a:cmd, "b", "blame")
    " git blame
    exec ":Gblame " . join(a:000, " ")
  elseif ide#util#NameRangeMatch(a:cmd, "br", "browse")
    " git browse
    exec ":Gbrowse " . join(a:000, " ")
  elseif a:cmd =~ "fugitive"
    call ide#view#OpenViewWindow(
      \ "git", "git_edit", ":edit " . a:cmd, "ide#git#IdeGitRevChosenCb", "e")
  endif
endfunction " }}}


function! ide#git#CloseGitView() abort " {{{
  call ide#view#CloseViewWindow("git")
endfunction " }}}


" Callback for when git rev chosen from window.
function! ide#git#IdeGitRevChosenCb(action, line, ...) abort " {{{
  if a:action ==# "c-t"
    if len(s:git_rev_history) != 0
      let last = s:git_rev_history[-1]
      call remove(s:git_rev_history, -1)
      call ide#view#OpenViewWindow(
        \ "git", "git_edit", ":edit " . last, "ide#git#IdeGitRevChosenCb", "e")
    endif
    return
  else
    let hash = ""
    for token in split(a:line, ' ')
      if token =~ "[0-9a-fA-F]\\{40}"
        let hash = token
        break
      endif
    endfor

    if empty(hash)
      return
    endif

    if a:0 > 0 && a:1 =~ "fugitive" &&
        \ (len(s:git_rev_history) == 0 || s:git_rev_history[-1] !=? a:1)
      call add(s:git_rev_history, a:1)
    endif
  endif

  let rev = "fugitive://" . b:git_dir . "//" . hash
  let git_path = expand('%:p')[len(b:git_dir) - 4:]
  if a:action ==# 't'
    exec ":tabnew | :open " . rev
  elseif a:action ==# 's'
    call ide#view#OpenView("split", rev)
  elseif a:action ==# 'e'
    call ide#view#OpenViewWindow(
      \ "git", "git_edit", ":edit " . rev, "ide#git#IdeGitRevChosenCb", "e")
  elseif a:action ==# 'E'
    silent exec "!gvim -c :new | :open " . rev
  elseif a:action ==# 'd'
    call ide#view#OpenView("diff", rev . "/" . git_path)
  elseif a:action ==# 'D'
    silent exec "!gvimdiff -R " . expand("%") . " " . rev . "/" . git_path
  endif
endfunction " }}}


" Gets git revision from string if possible.
"
" Args:
"   str: String to get rev from.
"   a:1: Optional file path to append to rev.
"
" Returns:
"   Fugative revision or empty string if not possible.
function! ide#git#GetGitRev(str, ...) abort " {{{
  if ! exists("b:git_dir")
    return ""
  endif

  if ide#util#NameRangeMatch(a:str, ":staged", ":staged") ||
      \ ide#util#NameRangeMatch(a:str, ":cached", ":cached")
    let rev_name = 0
  elseif a:str == ":git/"
    return "fugitive://" . b:git_dir
  else
    if ide#util#NameRangeMatch(a:str, ":h", ":head")
      let id = "HEAD"
    elseif a:str =~ ":head"
      let id = "HEAD" . a:str[5:]
    else
      let id = a:str[0] ==? ":" ? a:str[1:] : a:str
    endif

    let results = ide#util#InvokeShellCmd("git rev-parse " . id)
    if len(results) == 1 && results[0] =~ "[0-9a-fA-F]\\{40}"
      let rev_name = results[0]
    else
      return ""
    endif
  endif

  let rev = "fugitive://" . b:git_dir . "//" . rev_name
  if a:0 > 0
    return rev . "/" . ide#git#GetGitPath(a:1)
  else
    return rev
  endif
endfunction " }}}


" Gets git path relative to repository.
"
" Args:
"   path: Full path to file or directory.
"
" Returns:
"   Path relative to git repository.
function! ide#git#GetGitPath(path) abort " {{{
  if exists("b:git_dir")
    let git_home = b:git_dir[:-5]
    if a:path =~ "^" . git_home
      return a:path[len(git_home):]
    endif
  endif
  return a:path
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Formats git log output
"
" Args:
"   logs: List of logs from 'git log'
"
" Returns
"   List of formatted log output.
function! s:FormatLogs(logs) abort " {{{
  let results = []
  for log in a:logs
    let log_values = split(log, " ")
    " Trim hash to 7 chars
    let formatted_log = log_values[0][0:6] . " : " . join(log_values[1:], " ")
    call add(results, formatted_log)
  endfor
  return results
endfunction " }}}
