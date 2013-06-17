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

let s:initialized = 0

" Init projux settings
function! ide#projux#Init() abort " {{{
  if s:initialized
    return
  endif

  let s:initialized = 1

  if ! empty($PROJECT_NAME)
    let s:projux_installed = 1
    let s:project_name = $PROJECT_NAME
  else
    let s:projux_installed = 0
    return
  endif

  let s:project_dir = $PROJECT_DIR
  let s:project_src_dir = $PROJECT_SRC_DIR
  let s:project_test_dir = $PROJECT_TEST_DIR
  let s:project_pkgs = split($PROJECT_PKGS, " ")

  " Update path to include project src/test dirs
  let p = s:project_src_dir . ',' . s:project_test_dir
  set path=p

  let g:ide_tmux_host = $PROJECT_HOST
  if g:ide_tmux_host == split(system("hostname"))[0]
    let g:ide_tmux_host = "localhost"
  endif

  " With tmux grouped sessions, vim always run in main session so assuming
  " we are running in the second session, the main session is the external
  let tmux_session = split(
    \ system("tmux display-message -p '#S' 2> /dev/null"), "\n")
  if len(tmux_session) > 0
    let g:ide_tmux_session = tmux_session[0]
  endif

  if !exists("g:ide_tmux_win_vim")
    let g:ide_tmux_win_vim = "vim_2"
  endif
  if !exists("g:ide_tmux_win_shell")
    let g:ide_tmux_win_shell = "bash"
  endif
  if !exists("g:ide_tmux_win_build")
    let g:ide_tmux_win_build = "build"
  endif
  if !exists("g:ide_tmux_win_repl")
    let g:ide_tmux_win_repl = "repl"
  endif
endfunction " }}}


" Projux ProjectName implementation
function! ide#projux#ProjectName() abort " {{{
  if ! s:initialized
    call ide#projux#Init()
  endif
  return s:project_name
endfunction " }}}


" Projux ProjectDir implementation
function! ide#projux#ProjectDir() abort " {{{
  if ! s:initialized
    call ide#projux#Init()
  endif
  return s:project_dir
endfunction " }}}


" Projux ProjectSrcDirs implementation
function! ide#projux#ProjectSrcDirs() abort " {{{
  if ! s:initialized
    call ide#projux#Init()
  endif

  let dirs = []
  for p in s:project_pkgs
    call add(dirs, s:project_src_dir . '/' . p)
  endfor

  if len(dirs) == 0
    return [s:project_src_dir]
  else
    return dirs
  endif
endfunction " }}}


" Projux ProjectTestDirs implementation
function! ide#projux#ProjectTestDirs() abort " {{{
  if ! s:initialized
    call ide#projux#Init()
  endif

  let dirs = []
  for p in s:project_pkgs
    call add(dirs, s:project_test_dir . '/' . p)
  endfor

  if len(dirs) == 0
    return [s:project_test_dir]
  else
    return dirs
  endif
endfunction " }}}


" Projux Project implementation
function! ide#projux#Project(...) abort " {{{
  if ! s:initialized
    call ide#projux#Init()
  endif

  if ! s:projux_installed
    return ide#util#EchoError("Projux not installed")
  endif

  if a:0 == 0
    return ide#util#EchoShellCmd("project")
  elseif a:1 ==# "ls"
    return ide#projux#ChooseProject(
       \ "projects", g:ide_list_view_pos, g:ide_list_view_size)
  elseif a:1 ==# "settings"
    return ide#util#EchoShellCmd("project settings")
  elseif a:0 > 1 && a:2 ==# "settings"
    return ide#util#EchoShellCmd("project " . a:1 . " settings")
  else
    return ide#util#InvokeShellCmd("project " . a:1)
  endif
endfunction " }}}


" Projux GetUrl implementation
function! ide#projux#GetUrl(...) abort " {{{
  if ! s:initialized
    call ide#projux#Init()
  endif

  if ! s:projux_installed
    return ide#util#EchoError("Projux not installed")
  endif

  let out = ide#util#InvokeShellCmd("geturl " . join(a:000, " "))
  if len(out) > 0 && out[0] != "NOT PROJECT HOST!"
    return out[0]
  else
    return ""
  endif
endfunction " }}}


" Projux Search implementation
function! ide#projux#Search(...) " {{{
  if ! s:initialized
    call ide#projux#Init()
  endif

  if ! s:projux_installed
    return ide#util#EchoError("Projux not installed")
  endif

  return ide#util#InvokeShellCmd(
    \ "search " . join(ide#util#ExpandKeywords(a:000, 0, ""), " "))
endfunction " }}}


" Projux SearchContext implementation
function! ide#projux#SearchContext(context) abort " {{{
  if ! s:initialized
    call ide#projux#Init()
  endif

  if ! s:projux_installed
    return ide#util#EchoError("Projux not installed")
  endif

  return ide#projux#Search(a:context)
endfunction " }}}


" Projux Format implementation
function! ide#projux#Format(...) abort " {{{
  if ! s:initialized
    call ide#projux#Init()
  endif

  if ! s:projux_installed
    return ide#util#EchoError("Projux not installed")
  endif

  let format_cmd = "FILE_TYPE=" . &filetype . " format"
  if a:0 > 0 && ide#util#NameRangeMatch(a:1, ":s", ":selected")
    " In this case formatexpr was used. The v:lnum and v:count are set
    " by VIM to the start of the selected line and number of lines
    " selected. The ide#util#ReplaceSelectedText will read those selected
    " lines and pass them to our format program. If it is successful it
    " will replace the lines with the formatted output returned. If it is
    " not successful it will return a non-zero status code which we then
    " return from formatexpr. A non-zero return will cause VIM to use the
    " default formatting routines. The net effect is that we can all out
    " to 'format' and if it has a supported formatter (gofmt, clang-format,
    " etc) then it will be run, otherwise the default VIM formatting will
    " be used.
    "
    " NOTE: The projux format command takes a FILE_TYPE env var so we can
    "   provide a hint to the formater about the file being formated
    if mode() != "n"
      " Only basic mode formatting supported
      return 1
    endif
    return ide#util#ReplaceSelectedText(v:lnum, v:count, format_cmd)
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":b", ":buffer")
    " This works similar to formatexpr except in this case we are going to
    " run the format across the entire current buffer (line 1 to $)
    return ide#util#ReplaceSelectedText(1, line("$"), format_cmd)
  endif

  " Continue with formatting using specifically named files

  let base_dir = $PROJECT_BUILD_DIR

  call g:IdeWin("external", g:ide_tmux_win_build)
  return ide#tmux#Send(
    \ "pushd " . base_dir . " &> /dev/null && " .
    \ "format " . join(ide#util#RemoveCommonPath(base_dir, a:000), " ") .
    \ "; popd &> /dev/null\n",
    \ ide#tmux#GetSession() . ":" . g:ide_tmux_win_build)
endfunction " }}}


" Projux Lint implementation
function! ide#projux#Lint(...) " {{{
  if ! s:initialized
    call ide#projux#Init()
  endif

  if ! s:projux_installed
    return ide#util#EchoError("Projux not installed")
  endif

  if a:0 > 0 && ide#util#NameRangeMatch(a:1, ":b", ":buffer")
    " In this case the current buffer is being linted. Pass all the lines
    " to the lint program as stdin and then send the output to the loc list.
    "
    " NOTE: The projux lint command takes a FILE_TYPE env var so we can
    "   provide a hint to the linter on how to lint the file
    let text = join(getline(1, line("$")), "\n") . "\n"
    let lint_cmd = "FILE_TYPE=" . &filetype .
          \ " FILE_NAME=" . expand("%:p") . " lint"
    let results = system(lint_cmd, text)
    if v:shell_error == 0 && results != "\n"
      let errlist = ide#util#MakeLocationList(split(results, "\n"))
      call setloclist(0, errlist)

      " Let syntastic do its job...
      call ide#syntastic#DisplayErrors('location')
    endif
    return 0
  endif

  let base_dir = $PROJECT_BUILD_DIR

  if ! empty(v:servername)
    let async_response = " && vim --servername ${PROJECT_NAME}" .
       \ " --remote-send \":Errors :lint<CR>\" &> /dev/null"
  else
    let async_response = ""
  endif

  call g:IdeWin("external", g:ide_tmux_win_build)
  call ide#tmux#Send(
    \ "pushd " . base_dir . " &> /dev/null && " .
    \ "lint " . join(ide#util#RemoveCommonPath(base_dir, a:000), " ") .
    \ async_response .
    \ "; popd &> /dev/null\n",
    \ ide#tmux#GetSession() . ":" . g:ide_tmux_win_build)
endfunction " }}}


" Projux Build implementation
function! ide#projux#Build(...) " {{{
  if ! s:initialized
    call ide#projux#Init()
  endif

  if ! s:projux_installed
    return ide#util#EchoError("Projux not installed")
  endif

  let base_dir = $PROJECT_BUILD_DIR

  if ! empty(v:servername)
    let async_response = " && vim --servername ${PROJECT_NAME}" .
       \ " --remote-send \":Errors :build<CR>\" &> /dev/null"
  else
    let async_response = ""
  endif

  call g:IdeWin("external", g:ide_tmux_win_build)
  call ide#tmux#Send(
    \ "pushd " . base_dir . " &> /dev/null && " .
    \ "build " . join(ide#util#RemoveCommonPath(base_dir, a:000), " ") .
    \ async_response .
    \ "; popd &> /dev/null\n",
    \ ide#tmux#GetSession() . ":" . g:ide_tmux_win_build)
endfunction " }}}


" Projux Test implementation
function! ide#projux#Test(...) " {{{
  if ! s:initialized
    call ide#projux#Init()
  endif

  if ! s:projux_installed
    return ide#util#EchoError("Projux not installed")
  endif

  let base_dir = $PROJECT_BUILD_DIR

  if ! empty(v:servername)
    let async_response = " && vim --servername ${PROJECT_NAME}" .
       \ " --remote-send \":Errors :test<CR>\" &> /dev/null"
  else
    let async_response = ""
  endif

  call g:IdeWin("external", g:ide_tmux_win_build)
  call ide#tmux#Send(
    \ "pushd " . base_dir . " &> /dev/null && " .
    \ "test " . join(ide#util#RemoveCommonPath(base_dir, a:000), " ") .
    \ async_response .
    \ "; popd &> /dev/null\n",
    \ ide#tmux#GetSession() . ":" . g:ide_tmux_win_build)
endfunction " }}}


" Projux Coverage implementation
function! ide#projux#Coverage(...) " {{{
  if ! s:initialized
    call ide#projux#Init()
  endif

  if ! s:projux_installed
    return ide#util#EchoError("Projux not installed")
  endif

  let base_dir = $PROJECT_BUILD_DIR

  if ! empty(v:servername)
    let async_response = " && vim --servername ${PROJECT_NAME}" .
       \ " --remote-send \":Errors :coverage<CR>\" &> /dev/null"
  else
    let async_response = ""
  endif

  call g:IdeWin("external", g:ide_tmux_win_build)
  call ide#tmux#Send(
    \ "pushd " . base_dir . " &> /dev/null && " .
    \ "coverage " . join(ide#util#RemoveCommonPath(base_dir, a:000), " ") .
    \ async_response .
    \ "; popd &> /dev/null\n",
    \ ide#tmux#GetSession() . ":" . g:ide_tmux_win_build)
endfunction " }}}


" Projux Sanity implementation
function! ide#projux#Sanity(...) abort " {{{
  if ! s:initialized
    call ide#projux#Init()
  endif

  if ! s:projux_installed
    return ide#util#EchoError("Projux not installed")
  endif

  let base_dir = $PROJECT_BUILD_DIR

  call g:IdeWin("external", g:ide_tmux_win_build)
  call ide#tmux#Send(
    \ "pushd " . base_dir . " &> /dev/null && " .
    \ "sanity " . join(ide#util#RemoveCommonPath(base_dir, a:000, 1), " ") .
    \ "; popd &> /dev/null\n",
    \ ide#tmux#GetSession() . ":" . g:ide_tmux_win_build)
endfunction " }}}


" Projux GetErrors implementation
function! ide#projux#GetErrors(...)
  if ! s:initialized
    call ide#projux#Init()
  endif

  if ! s:projux_installed
    return ide#util#EchoError("Projux not installed")
  endif

  if a:0 > 0 && (a:1 == ':build' || a:1 == ':lint' ||
      \ a:1 == ':test' || a:1 == ':coverage')
    let results = ide#util#InvokeShellCmd("geterrors " . a:1)
  else
    let results = ide#util#InvokeShellCmd(
      \ "geterrors " . join(ide#util#ExpandKeywords(a:000, 1, ""), " "))
  endif

  return ide#util#MakeLocationList(results)
endf


" Projux Run implementation
function! ide#projux#Run(...) " {{{
  if ! s:initialized
    call ide#projux#Init()
  endif

  if ! s:projux_installed
    return ide#util#EchoError("Projux not installed")
  endif

  call g:IdeWin("external", g:ide_tmux_win_shell)
  call ide#tmux#Send(
    \ "run " . join(ide#util#ExpandKeywords(a:000, 1, ""), " ") . "\n",
    \ ide#tmux#GetSession() . ":" . g:ide_tmux_win_shell)
endfunction " }}}


function! ide#projux#ExternalWindow(...)
  if ! s:initialized
    call ide#projux#Init()
  endif

  if ! s:projux_installed
    return ide#util#EchoError("Projux not installed")
  endif

  let out = ide#util#InvokeShellCmd("win " . join(a:000, " "))
  if len(out) > 0
    return out[0]
  else
    return ""
  endif
endf


" Projux project chooser
function! ide#projux#ChooseProject(buffer_name, win_pos, win_size) abort " {{{
  if ! s:initialized
    call ide#projux#Init()
  endif

  if ! s:projux_installed
    return ide#util#EchoError("Projux not installed")
  endif

  let projects = []
  let cur = 1
  let idx = 1
  for p in sort(ide#util#InvokeShellCmd("project ls"))
    if s:project_name == p
      let cur = idx
      call add(projects, ">" . p)
    else
      call add(projects, " " . p)
    endif
    let idx += 1
  endfor

  let win_size = max([min([a:win_size, len(projects)]), 3])
  call ide#util#OpenReadonlyWindow(
      \ a:buffer_name, projects, a:win_pos, win_size, cur)

  " map q to close window
  nnoremap <silent> <buffer> q
    \ :call ide#util#CloseWindow(bufname(''))<CR>

  " map enter to call funcref
  nnoremap <silent> <buffer> <cr>
    \ call ide#util#CloseWindow(bufname('')) \|
    \ call ide#util#InvokeShellCmd("project " . getline('.'))<CR>
endfunction " }}}
