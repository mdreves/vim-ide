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

" Check if loaded
if exists("g:loaded_ide_global_fns") || &cp || v:version < 700
  finish
endif
let g:loaded_ide_global_fns = 1

" Check if user disabled
if exists("g:ide") && g:ide == 0
 finish
endif


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Local Variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" State variables
let s:last_find = []             " args for last call to IdeFind
let s:last_find_results = []     " cached find results
let s:last_grep = []             " args for last call to IdeGrep
let s:last_grep_results = []     " cached grep results
let s:last_google = []           " args for last call to IdeGoogle
let s:last_diff = []             " args for call to IdeDiff
let s:last_ediff = []            " args for last call to IdeEDiff
let s:last_search = []           " args for last call to IdeSearch
let s:last_errors = []           " args for last call to IdeErrors
let s:last_lint_errors = []      " errors from last IdeLint
let s:last_build_errors = []     " errors from last IdeBuild
let s:last_test_errors = []      " errors from last IdeTest
let s:last_coverage_errors = []  " errors from last IdeCoverage
let s:last_run = []              " args for last call to IdeRun
let s:next_colorscheme = -1
let s:default_cmd_handlers = {}


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General function implementations.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Initialize IDE settings
function! g:IdeStartup() abort " {{{
  if &diff
    if has_key(g:ide_filetype_settings, 'diff')
      let settings = g:ide_filetype_settings['diff']
      if settings['colorscheme'] != -1
        exec "colorscheme " . g:ide_colorschemes[settings['colorscheme']][0]
      else
        exec "colorscheme " . g:ide_colorschemes[0][0]
      endif
      exec "set " . settings['local_settings']
    elseif has_key(g:ide_filetype_settings, 'default')
      let settings = g:ide_filetype_settings['default']
      if settings['colorscheme'] != -1
        exec "colorscheme " . g:ide_colorschemes[settings['colorscheme']][0]
      else
        exec "colorscheme " . g:ide_colorschemes[0][0]
      endif
      set wrap
    else
      exec "colorscheme " . g:ide_colorschemes[0][0]
      set wrap
    endif
    let g:background = "light"
    syntax off
    set nofoldenable foldcolumn=0 number
    wincmd b
    set nofoldenable foldcolumn=0 number
    wincmd =
    exec 'autocmd WinEnter * if winnr("$") == 1 | exec "q" | endif'
  else
    if ! empty(&filetype) && has_key(g:ide_filetype_settings, &filetype)
      let settings = g:ide_filetype_settings[&filetype]
      if settings['colorscheme'] != -1
        let cs_settings = g:ide_colorschemes[settings['colorscheme']]
      else
        let cs_settings = g:ide_colorschemes[0]
      endif
    elseif has_key(g:ide_filetype_settings, 'default')
      let settings = g:ide_filetype_settings['default']
      if settings['colorscheme'] != -1
        let cs_settings = g:ide_colorschemes[settings['colorscheme']]
      else
        let cs_settings = g:ide_colorschemes[0]
      endif
    else
      let cs_settings = g:ide_colorschemes[0]
    endif
    let g:background = cs_settings[1]
    exec "set background=" . cs_settings[1]
    if len(cs_settings) > 2 && !empty(cs_settings[2])
      exec "highlight Normal guibg=" . cs_settings[2]
    endif

    exec 'colorscheme ' . cs_settings[0]
  endif

  if exists("g:ide_post_startup")
    return call(g:ide_post_startup, [])
  endif
endfunction " }}}


" Overrides the VIM open command (not used) and opens the named target.
"
" Targets exists for views, files, dirs, urls, etc with selection based on the
" following keywords:
"   <view>                   : ':buf[fers]', ':pro[jects]', ':out[line]',
"                              ':exp[lorer]', ':ter[minal]', ':bro[wser]',
"                              ':qui[ckfix]', ':loc[ation]', ':hel[p]',
"                              ':git', ':dif[f]', ':mir[ror]', ':spl[it]'
"   ':tab'                   : Opens file in tab view
"
" By default, if none of the above keywords are found for the first argument,
" then 'file', 'dir', 'browser', or 'git' is assumed depending on the values
" of the additional args. For example:
"   open                     : Assumes 'dir' and opens explorer to current dir
"   open google.com          : Assumes 'browser' and opens browser to google.com
"   open foo                 : If 'foo' is dir then 'dir' else assumes 'file'
"   open :head               : Assumes 'git' and opens git view to HEAD revision
"
" The 'dir', 'file', 'split', and 'tab' options support additional keywords for
" specifying which file or dir to open:
"   ':test'                  : Open test file assoc with current file
"   ':test/'                 : Open test dir assoc with current file
"   ':src'                   : Open src file assoc with current file
"   ':src/'                  : Open src dir assoc with current file
"   ':project/'              : Open project dir assoc with current file
"   ':<ext>'                 : 'c', 'h', 'java', 'scala', assoc with cur file
"
" The 'browser' option supports the following additional keywords for
" specifying special URLs to open:
"   ':rev[iew] [id]'         : Open URL for code review
"   ':bug [id]'              : Open URL for bug
"   ':rep[ort] [name]'       : Open URL for named report
"
" Command Shortcuts:
"   :o         open
"   :ot        open tab
"   :os        open split
"
" Examples:
"  views:
"   open buffers             : Opens buffers view
"   open project             : Opens project view
"   open explorer            : Opens file/project explorer view
"   open outline             : Opens outline view
"   open terminal            : Opens terminal view
"   open browser google.com  : Opens browser view to google.com
"   open quickfix            : Opens quickfix view
"   open location            : Opens location view
"   open help foo            : Opens help view to subject foo
"   open git :head           : Opens git view to HEAD revision
"   open diff foo            : Opens diff view to diff foo
"   open split /bar/foo      : Opens split view to file /bar/foo
"   open split :test         : Opens test file in split view
"   open split :h            : Opens h file assoc c in split view
"   open mirror              : Opens mirror view
"
"  sessions:
"   open session foo         : Open session named foo
"
"  tabs:
"   open tab /bar/foo        : As above but opens in tab view
"
"  defaults/keywords:
"   open                     : Open file explorer at current dir
"   open google.com          : Opens browser to url google.com (based on .com)
"   open foo                 : Opens explorer if foo is dir else opens as file
"   open /bar/foo            : Opens file /foo/bar
"   open :test               : Opens test file assoc with cur
"   open :src                : Opens src file assoc with cur
"   open :c                  : Open c file assoc h or test file
"   open :test/              : Open explorer to project test dir
"   open :src/               : Open explorer to project src dir
"   open :head               : Opens git view to HEAD revision
"   open :review             : Opens browser to default review id
"   open :review 55555       : Opens browser to review id 55555
"   open :bug                : Opens browser to default bug id
"   open :bug 55555          : Opens browser to bug id 55555
"   open :report build       : Opens browser to report for last build
"   open :report test        : Opens browser to report for last test
"   open :report coverage    : Opens browser to report for last test coverage
"
"  external files:
"   eopen :mirror            : Opens readonly mirror in external window
"   eopen foo                : Opens foo file in external window
"   eopen :test              : Opens test file in external window
"
" The scope argument is used to control whether the open is performed locally or
" externally. If external is used, then if already running in gvim then a
" separate gvim window is opened. If gvim is not used (e.g. when running vim
" inside a terminal window) then tmux is used. In this case, files are opened
" in the window named in the 'g:ide_tmux_win_vim' variable using the current
" tmux session info.
"
" Args:
"   scope: 'local' or 'external'. Opening external windows only works for some
"     targets (terminal, browser, diff, review, bug, file and mirror)
"   a:*: ':buf[fers'], ':err[ors]', ':proj[ects]', ':outl[ine]',
"        ':exp[lorer]', ':ter[minal]', ':bro[wser]', ':qui[ckfix]',
"        ':loc[ation]', ':hel[p], ':dif[f], 'git', 'spl[it]', 'mirr[or],
"        ':rev[iew]', ':bug', ':rep[ort]', ':tab'
"   a:*: <file|dir|url|...>
function! g:IdeOpen(scope, ...) abort " {{{
  if a:0 == 0 || ide#util#NameRangeMatch(a:1, ":exp", ":explorer")
    call call("ide#view#OpenView", ["explorer"] + a:000[1:])
  elseif ide#util#NameRangeMatch(a:1, ":buf", ":buffers")
    call ide#view#OpenView("buffers", ".")
  elseif ide#util#NameRangeMatch(a:1, ":pro", ":projects")
    call ide#view#OpenView("projects")
  elseif ide#util#NameRangeMatch(a:1, ":out", ":outline")
    call ide#view#OpenView("outline")
  elseif ide#util#NameRangeMatch(a:1, ":ter", ":terminal")
    call ide#view#OpenView("terminal")
  elseif ide#util#NameRangeMatch(a:1, ":url", ":url") ||
      \ ide#util#NameRangeMatch(a:1, ":bro", ":browser")
    call call("g:IdeOpenUrl", a:000[1:])
  elseif ide#util#NameRangeMatch(a:1, ":rep", ":report") ||
      \ ide#util#NameRangeMatch(a:1, ":rev", ":review") ||
      \ ide#util#NameRangeMatch(a:1, ":bug", ":bug")
    call call("g:IdeOpenUrl", a:000)
  elseif ide#util#NameRangeMatch(a:1, ":qui", ":quickfix")
    call ide#view#OpenView("quickfix")
  elseif ide#util#NameRangeMatch(a:1, ":loc", ":location")
    call ide#view#OpenView("location")
  elseif ide#util#NameRangeMatch(a:1, ":hel", ":help")
    if a:0 > 1
      call ide#view#OpenView("help", a:2)
    endif
  elseif ide#util#NameRangeMatch(a:1, ":git", ":git")
    if exists("b:git_dir") && a:0 > 1 && a:2[0] ==? ":"
      let path = ide#git#GetGitRev(a:2)
      if ! empty(path)
        call ide#view#OpenView("git", path)
      endif
    endif
  elseif ide#util#NameRangeMatch(a:1, ":dif", ":diff")
    call call('g:IdeDiff', [a:scope] + a:000[1:])
  elseif ide#util#NameRangeMatch(a:1, ":spl", ":split")
    if a:0 == 1
      call ide#view#OpenView("split")
    else
      let companion = g:IdeCompanion(expand("%:p"), a:2)
      if empty(companion) && ! empty(a:2) && a:2[0] == ":"
        return ide#util#EchoError("No matching file")
      endif
      call ide#view#OpenView("split", empty(companion) ? a:2 : companion)
    endif
  elseif ide#util#NameRangeMatch(a:1, ":mir", ":mirror")
    if a:scope ==? "external"
      call g:IdeOpenExternal("-R", expand("%:p"))
    else
      call ide#view#OpenView("mirror")
    endif
  elseif ide#util#NameRangeMatch(a:1, ":ses", ":session")
    exec "OpenSession " . join(a:000[1:], "")
  elseif ide#util#NameRangeMatch(a:1, ":tab", ":tab")
    if a:0 == 1
      silent exec "tabnew"
    else
      let companion = g:IdeCompanion(expand("%:p"), a:2)
      if empty(companion) && ! empty(a:2) && a:2[0] == ":"
        return ide#util#EchoError("No matching file")
      endif
      exec "tabe " . (empty(companion) ? a:2 : companion)
    endif
  else
    if exists("b:git_dir") && a:1[0] ==? ":" && a:1 != ":h"  " :h is c code
      let arg = ide#git#GetGitRev(a:1)
      if ! empty(arg)
        return ide#view#OpenView("git", arg)
      else
        let arg = g:IdeCompanion(expand("%:p"), a:1)
      endif
    elseif a:1 ==? "%" || ide#util#NameRangeMatch(a:1, ":f", ":file")
      let arg = expand("%:p")
    elseif a:1 ==? "%/"
      let arg = expand("%:p:h")
    elseif a:1[0] ==? ":"
      let arg = g:IdeCompanion(expand("%:p"), a:1)
    else
      let arg = a:1
    endif

    if empty(arg)
      if ! empty(a:1) && a:1[0] == ":"
        return ide#util#EchoError("No matching file or dir")
      endif
      let arg = ide#util#SafeExpand(a:1)
      let args = a:000
    else
      let args = [arg]
    endif

    if a:scope ==? "external"
      return call("g:IdeOpenExternal", [arg])
    elseif arg ==? expand("%:p")
      return
    elseif ide#util#IsUrl(arg)
      call ide#view#OpenView("browser", arg)
    elseif ide#util#IsDir(arg)
      call ide#view#OpenView("explorer", arg)
    else
      " Multiple can be passed like ':open foo -R bar' where -R means readonly
      let ronly = 0
      for arg in args
        if arg == '||'
          " Special case for when command passed over tmux and vim already open
          " (e.g. :open foo || vim --server vim_2 foo)
          break
        elseif arg == '-R' || arg == '-r'
          let ronly = 1
        elseif ! bufexists(arg)
          if ronly
            silent exec "view " . arg
          else
            silent exec "edit " . arg
          endif
        else
          silent exec "edit " . arg
        endif
      endfor
    endif
  endif
endfunction " }}}

function! g:IdeOpenExternal(...) abort " {{{
  " Open as server so always use the same window
  let args = ""
  for arg in a:000
    if len(arg[0]) > 0 && arg[0] == '-'
      let args = args . " " . arg
    elseif bufexists(arg)
      let args = args . " -R " . fnamemodify(arg, ":p")
    else
      let args = args . " " . fnamemodify(arg, ":p")
    endif
  endfor

  if has("gui_running")
    silent exec "!gvim " . args
  else
    call g:IdeTmuxInit()

    " Since we may already have an active session, open the file using
    "   :open foo || vim --servername xxx_2 foo
    " This way the vim command can run, but if not in vim then bash will
    " fail and then run the vim bash command to startup
    let cmd = ":open " . args . " &> /dev/null " .
        \ " || vim --servername " . g:ide_tmux_session . "_2 " . args

    call g:IdeWin("external", g:ide_tmux_win_vim)
    call ide#tmux#Send(
        \ cmd . "\n",
        \ ide#tmux#GetSession() . ":" . g:ide_tmux_win_vim)
  endif
endfunction " }}}

function! g:IdeOpenUrl(...) abort " {{{
  if a:0 == 0
    let url = ""
  elseif ide#util#NameRangeMatch(a:1, ":rep", ":report")
    let url = g:IdeGetUrl([":report"] + a:000[1:])
    if empty(url)
      return ide#util#EchoError("No report page found")
    endif
  elseif ide#util#NameRangeMatch(a:1, ":rev", ":review")
    let url = g:IdeGetUrl([":review"] + a:000[1:])
    if empty(url)
      return ide#util#EchoError("No review page found")
    endif
  elseif ide#util#NameRangeMatch(a:1, ":b", ":bug")
    let url = g:IdeGetUrl([":bug"] + a:000[1:])
    if empty(url)
      return ide#util#EchoError("No bug page found")
    endif
  else
    let url = join(a:000, " ")
  endif

  call call("ide#view#OpenView", ["browser", url])
endfunction " }}}


" Overrides the VIM close command to allow closing views/sessions.
"
" Examples:
"   close                    : Default close behavior
"   close :buffers           : Closes buffers view
"   close :projects          : Closes projects view
"   close :explorer          : Closes explorer view
"   close :outline           : Closes outline view
"   close :terminal          : Closes terminal view
"   close :browser           : Closes browser view
"   close :quickfix          : Closes quickfix view
"   close :location          : Closes location view
"   close :help              : Closes help view
"   close :git               : Closes git view
"   close :diff              : Closes diff view
"   close :split             : Closes split view
"   close :mirror            : Closes mirror view
"   close :session           : Closes session
"
" Args:
"   a:1: 'expl[orer]', 'outl[ine]', 'term[inal]', 'quic[kfix]', 'loc[ation]',
"     'help', 'brow[ser]', 'spli[t]', 'mirr[or]', 'session'
function! g:IdeClose(...) abort " {{{
  if a:0 == 0
    exec "close"
  elseif ide#util#NameRangeMatch(a:1, ":pro", ":projects")
    call ide#view#CloseView("projects")
  elseif ide#util#NameRangeMatch(a:1, ":exp", ":explorer")
    call ide#view#CloseView("explorer")
  elseif ide#util#NameRangeMatch(a:1, ":buf", ":buffers")
    call ide#view#CloseView("buffers")
  elseif ide#util#NameRangeMatch(a:1, ":out", ":outline")
    call ide#view#CloseView("outline")
  elseif ide#util#NameRangeMatch(a:1, ":ter", ":terminal")
    call ide#view#CloseView("terminal", 1)
  elseif ide#util#NameRangeMatch(a:1, ":bro", ":browser")
    call ide#view#CloseView("browser", 1)
  elseif ide#util#NameRangeMatch(a:1, ":qui", ":quickfix")
    call ide#view#CloseView("quickfix")
  elseif ide#util#NameRangeMatch(a:1, ":loc", ":location")
    call ide#view#CloseView("location")
  elseif ide#util#NameRangeMatch(a:1, ":hel", ":help")
    call ide#view#CloseView("help")
  elseif ide#util#NameRangeMatch(a:1, ":git", ":git")
    call ide#view#CloseView("git")
  elseif ide#util#NameRangeMatch(a:1, ":dif", ":diff")
    call ide#view#CloseView("diff")
  elseif ide#util#NameRangeMatch(a:1, ":spl", ":split")
    call ide#view#CloseView("split")
  elseif ide#util#NameRangeMatch(a:1, ":mir", ":mirror")
    call ide#view#CloseView("mirror")
  elseif ide#util#NameRangeMatch(a:1, ":ses", ":session")
    exec "CloseSession " . join(a:000[1:], "")
  endif
endfunction " }}}


" Finds files/dirs.
"
" Examples
"   find                         : Re-run last find
"   find *.txt :project/         : Search for '*.txt' in project dirs
"   find *.txt :src/             : Search for '*.txt' in src dirs
"   find *.txt :test/            : Search for '*.txt' in test dirs
"   find *.txt .                 : Search for '*.txt' starting from cur dir
"   find .* .                    : Search for hidden files in cur dir
"   find *.txt /                 : Search for '*.txt' starting from root dir
"   find *.txt /foo depth 3      : Search for '*.txt' at /foo to depth of 3
"   find *.txt mtime -7d         : Search for '*.txt' modified in last 7 days
"   find *.txt /foo newer foo.x  : Search for '*.txt' newer than foo.x
"   find *.txt grep hi bob       : Search for '*.txt' with 'hi bob' in them
"   find foo type f              : Find only files with names foo
"   find foo type d              : Find only dirs with names foo
"   find foo type l              : Find only softlinks with names foo
"   find foo                     : Find files/dirs/links with names foo
"
" Args:
"   a:*: pattern: glob to search for.
"        start_dir: ':project/', ':src/', ':test/', <start_path>,
"        flags: depth, mtime, newer, ...
function! g:IdeFind(...) abort " {{{
  if a:0 == 0
    " Re-use previous find
    if len(s:last_find_results) > 0
      call ide#util#ChooseFile(
        \ "file_list", g:ide_list_view_pos, g:ide_list_view_size,
        \ s:last_find_results[0], s:last_find_results[1], "g:IdeFileChosenCb")
    elseif !empty(s:last_find)
      exec "Find " . join(a:000, " ")
    endif
    return
  endif

  let s:last_find = a:000

  " Special case where unix find called directly
  if a:1[0] ==? "-"
    let matches = ide#util#FindFiles(
      \ g:IdeSrcDirs(expand("%:p")), join(a:000, ""))
    if len(matches) == 0
      return []
    else
      let base = ide#util#GetCommonPath(matches+[<SID>GetDefaultBaseDir()])
      if base ==? "/" | let base = "" | endif
      let results = [base, ide#util#RemoveCommonPath(base, matches)]
    endif
  else
    let results = g:IdeFindFiles(a:1, a:000[1:])
  endif

  if len(results) == 0
    return ide#util#EchoError("No files found")
  else
    let s:last_find_results = results
    call ide#util#ChooseFile(
      \ "file_list", g:ide_list_view_pos, g:ide_list_view_size,
      \ results[0], results[1], "g:IdeFileChosenCb")
  endif
endfunction " }}}


" Finds files.
"
" See g:IdeFind for examples.
"
" Args:
"   file_pat: Pattern (glob) to search for.
"   search_args: List of additional option args:
"     ':project/', ':src/', ':test/', '.', <start_path>
"     depth, newer, mtime, ...
"
" Returns:
"   List where first entry is base path and second entry is list of found files.
"   If only one entry is found then the base path will be empty and the list
"   of files will contain only one item.
function! g:IdeFindFiles(file_pat, search_args) abort " {{{
  " Special case where dirs requested and file_pat is dir
  if len(a:search_args) == 2 && a:search_args[0] ==? "type" &&
      \ a:search_args[1] ==? "d"
    if ide#util#NameRangeMatch(a:file_pat, ":p", ":project/")
      let matches = [g:IdeProjectDir(expand("%:p"))]
    elseif ide#util#NameRangeMatch(a:file_pat, ":s", ":src/")
      let matches = g:IdeSrcDirs(expand("%:p"))
    elseif ide#util#NameRangeMatch(a:file_pat, ":t", ":test/")
      let matches = g:IdeTestDirs(expand("%:p"))
    endif
  endif

  if !exists("matches")
    let idx = 0
    " No args, or all args are flags
    if len(a:search_args) == 0 || len(a:search_args) % 2 == 0
      let src_dirs = g:IdeSrcDirs(expand("%:p"))
      let test_dirs = g:IdeTestDirs(expand("%:p"))
      if src_dirs == test_dirs
        let default_dirs = src_dirs
      else
        let default_dirs = src_dirs + test_dirs
      endif
    elseif ide#util#NameRangeMatch(a:search_args[0], ":p", ":project/")
      let default_dirs = [g:IdeProjectDir(expand("%:p"))]
      let idx += 1
    elseif ide#util#NameRangeMatch(a:search_args[0], ":s", ":src/")
      let default_dirs = g:IdeSrcDirs(expand("%:p"))
      let idx += 1
    elseif ide#util#NameRangeMatch(a:search_args[0], ":t", ":test/")
      let default_dirs = g:IdeTestDirs(expand("%:p"))
      let idx += 1
    else
      let default_dirs = [<SID>GetDefaultBaseDir()]
    endif

    let matches = call(
      \ "ide#util#FindFiles", [default_dirs, a:file_pat] + a:search_args[idx :])
  endif

  if len(matches) == 0
    return []
  else
    let base = ide#util#GetCommonPath(matches)
    if base ==? "/" | let base = "" | endif
    return [base, ide#util#RemoveCommonPath(base, matches)]
  endif
endfunction " }}}


" Callback for when file chosen from temp window.
function! g:IdeFileChosenCb(action, file_name) abort " {{{
  if a:action ==# 't'
    exec "tabe " . a:file_name
  elseif a:action ==# 's'
    call ide#view#OpenView("split", a:file_name)
  elseif a:action ==# 'e'
    if ide#util#IsDir(a:file_name)
      call ide#view#OpenView("explorer", a:file_name)
    else
      exec "edit " . a:file_name
    endif
  elseif a:action ==# 'E'
    if ide#util#IsDir(a:file_name)
      call ide#view#OpenView("explorer", a:file_name)
    else
      return call("g:IdeOpenExternal", [a:file_name])
    endif
  elseif a:action ==# 'd'
    call ide#view#OpenView("diff", a:file_name)
  elseif a:action ==# 'D'
    silent exec "!gvimdiff -R " . expand("%") . " " . a:file_name
  endif
endfunction " }}}


" Greps for pattern in directories specified by the optional args.
"
" If no pattern argument is provided then the last search is reused. If no
" directory argument is provided, then the current project src/test dir is
" assumed.
"
" Examples:
"   grep                      : Re-runs previous grep
"   grep foo                  : Search src/test files for 'foo'
"   grep foo :project/        : As above
"   grep foo :src/            : Search project source files for 'foo'
"   grep foo :test/           : Search project test files for 'foo'
"   grep foo .                : Search current dirs files for 'foo'
"   grep foo /bar             : Search /bar dirs files for 'foo'
"
" Args:
"   a:1: Search pattern.
"   a:2: Directory.
function! g:IdeGrep(...) abort " {{{
  if a:0 == 0
    " Re-use previous search
    if len(s:last_grep_results) > 0
      call setloclist(0, s:last_grep_results)
      call ide#view#OpenView("location")
    elseif !empty(s:last_grep)
      exec "Grep " . join(a:000, " ")
    endif
    return
  endif

  let s:last_grep = a:000
  let s:last_grep_results = []

  if a:0 > 1 && ide#util#NameRangeMatch(a:2, ":g", ":git/")
    silent exec "Glgrep " . shellescape(a:1)
  else
    let dirs = []
    if a:0 == 1
      let src_dirs = g:IdeSrcDirs(expand("%:p"))
      let test_dirs = g:IdeTestDirs(expand("%:p"))
      if src_dirs == test_dirs
        let combined_dirs = src_dirs
      else
        let combined_dirs = src_dirs + test_dirs
      endif
      for dir in combined_dirs
        call add(dirs, dir)
      endfor
    elseif ide#util#NameRangeMatch(a:2, ":s", ":src/")
      for dir in g:IdeSrcDirs(expand("%:p"))
        call add(dirs, dir)
      endfor
    elseif ide#util#NameRangeMatch(a:2, ":p", ":project/")
      call add(dirs, g:IdeProjectDir(expand("%:p")))
    elseif ide#util#NameRangeMatch(a:2, ":t", ":test/")
      for dir in g:IdeTestDirs(expand("%:p"))
        call add(dirs, dir)
      endfor
    elseif ide#util#NameRangeMatch(a:2, ":%/", ":%/")
      call add(dirs, expand("%:p:h"))
    else
      for dir in a:000[1:]
        call add(dirs, dir[-1] == "/" ? dir . '*' : dir)
      endfor
    endif

    let result = system("grep -nIR " . shellescape(a:1) . " " . join(dirs, " "))
    if empty(result) || result ==? "\n"
      return ide#util#EchoError("No results found")
    endif

    call setloclist(0, ide#util#MakeLocationList(split(result, "\n"), 0))
  endif

  let s:last_grep_results = getloclist(0)
  if len(s:last_grep_results) > 0
    call ide#view#OpenView("location")
  endif
endfunction " }}}


" Googles for tag words.
"
" The special keywords :f[iletype] and :s[tackoverflow] can be used in place
" of the current file type and the name 'stackoverflow'.
"
" Examples:
"   google foo                : Opens browser to google 'foo'
"   google foo :f             : Opens browser to google 'foo <filetype>'
"   google foo :s             : Opens browser to google 'foo stackoverflow'
"
" Args:
"   a:*: Tag words
function! g:IdeGoogle(...) abort " {{{
  if a:0 == 0
    " Re-use previous google
    if empty(s:last_google)
      exec "Google " . join(a:000, " ")
    endif
    return
  endif

  let s:last_google = a:000

  let words = []
  for word in a:000
    if ide#util#NameRangeMatch(word, ":f", ":filetype")
      call add(words, &filetype)
    elseif ide#util#NameRangeMatch(word, ":s", ":stackoverflow")
      call add(words, 'stackoverflow')
    else
      call add(words, substitute(word, " ", "+", "g"))
    endif
  endfor

  let url = "google.com/search?q=" . join(words, "+")
  call ide#view#OpenView("browser", url)
endfunction " }}}


" Help (special case of open for compatibilty with VIM).
"
" Args:
"   a:1: Optional help subject (defaults to word under cursor)
function! g:IdeHelp(...) abort " {{{
  if a:0 > 0
    call ide#view#OpenView('help', a:1)
  else
    call ide#view#OpenView('help', expand("<cWORD>"))
  endif
endfunction " }}}


" Diffs files including git revisions.
"
" The first vararg parameter contains the git revision or filename. The
" following names have special meanings:
"
"   :saved              : Diff saved changes
"   :staged             : Diff current with staged changes
"   :<rev>              : Diff git rev # (e.g diff :v1.1)
"
" If no arguments are passed then the last diff is re-run.
"
" The scope argument is used to control whether the open is performed locally or
" in a new external window. If an external window is used, then more than one
" filename may be passed as varargs. When only one filename is passed then it is
" diffed against the currently open file, otherwise the diff is against the
" files passed.
"
" Examples:
"   diff :saved          : Diff against last save
"   diff :staged         : Diff against staged changes in git
"   diff :head           : Diff against head version of file in git
"   diff /bar/foo        : Diff against file /var/foo
"   ediff :staged :head  : Diff staged chagnes in git againt head changes
"   ediff foo bar        : Diff files foo and bar
"
" Args:
"   scope: 'local' or 'external'.
"   a:1: Keyword (saved, ...) or file name
"   a:2: Keyword (saved, ...) or file name (only if external used)
function! g:IdeDiff(scope, ...)
  if a:0 == 0
    " Re-use previous diff
    if a:scope ==? "external" && !empty(s:last_ediff)
      exec "EDiff " . join(a:000, " ")
    elseif a:scope !=? "external" && !empty(s:last_diff)
      exec "Diff " . join(a:000, " ")
    endif
    return
  endif

  let paths = []
  for path in a:000
    if ide#util#NameRangeMatch(path, ":saved", ":saved")
      if a:scope ==? "external"
        " All external diffs are with last saved
        call add(paths, expand("%:p"))
      else
        return ide#view#OpenView("diff")
      endif
    elseif path[0] ==? ":"
      let p = ide#git#GetGitRev(path, expand("%:p"))
      if empty(p)
        return ide#util#EchoError("GIT revision not found: " . path[1:])
      else
        call add(paths, p)
      endif
    else
      call add(paths, path)
    endif
  endfor

  if a:scope ==? "external" && len(paths) == 1
    let diff_args = expand("%:p") . " " . paths[0]
  else
    let diff_args = join(paths, " ")
  endif

  if a:scope ==? "external" || len(paths) > 1
    let s:last_ediff = a:000
    silent exec "!gvimdiff -R " . diff_args
  else
    let s:last_diff = a:000
    call ide#view#OpenView("diff", diff_args)
  endif
endfunction


" Git.
"
" This wraps the vim-fugative wrapper and in some cases replaces the
" implementation with a IDE specific verison. Operations involving the
" current file can either pass '%' or can pass nothing at all and the
" filename will automatically be added to the command. Unlike git itself,
" the current file is always the default for operations. If the desire is
" to run git accross all files in the repository, then the 'all' keyword
" should be used (e.g. 'git log' works on file while 'git log all' works
" on repo).
"
" Examples:
"   git status
"   git log
"   git log all
"   git commit
"   git read :head
"   git write
"   git mv new_name
"   git rm
"   git blame
"
" Args:
"   cmd: Git command.
"   a:*: Git command args.
function! g:IdeGit(cmd, ...)
  if ! exists("b:git_dir")
    return ide#util#EchoError("Git repo not found")
  endif

  call call("ide#view#OpenView", ['git', a:cmd] + a:000)
endfunction " }}}


" Displays file/command/search/... history
"
" Examples:
"   history command
"   history search
"   history file
function! g:IdeHistory(...)
  if a:0 > 0 && (ide#util#NameRangeMatch(a:1, "f", "file") || a:1 ==? "%")
    if ide#plugin#PluginExists("eclim")
      call ide#eclim#History()
    endif
  else
    exec "history " . join(a:000, " ")
  endif
endfunction " }}}


" Clears quickfix list, location list, signs, file history, grep, find, ...
"
" Examples:
"   clear               # location list, quickfix list, signs
"   clear :quickfix
"   clear :loc
"   clear :sign
"   clear :history file
"   clear :grep
"   clear :find
"   clear :errors
"   clear :lint
"   clear :build
"   clear :test
"   clear :coverage
function! g:IdeClear(...)
  if a:0 > 0 && ide#util#NameRangeMatch(a:1, ":q", ":quickfix")
    call setqflist([])
    call ide#view#CloseView("quickfix")
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":l", ":location")
    call setloclist(winnr(), [])
    call ide#view#CloseView("location")
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":s", ":sign")
    exec "sign unplace *"
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":h", ":history")
    if a:0 > 1 && (ide#util#NameRangeMatch(a:2, "f", "file") || a:2 ==? "%") &&
        / ide#plugin#PluginExists("eclim")
      call ide#eclim#History("clear")
    endif
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":search", ":search")
    let s:last_search_results = []
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":e", ":errors")
    call setloclist(winnr(), [])
    exec "sign unplace *"
    call ide#view#CloseView("location")
    let s:last_errors = []
    let s:last_lint_errors = []
    let s:last_build_errors = []
    let s:last_coverage_errors = []
    let s:last_test_errors = []
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":g", ":grep")
    let s:last_grep_results = []
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":l", ":lint")
    let s:last_lint_results = []
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":b", ":build")
    let s:last_build_results = []
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":t", ":test")
    let s:last_test_results = []
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":c", ":coverage")
    let s:last_coverage_results = []
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":f", ":find")
    let s:last_find_results = []
  else
    call setqflist([])
    call setloclist(winnr(), [])
    exec "sign unplace *"
    call ide#view#CloseView("quickfix")
    call ide#view#CloseView("location")
  endif
endfunction " }}}


" Refreshes output for find/grep/diff/lint/build/test/...
"
" Examples:
"   refresh :find
"   refresh :grep
"   refresh :diff
"   refresh :errors
"   refresh :lint
"   refresh :build
"   refresh :test
"   refresh :coverage
function! g:IdeRefresh()
  if a:0 > 0 && ide#util#NameRangeMatch(a:1, ":e", ":errors")
    let s:last_build_errors = []
    let s:last_lint_errors = []
    let s:last_test_errors = []
    let s:last_coverage_errors = []
    if len(s:last_errors) > 0
      call g:IdeErrors(join(s:last_errors, " "))
    endif
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":b", ":build")
    let s:last_build_errors = []
    call g:IdeErrors(":build")
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":l", ":lint")
    let s:last_lint_errors = []
    call g:IdeErrors(":lint")
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":t", ":test")
    let s:last_test_errors = []
    call g:IdeErrors(":test")
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":c", ":coverage")
    let s:last_coverage_errors = []
    call g:IdeErrors(":coverage")
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":g", ":grep")
    let s:last_grep_results = []
    if len(s:last_grep) > 0
      exec "Grep " . join(s:last_grep, " ")
    endif
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":s", ":search")
    let s:last_search_results = []
    if len(s:last_search) > 0
      exec "Search " . join(s:last_search, " ")
    endif
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":f", ":find")
    let s:last_find_results = []
    if len(s:last_find) > 0
      exec "Find " . join(s:last_find, " ")
    endif
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":d", ":diff")
    if len(s:last_diff) > 0
      exec "Diff " . join(s:last_diff, " ")
    endif
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, ":e", ":ediff")
    if len(s:last_ediff) > 0
      exec "EDiff " . join(s:last_ediff, " ")
    endif
  endif
endfunction " }}}


" Resets all settings.
function! g:IdeReset()
  call ide#util#SetWinPosition()
  call ide#util#SetWinDimensions()
endfunction " }}}


" Save session.
function! g:IdeSave(...)
  if a:0 > 0 && ide#util#NameRangeMatch(a:1, ":sess", ":session")
    if a:0 == 1 && g:IdeCmdHandler('project') == "projux"
      exec "SaveSession " . ide#projux#ProjectName()
    elseif a:0 > 1
      exec "SaveSession " . a:2
    else
      :SaveSession
    endif
  endif
endfunction " }}}


" Rm session.
function! g:IdeRm()
  if a:0 > 0 && ide#util#NameRangeMatch(a:1, "sess", "session")
    if a:0 == 1 && g:IdeCmdHandler('project') == "projux"
      exec "DeleteSession " . ide#projux#ProjectName()
    elseif a:0 > 1
      exec "DeleteSession " . a:2
    else
      :DeleteSession
    endif
  endif
endfunction " }}}


" Attaches external window to gvim.
"
" Args:
"   target: 'browser', 'terminal'
"   a:1: 'any' to attach any term/browser even if not opened by gvim
function! g:IdeAttach(target, ...)
  let any = a:0 > 0 ? ide#util#NameRangeMatch(a:1, "a", "any") : 0
  if ide#util#NameRangeMatch(a:target, "b", "browser")
    call ide#mac#PositionBrowserRelativeToMacVim(g:ide_browser_view_pos, any)
  elseif ide#util#NameRangeMatch(a:target, "te", "terminal")
    call ide#mac#PositionTerminalRelativeToMacVim(g:ide_terminal_view_pos, any)
  endif
endfunction " }}}


" Detaches external window from gvim.
"
" Args:
"   target: 'browser', 'terminal'
function! g:IdeDettach(target, ...)
  if ide#util#NameRangeMatch(a:target, "b", "browser")
    call ide#mac#DetachTerminal()
  elseif ide#util#NameRangeMatch(a:target, "t", "terminal")
    call ide#mac#DetachBrowser()
  endif
endfunction " }}}


" Init tmux.
function! g:IdeTmuxInit(...) abort " {{{
  let handler = g:IdeCmdHandler('project')
  if handler == 'projux'
    call call("ide#projux#Init", a:000)
  endif

  " Default tmux settings
  if !exists("g:ide_tmux_host")
    let g:ide_tmux_host = "localhost"
  endif
  if !exists("g:ide_tmux_session")
    let g:ide_tmux_session = "default"
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


" Tmux commands
"
" Tmux commands are sent to the window named in the 'g:ide_tmux_win_shell'
" variable using the current tmux session info.
function! g:IdeTmux(...)
  call g:IdeTmuxInit()

  if a:0 > 0 && ide#util#NameRangeMatch(a:1, "se", "send")
    call ide#tmux#Send(
        \ join(a:000[1:], " "),
        \ ide#tmux#GetSession() . ":" . g:ide_tmux_win_shell)
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, "sh", "shell")
    let session = ide#tmux#GetOppositeSession()
    try
      while 1
        let cmd = input("$ ")
        call ide#tmux#Send(cmd . "\n", session)
      endwhile
    catch
    endtry
    let cmd = input("")
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, "sh", "show")
    echom "Host: " . ide#tmux#GetHost()
    echom "Session: " . ide#tmux#GetSession()
  elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, "c", "config")
    call call("ide#tmux#SetHost", a:000[1:])
    call call("ide#tmux#SetSession", a:000[2:])
  endif
endfunction " }}}


" Switch tmux windows.
"
" This function is used with the 'win' and 'ewin' commands to switch tmux
" windows. The scope of the command can be local (the tmux window associated
" with the current vim session) or external (the tmux window configured using
" g:ide_tmux_host and g:ide_tmux_session variables).
"
" Examples:
"   :win             - show local tmux window
"   :win bash        - switch local window to use bash
"   :ewin            - show external tmux window
"   :ewin bash       - switch external window to use bash
"
" Args:
"   scope: 'local' or 'external'
"   win: Name of window to switch to.
function! g:IdeWin(scope, ...) abort " {{{
  call g:IdeTmuxInit()

  if a:0 > 0 && a:1 ==? "ls"
    if a:scope ==? "local"
      let names = ide#tmux#GetWindowNames()
    else
      let names = ide#tmux#GetWindowNames(ide#tmux#GetOppositeSession())
    endif
    for name in names
      echom name
    endfor
  elseif a:0 == 0
    let win = ide#tmux#CurWindow()
    if ! empty(win)
      echom win
    endif
  else
    if a:scope ==? "local"
      call ide#tmux#SelectWindow(join(a:000, " "), g:ide_tmux_session)
    else
      call ide#tmux#SelectWindow(
         \ join(a:000, " "), ide#tmux#GetOppositeSession())
    endif
  endif
endfunction " }}}


" Lists buffers.
"
" Buffers can be opened with e/E (edit), s (split), t(tab), d/D (diff).
" They can be deleted with x (delete).
"
" Args:
"   a:1: Default action on enter.
function! g:IdeBuffers(...)
  return call("ide#util#ChooseBuffer",[
    \ 0, "buffer_list", g:ide_list_view_pos, g:ide_list_view_size,
    \ "ide#view#BufferChosenCb"] + a:000)
endfunction " }}}


" Invokes plugin related utils.
"
" Examples:
"   plugin ls               : List plugins
"   plugin update foo       : Updates foo plugin
"   plugin update all       : Updates all plugins
"   plugin disable foo      : Disables foo plugin
"   plugin enable foo       : Enables foo plugin
"
" Args:
"   op: 'list/ls', 'update {all}'
function! g:IdePlugin(op, ...)
  if ide#util#NameRangeMatch(a:op, "l", "ls") ||
      \ ide#util#NameRangeMatch(a:op, "l", "list")
    for plugin in ide#plugin#GetPlugins()
      echomsg plugin
    endfor
  elseif ide#util#NameRangeMatch(a:op, "u", "update") && a:0 > 0
    call ide#plugin#UpdatePlugin(a:1)
  elseif ide#util#NameRangeMatch(a:op, "e", "enable") && a:0 > 0
    call ide#plugin#EnablePlugin(a:1)
  elseif ide#util#NameRangeMatch(a:op, "d", "disable") && a:0 > 0
    call ide#plugin#DisablePlugin(a:1)
  elseif a:op ==? "eclim"
    call call("ide#eclim#Cmd", a:000)
  endif
endfunction " }}}


" Completion support for plugin commands.
"
" This function is used in the -complete attribute for a command:
"   command -nargs=* -complete=customlist,g:IdePluginComplete Docs :call ...
function! g:IdePluginComplete(argLead, cmdLine, cursorPos)
  let arg_count = len(substitute(a:cmdLine, "[^ ]", "", "g"))
  if arg_count == 1
    return filter(
      \ ['disable', 'enable', 'list', 'update'],
      \ 'v:val =~ "^' . a:argLead . '"')
  elseif arg_count == 2 && split(a:cmdLine, " ")[1] !=? "list"
    return filter(ide#plugin#GetPlugins(), 'v:val =~ "^' . a:argLead . '"')
  endif
  return []
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Project related function implementations.
"
" Where appropriate, these functions should be overridden within .vimrc or by
" filetype specific implementations. For example, the java specific build
" implementation would be provided by a g:IdeBuild specification in
" ftplugin/java.vim.
"
" NOTE: Here filetype specific configuration are placed inline of the functions
"       and not in ftdetect in order to make it easier to override from
"       .vimrc, etc
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Returns directory of project associated with current file or directory.
"
" This function is used within commands such as 'find', etc. to scope the
" directories used with the commands.
"
" This function may be overriden by a filetype specific setting. A default
" implementation is available as g:IdeDefaultProjectDir.
"
" Args:
"   cur: Current file or directory in use.
if !exists("*g:IdeProjectDir")
  function! g:IdeProjectDir(cur) abort " {{{
    return g:IdeDefaultProjectDir(a:cur)
  endfunction " }}}
endif

" Default project dir implementation.
"
" If projux set for the project, then  $PROJECT_DIR env variable is used, else
" it looks for a workspace directory (as configured by g:ide_workspace) in
" the path. If no project directory is found then the current dir is used.
function! g:IdeDefaultProjectDir(cur)
  " Filetype specific implementations
  if &filetype ==? "java" || &filetype ==? "scala"
    let paths = ide#util#SplitPath(a:cur, ['src', 'test'])
    if len(paths) == 0
      echom "Project dir not found for " . a:cur
    else
      return paths[0]
    endif
  endif

  " Default implementation
  if g:IdeCmdHandler('project') == 'projux'
    return ide#projux#ProjectDir()
  else
    let dir_name = ide#util#Dirname(a:cur)
    let dir_names = split(dir_name, "/")

    if len(dir_names) > 1
      for offset in range(2, len(dir_names))
        let cur_dir = dir_names[len(dir_names) - offset]
        if empty(g:ide_workspace)
          if cur_dir ==? "workspace" || cur_dir ==? "work" ||
              \ cur_dir ==? "source"
            return "/" . join(dir_names[:len(dir_names) - offset + 1], "/")
          endif
        else
          if cur_dir ==? g:ide_workspace
            return "/" . join(dir_names[:len(dir_names) - offset + 1], "/")
          endif
        endif
      endfor
    endif

    return ide#util#Dirname(a:cur)
  endif
endfunction " }}}


" Returns src directories of project associated with current file or directory.
"
" This function is used within commands such as 'open', 'find', etc. to
" scope the directories used with the commands.
"
" This function may be overriden by a filetype specific setting. A default
" implementation is available as g:IdeDefaultSrcDirs.

" Args:
"   cur: Current file or directory in use.
if !exists("*g:IdeSrcDirs")
  function! g:IdeSrcDirs(cur) abort " {{{
    return g:IdeDefaultSrcDirs(a:cur)
  endfunction " }}}
endif

" Default project src dirs implementation.
"
" If projux set for the project, then  $PROJECT_SRC_DIR env variable is used,
" else it looks for a workspace directory (as configured by g:ide_workspace) in
" the path. If no project directory is found then the current dir is used.
function! g:IdeDefaultSrcDirs(cur)
  " Filetype specific implementations
  if &filetype ==? "java" || &filetype ==? "scala"
    let paths = ide#util#SplitPath(a:cur, ['src', 'test'])
    if len(paths) == 0
      return []
    else
      return [paths[0] . '/src']
    endif
  endif

  " Default implementation
  if ! exists("s:src_dirs")
    if g:IdeCmdHandler('project') == 'projux'
      let s:src_dirs = ide#projux#ProjectSrcDirs()
    else
      let s:src_dirs = [ide#util#Dirname(a:cur)]
    endif
  endif
  return s:src_dirs
endfunction " }}}


" Returns test directories of project associated with current file or directory.
"
" This function is used within commands such as 'open', 'find', etc. to
" scope the directories used with the commands.
"
" This function may be overriden by a filetype specific setting. A default
" implementation is available as g:IdeDefaultTestDirs.
"
" Args:
"   cur: Current file or directory in use.
if !exists("*g:IdeTestDirs")
  function! g:IdeTestDirs(cur) abort " {{{
    return g:IdeDefaultTestDirs(a:cur)
  endfunction " }}}
endif

" Default project test dirs implementation.
"
" If projux set for the project, then  $PROJECT_TEST_DIR env variable is used,
" else it looks for a workspace directory (as configured by g:ide_workspace) in
" the path. If no project directory is found then the current dir is used.
function! g:IdeDefaultTestDirs(cur)
  " Filetype specific implementations
  if &filetype ==? "java" || &filetype ==? "scala"
    let paths = ide#util#SplitPath(a:cur, ['src', 'test'])
    if len(paths) == 0
      return []
    else
      return [paths[0] . '/test']
    endif
  endif

  " Default implementation
  if ! exists("s:test_dirs")
    if g:IdeCmdHandler('project') == 'projux'
      let s:test_dirs = ide#projux#ProjectTestDirs()
    else
      let s:test_dirs = [ide#util#Dirname(a:cur)]
    endif
  endif
  return s:test_dirs
endfunction " }}}


" Gets companion file or directory.
"
" This function is used within the 'open' command to find the companion files
" (foo.h vs foo.c, Foo.java vs FooTest.java, etc). For example:
"   :open split :test
"   :open split :src
"   :open split :h
"   :open split :c
"
" A companion file is either an 'alternate' for a file (e.g. .h vs .c, etc) or a
" 'test' for a file (e.g. 'Foo.java' vs 'FooTest.java', etc).
"
" Most source files will provide their own filetype specific implementation in
" vim-ide/ftplugin/<type>.vim. A default implementation is available as
" g:IdeDefaultCompanion.
"
" Examples:
"   IdeCompanion('/foo/src/Bar.java', ':test')      : /foo/test/BarTest.java
"   IdeCompanion('/foo/test/BarTest.java', ':src')  : /foo/src/Bar.java
"   IdeCompanion('/foo/src/', ':test')              : /foo/test/
"   IdeCompanion('/foo/bar.py', ':test')            : /foo/bar_test.py
"   IdeCompanion('/foo/bar.c', ':h')                : /foo/bar.h
"   IdeCompanion('/foo/bar.c', ':test')             : /foo/bar_test.c
"
" Args:
"   cur: Current file or directory in use.
"   a:1: Keyword of companion to return (':test', ':src', ':c', ':h', ':scala',
"     etc). If this parameter is not provided then the default companion should
"     be returned.
"
" Returns:
"   Companion file associated with cur file or directory in use or '' if no
"   companion exists. If returned, the companion file or directory must exist.
if !exists("*g:IdeCompanion")
  function! g:IdeCompanion(cur, ...)
    return call("g:IdeDefaultCompanion", [a:cur] + a:000)
  endfunction " }}}
endif

" Default companion implementation
"
" The default implementation supports matching test files that are distinguished
" by _test in the name (e.g. foo.ext vs foo_test.ext).
function! g:IdeDefaultCompanion(cur, ...)
  if a:0 > 0 && a:1 == ":project/"
    return g:IdeProjectDir(a:cur)
  endif

  " Filetype specific implementations
  if &filetype ==? "java" || &filetype ==? "scala"
    return call("g:IdeJavaScalaCompanion", [a:cur] + a:000)
  elseif &filetype ==? "c" || &filetype ==? "cpp"
    return call("g:IdeCCompanion", [a:cur] + a:000)
  endif

  " Default implementation
  if a:0 > 0
    let target = a:1
  else
    let target = ":test"
  endif

  if target == ":test/"
    return "."
  elseif target == ":src/"
    return "."
  endif

  " Assume test files for code are in same dir
  if ide#util#IsDir(a:cur) || a:0 == 1 && len(a:1) > 0 && a:1[len(a:1)-1] == "/"
    return a:cur
  endif

  let ext = substitute(a:cur, '\(.*\.\)', "", "")

  " matches .*, _test.*, _unittest.*
  let pattern = '\(\(_\(unit\)\?test\)\?\.[^.]*\)$'
  if ide#util#NameRangeMatch(target, ":t", ":test")
    let file = substitute(a:cur, pattern, "_test.", "") . ext
  elseif ide#util#NameRangeMatch(target, ":u", ":unittest")
    let file = substitute(a:cur, pattern, "_unittest.", "") . ext
  elseif ide#util#NameRangeMatch(target, ":" . ext[:3], ":" . ext) ||
      \ ide#util#NameRangeMatch(target, ":s", ":src")
    let file = substitute(a:cur, pattern, "." . ext, "")
  else
    let file = ""
  endif
  return !empty(file) && filereadable(file) ? file : ""
endfunction " }}}

function! g:IdeJavaScalaCompanion(cur, ...) abort " {{{
  if a:0 > 0
    let target = a:1
  else
    let target = ":test"
  endif

  if ide#util#NameRangeMatch(target, ":p", ":project/")
    let paths = ide#util#SplitPath(a:cur, ['src', 'test'])
    if len(paths) == 0
      return ""
    else
      return paths[0]
    endif
  elseif target == ":test/"
    let paths = ide#util#SplitPath(a:cur, ['src', 'test'])
    if len(paths) == 0
      return ""
    else
      return paths[0] . '/test'
    endif
  elseif target == ":src/"
    let paths = ide#util#SplitPath(a:cur, ['src', 'test'])
    if len(paths) == 0
      return ""
    else
      return paths[0] . '/src'
    endif
  elseif ide#util#NameRangeMatch(target, ":t", ":test")
    " matches .*, *Test.*
    let paths = ide#util#SplitPath(a:cur, ['src', 'test'])
    if len(paths) == 0
      return ""
    else
      let file = paths[0] . '/test/' .
        \ substitute(
          \ substitute(paths[1], 'Test\.', '\.', ''), '\.', 'Test\.', '')
    endif
  elseif ide#util#NameRangeMatch(target, ":j", ":java") ||
      \ ide#util#NameRangeMatch(target, ":sc", ":scala") ||
      \ ide#util#NameRangeMatch(target, ":s", ":src")
    let paths = ide#util#SplitPath(a:cur, ['src', 'test'])
    if len(paths) == 0
      return ""
    else
      let file = paths[0] . '/src/' . substitute(paths[1], 'Test\.', '\.', '')
    endif
  else
    return ""
  endif

  if filereadable(file) || isdirectory(file)
    return file
  else
    " Return test directory to choose file from
    let cur_file = substitute(file, '\(.*\/\)', "", "")
    let cur_dir = substitute(
      \ file,'\(' . substitute(cur_file, '.', '\.', '') . '\)$', "", "")
    return cur_dir[:len(cur_dir) - 2]
  endif
endfunction " }}}

function! g:IdeCCompanion(cur, ...) abort " {{{
  if a:0 > 0
    let target = a:1
  else
    let target = ":test"
  endif

  if ide#util#NameRangeMatch(target, ":p", ":project/")
    return g:IdeProjectDir()
  elseif target == ":test/"
    return "."
  elseif target == ":src/"
    return "."
  endif

  " Test files for c code are in same dir
  if ide#util#IsDir(a:cur) || a:0 == 1 && len(a:1) > 0 && a:1[len(a:1)-1] == "/"
    return a:cur
  endif

  " matches .*, _test.*, _unittest.*, -inl.*
  let pattern = '\(\(_\(unit\)\?test\)\?\.[^.]*\|\(-inl\)\?\.[^.]*\)$'
  if ide#util#NameRangeMatch(target, ":t", ":test")
    let ext = substitute(a:cur, '\(.*\.\)', "", "")
    let file = substitute(a:cur, pattern, "_test.", "") .
      \ substitute(ext, "h", "cc", "")
  elseif ide#util#NameRangeMatch(target, ":u", ":unittest")
    let ext = substitute(a:cur, '\(.*\.\)', "", "")
    let file = substitute(a:cur, pattern, "_unittest.", "") .
      \ substitute(ext, "h", "cc", "")
  elseif ide#util#NameRangeMatch(target, ":h", ":header")
    let file = substitute(a:cur, pattern, ".h", "")
  elseif ide#util#NameRangeMatch(target, ":c", ":c")
    let file = substitute(a:cur, pattern, ".c", "")
  elseif ide#util#NameRangeMatch(target, ":cc", ":cc") ||
      \ ide#util#NameRangeMatch(target, ":s", ":src")
    let file = substitute(a:cur, pattern, ".cc", "")
  elseif ide#util#NameRangeMatch(target, ":cp", ":cpp")
    let file = substitute(a:cur, pattern, ".cpp", "")
  elseif ide#util#NameRangeMatch(target, ":i", ":inl")
    let file = substitute(a:cur, pattern, "-inl.h", "")
  else
    let file = ""
  endif
  return !empty(file) && filereadable(file) ? file : ""
endfunction " }}}


" Expand targets in array.
"
" Args:
"   arr: Array of targets.
"
" Returns:
"   Array of expanded targets.
function! s:ExpandTargets(...) abort " {{{
  if a:0 == 0
    return []
  endif
  let expanded_arr = []
  for target in a:1
    " Try :src, :test, etc first
    let expanded_target = g:IdeCompanion(target)
    if empty(expanded_target)
      " Assume file or dir and replace %, %/ and/or expand full path
      let expanded_target = ide#util#ExpandKeywords([target], 1, "")[0]
    endif
    call add(expanded_arr, expanded_target)
  endfor
  return expanded_arr
endfunction " }}}


" Gets URL given type.
"
" This function is used with the 'open' command to open special keyword
" URLs.
"
" This function may be overriden by .vimrc. A default implementation is
" available as g:IdeDefaultGetUrl using projux.
"
" Args:
"   cur: Current file or directory in use.
if !exists("*g:IdeGetUrl")
  function! g:IdeGetUrl(...) abort " {{{
    return call("g:IdeDefaultGetUrl", a:000)
  endfunction " }}}
endif

" Default url implementation
function! g:IdeDefaultGetUrl(...)
  if g:IdeCmdHandler('project') == 'projux'
    return call('ide#projux#GetUrl', a:000)
  endif

  if !empty(&filetype)
    return ide#util#EchoError("GetUrl not implemented for " . &filetype)
  else
    return ide#util#EchoError("GetUrl not implemented")
  endif
endfunction " }}}


" Project.
"
" Examples:
"   project                      : Display current project
"   project <proj>               : Switch to project <proj>
"   project ls                   : List projects
"   project settings             : Show project settings
"   project refresh              : Refresh project
"
" This is intended to be overriden by specific implementation in .vimrc or
" filetype settings. The keywords used depend on the implementation. A default
" implementation is available as g:IdeDefaultProject using projux or eclim
" depending on the 'project' setting in g:ide_filetype_settings.
"
" Args:
"   a:*: keywords
if !exists("*g:IdeProject")
  function! g:IdeProject(...) abort " {{{
    return call("g:IdeDefaultProject", a:000)
  endfunction " }}}
endif

" Default project implementation.
function! g:IdeDefaultProject(...) abort " {{{
  let handler = g:IdeCmdHandler('project')
  if handler == 'projux'
    return call("ide#projux#Project", a:000)
  elseif handler == 'eclim'
    return call("ide#eclim#Project", a:000)
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Project not implemented for " . &filetype)
  else
    return ide#util#EchoError("Project not implemented")
  endif
endfunction " }}}


" Docs.
"
" Example:
"   :docs foo bar          : Search for docs with tags 'foo' and 'bar'
"
" This should be overridden by filetype specific settings. A default
" implementation is available as g:IdeDefaultDocs that supports
" java (via eclim), scala (via vim-scaladoc), and python (via pyref)
"
" Args:
"   a:*: List of  tags to search for
if !exists("*g:IdeDocs")
  function! g:IdeDocs(...) abort " {{{
    return call("g:IdeDefaultDocs", a:000)
  endfunction " }}}
endif

" Default docs implementation
"
" The default behavior is to google for the tags.
function! g:IdeDefaultDocs(...) abort " {{{
  if a:0 > 0
    let tags = join(a:000, " ")
  else
    let tags = expand("<cWORD>")
  endif

  " Filetype specific implementations
  if &filetype ==? "java"
    if ide#plugin#PluginExists("eclim")
      return call("ide#eclim#Docs", a:000)
    endif
  elseif &filetype ==? "scala"
    if ide#plugin#PluginExists("vim-scaladoc") && g:scaladoc
      call scaladoc#Search(
        \ tags, "ide#view#OpenBrowserView", "scaladoc_list",
        \ g:ide_list_view_pos, g:ide_list_view_size)
      return
    endif
  elseif &filetype ==? "python"
    if ide#plugin#PluginExists("vim-pyref") && g:loaded_pyref
      exec "PyRef " . tags
      return
    endif
  endif

  " Default implementation
  return g:IdeSearch("google", tags)
endfunction " }}}

" This function is used in the -complete attribute for the command:
"   command -nargs=* -complete=customlist,g:IdeDocsComplete Docs :call g:IdeDocs
"
" A default implementation is available as g:IdeDefaultDocsComplete.
"
" This should be overridden by filetype specific settings.
if !exists("*g:IdeDocsComplete")
  function! g:IdeDocsComplete(argLead, cmdLine, cursorPos) abort " {{{
    return g:IdeDefaultDocsComplete(a:argLead, a:cmdLine, a:cursorPos)
  endfunction " }}}
endif

" Default docs -complete implementation
function! g:IdeDefaultDocsComplete(argLead, cmdLine, cursorPos) abort " {{{
  " Filetype specific implementations
  if &filetype ==? "java"
    if ide#plugin#PluginExists("eclim")
      return call("ide#eclim#DocsComplete",
        \ a:argLead, a:cmdLine, a:cursorPos)
    endif
  elseif &filetype ==? "python"
    if ide#plugin#PluginExists("vim-pyref") && g:loaded_pyref
      return xolox#pyref#complete(a:argLead, a:cmdLine, a:cursorPos)
    endif
  endif

  return []
endfunction " }}}


" Searches for patterns in a code base.
"
" Examples:
"   search                    : Re-runs previous search
"   search -p <pat> ..        : Search eclipse using eclim pattern flags
"   search todo file          : Search file todo using eclim
"   search todo project       : Search project todo using eclim
"
" This function is available to be overridden in .vimrc. A default
" implementation is available as g:IdeDefaultSearch using projux or eclim
" depending on the 'search' setting in g:ide_filetype_settings.
if !exists("*g:IdeSearch")
  function! g:IdeSearch(...) abort " {{{
    return call("g:IdeDefaultSearch", a:000)
  endfunction " }}}
endif

" Default search implementation
"
" The default implementation uses eclim for code searching todos and patterns.
" If no argument is provided then the last search is reused.
function! g:IdeDefaultSearch(...) abort " {{{
  if a:0 == 0
    " Re-use previous search
    if !empty(s:last_search)
      exec "Search " . join(a:000, " ")
    endif
    return
  endif

  let s:last_search = a:000

  let handler = g:IdeCmdHandler('search')
  if handler == 'projux'
    return call("ide#projux#Search", a:000)
  elseif handler == 'eclim'
    return call("ide#eclim#Search", a:000)
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Search not implemented for " . &filetype)
  else
    return ide#util#EchoError("Search not implemented")
  endif
endfunction " }}}


" Search context.
"
" Searches project for code based on current position of cursor within file.
" This function may be overriden by a filetype specific setting. A default
" implementation is available as g:IdeDefaultSearchContext using projux or
" eclim depending on the 'search' setting in g:ide_filetype_settings.
"
" Args:
"   context: Word under cursor (e.g. <cWORD>).
if !exists("*g:IdeSearchContext")
  function! g:IdeSearchContext(context) abort " {{{
    return g:IdeDefaultSearchContext(a:context)
  endfunction " }}}
endif

" Default search context implementation
function! g:IdeDefaultSearchContext(context) abort " {{{
  let handler = g:IdeCmdHandler('search')
  if handler == 'projux'
    return call("ide#projux#SearchContext", a:000)
  elseif handler == 'eclim'
    return call("ide#eclim#SearchContext", a:000)
  endif

  if !empty(&filetype)
    return ide#util#EchoError("SearchContext not implemented for " . &filetype)
  else
    return ide#util#EchoError("SearchContext not implemented")
  endif
endfunction " }}}


" Format.
"
" Examples:
"   :format              : format default targets
"   :format :selected    : format selected text
"   :format :buffer      : format current buffer
"   :format :file        : format current file
"   :format .            : format targets in current dir
"   :format :project/    : format targets in current project
"
" Formats code specified by the optional args. The args supported are
" up to the the filetype specific settings to define. However, one argument
" has special meaning:
"
"    ':selected'         Used when format is called from visual mode, a motion
"                        key, or formatexpr. In this case the a:2 contains the
"                        selection mode ('v', 'V', 'char', 'line', 'block', or
"                        'expr'). The ide#util#GetSelectedText(mode) function
"                        can be used to obtain the text and the function
"                        ide#util#ReplaceSelectedText(lnum, count, cmd) can
"                        be used to call a function to update it in place.
"
" To use format with 'gq' set the following:
"     formatexpr=g:IdeFormatSelected("expr")
"
" To use format with operatorfunc and visualmode:
"   nnoremap <leader>f :set operatorfunc=g:FormatSelected<cr>g@
"   vnoremap <leader>f :<c-u>call g:FormatSelected(visualmode())<cr>
"
" A default implementation is available using projux or eclim depending on
" the 'format' setting in g:ide_filetype_settings.
"
" Args:
"   a:1: ':selected', ':file', '.', ...
if !exists("*g:IdeFormat")
  function! g:IdeFormat(...) abort " {{{
    return call("g:IdeDefaultFormat", a:000)
  endfunction " }}}
endif

" Default format implementation
function! g:IdeDefaultFormat(...) abort " {{{
  if a:0 > 0 && (ide#util#NameRangeMatch(a:1, ":s", ":selected") ||
      \ ide#util#NameRangeMatch(a:1, ":b", ":buffer"))
    let args = a:000
  else
    let args = s:ExpandTargets(a:000)
  endif
  let handler = g:IdeCmdHandler('format')
  if handler == 'projux'
    return call("ide#projux#Format", args)
  elseif handler == 'eclim'
    return call("ide#eclim#Format", args)
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Format not implemented for " . &filetype)
  else
    return ide#util#EchoError("Format not implemented")
  endif
endfunction " }}}


" Helper for calling ide:Format(selected, mode).
"
" This function can be used with operatorfunc and visualmode:
"   nnoremap <leader>f :set operatorfunc=g:FormatSelected<cr>g@
"   vnoremap <leader>f :<c-u>call g:FormatSelected(visualmode())<cr>
"
" It can also be used with formatexpr
"   formatexpr=g:IdeFormatSelected('expr')
"
" Args:
"   sel_mode: 'v' charwise visual, 'V' linewise visual, 'char' charwise
"     motion, 'line' linewise motion, 'block' blockwise motion, 'expr'
"     formatexpr
function! g:IdeFormatSelected(sel_mode) abort " {{{
  " If formatexpr, only format with 'giq' in normal mode, other really sloooow
  if a:sel_mode == "expr" && mode() != "n"
    return 1
  endif
  return g:IdeFormat(':selected', a:sel_mode)
endfunction " }}}


" Lint.
"
" Examples:
"   :lint            : default lint targets
"   :lint :file      : lint current file
"   :lint .          : lint current dir
"   :lint :project/  : lint targets in current project
"
" Lints targets specified by the optional args. The args supported are
" up to the the filetype specific settings to define. A default
" implementation is available as g:IdeDefaultLint using projux, eclim, or
" pymode depending on the 'lint' setting in g:ide_filetype_settings.
"
" Args:
"   a:1: ':file', '.', ...
if !exists("*g:IdeLint")
  function! g:IdeLint(...) abort " {{{
    return call("g:IdeDefaultLint", a:000)
  endfunction " }}}
endif

" Default lint implementation
function! g:IdeDefaultLint(...) abort " {{{
  if a:0 > 0 && ide#util#NameRangeMatch(a:1, ":b", ":buffer")
    let args = a:000
  else
    let args = s:ExpandTargets(a:000)
  endif
  if &filetype == "java" &&
        \ ((a:0 > 0 && ide#util#NameRangeMatch(a:1, ":p", ":pmd")) ||
        \  (a:0 > 1 && ide#util#NameRangeMatch(a:2, ":p", ":pmd")))
    return call('ide#pmd#Lint', args)
  endif

  let s:last_lint_errors = []
  let s:last_errors = [":lint"]
  let handler = g:IdeCmdHandler('lint')
  if handler == 'projux'
    return call("ide#projux#Lint", args)
  elseif handler == 'eclim'
    return call("ide#eclim#Lint", args)
  elseif handler == 'pymode'
    return call("ide#pymode#Lint", args)
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Lint not implemented for " . &filetype)
  else
    return ide#util#EchoError("Lint not implemented")
  endif
endfunction " }}}


" Build.
"
" Examples:
"   :build            : default build targets
"   :build :file      : build file
"   :build .          : build current dir
"   :build :project/  : build current project
"
" Builds file(s) specified by the optional args. The args supported are
" up to the the filetype specific settings to define. A default
" implementation is available as g:IdeDefaultBuild using projux or eclim
" depending on the 'build' setting in g:ide_filetype_settings.
"
" Args:
"   a:1: ':file', ...
if !exists("*g:IdeBuild")
  function! g:IdeBuild(...) abort " {{{
    return call("g:IdeDefaultBuild", a:000)
  endfunction " }}}
endif

" Default build implementation
function! g:IdeDefaultBuild(...) abort " {{{
  let s:last_build_errors = []
  let s:last_errors = [":build"]
  let args = s:ExpandTargets(a:000)

  let handler = g:IdeCmdHandler('build')
  if handler == 'projux'
    return call("ide#projux#Build", args)
  elseif handler == 'eclim'
    return call("ide#eclim#Build", args)
  elseif handler == 'pymode'
    return call("ide#pymode#Build", args)
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Build not implemented for " . &filetype)
  else
    return ide#util#EchoError("Build not implemented")
  endif
endfunction " }}}


" Test.
"
" Examples:
"   :test FooClass        : Run test case 'FooClass'
"   :test :file           : Run files test cases
"   :test .               : Run directory test cases
"   :test :all            : Run :all test cases
"
" Tests cases specified by the optional args. The args supported are
" up to the filetype specific settings to define. A default implementation
" is available as g:IdeDefaultTest using projux or eclim depending on the
" 'test' setting in g:ide_filetype_settings.
"
" Args:
"   a:1: <test_case>, ...
if !exists("*g:IdeTest")
  function! g:IdeTest(...) abort " {{{
    return call("g:IdeDefaultTest", a:000)
  endfunction " }}}
endif

" Default test implementation
function! g:IdeDefaultTest(...) abort " {{{
  let s:last_test_errors = []
  let s:last_errors = [":test"]
  let args = s:ExpandTargets(a:000)

  let handler = g:IdeCmdHandler('test')
  if handler == 'projux'
    return call("ide#projux#Test", args)
  elseif handler == 'eclim'
    return call("ide#eclim#Test", args)
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Test not implemented for " . &filetype)
  else
    return ide#util#EchoError("Test not implemented")
  endif
endfunction " }}}


" Coverage.
"
" Examples:
"   :coverage FooClass    : Run test coverage on test case 'FooClass'
"   :coverage :all        : Run coverage on all test cases
"
" Tests cases specified by the optional args. The args supported are
" up to the filetype specific settings to define. A default implementation
" is available as g:IdeDefaultCoverage using projux depending on the
" 'coverage' setting in g:ide_filetype_settings.
"
" Args:
"   a:1: <test_case>
if !exists("*g:IdeCoverage")
  function! g:IdeCoverage(...) abort " {{{
    return call("g:IdeDefaultCoverage", a:000)
  endfunction " }}}
endif

" Default coverage implementation
function! g:IdeDefaultCoverage(...) abort " {{{
  let s:last_coverage_errors = []
  let s:last_errors = [":coverage"]
  let args = s:ExpandTargets(a:000)

  if g:IdeCmdHandler('coverage') == 'projux'
    return call("ide#projux#Coverage", args)
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Coverage not implemented for " . &filetype)
  else
    return ide#util#EchoError("Coverage not implemented")
  endif
endfunction " }}}


" Run.
"
" Examples:
"   :run                  : Run program
"   :run :again           : Re-run last run
"
" Runs program. The args supported are implementation dependent. A default
" implementation is available as g:IdeDefaultRun using projux depending on
" the 'run' setting in g:ide_filetype_settings. The default implementation
" supports passing ':again' to re-run the previous run command.
"
" Args:
"   a:*: run args
if !exists("*g:IdeRun")
  function! g:IdeRun(...) abort " {{{
    return call("g:IdeDefaultRun", a:000)
  endfunction " }}}
endif

" Default run implementation
function! g:IdeDefaultRun(...) abort " {{{
  if a:0 > 0 && ide#util#NameRangeMatch(a:1, ":a", ":again")
    let args = s:last_run
  else
    let args = a:000
  endif

  if g:IdeCmdHandler('run') == 'projux'
    return call("ide#projux#Run", args)
  endif

  if a:0 == 0 || ! ide#util#NameRangeMatch(a:1, ":a", ":again")
    s:last_run = a:000
  endif

  return ide#util#EchoError("Run not implemented")
endfunction " }}}


" Sanity.
"
" Examples:
"   :sanity               : Run project sanity checks
"
" Runs project sanity checks. The args supported are implementation dependent.
" A default implementation is available as g:IdeDefaultSanity using projux
" depending on the 'sanity' setting in g:ide_filetype_settings.
if !exists("*g:IdeSanity")
  function! g:IdeSanity(...) abort " {{{
    return call("g:IdeDefaultSanity", a:000)
  endfunction " }}}
endif

" Default sanity implementation
function! g:IdeDefaultSanity(...) abort " {{{
  if g:IdeCmdHandler('sanity') == 'projux'
    return call("ide#projux#Sanity", a:000)
  endif

  return ide#util#EchoError("Sanity not implemented")
endfunction " }}}


" Errors.
"
" This function is called to create a list of errors associated with
" the file or project. Default support is available using syntastic
" eclim, and projux.
"
" Examples:
"   errors             # re-runs last call if any, otherwise picks a default
"   errors :build      # calls g:IdeGetErrors(":build") and adds to loclist
"   errors :lint       # calls g:IdeGetErrors(":lint") and adds to loclist
"   errors :test       # calls g:IdeGetErrors(":test") and adds to loclist
"   errors :coverage   # calls g:IdeGetErrors(":coverage") and adds to loclist
"   errors :syntastic  # calls g:IdeGetErrors(":syntastic") and adds to loclist
"   errors :eclim      # calls g:IdeGetErrors(":eclim") and adds to loclist
"   errors :all        # calls all of the above and aggregates into loclist
if !exists("*g:IdeErrors")
  function! g:IdeErrors(...) abort " {{{
    return call("g:IdeDefaultErrors", a:000)
  endfunction " }}}
endif

" Default errors implementation
function! g:IdeDefaultErrors(...) abort " {{{
  if a:0 == 0
    let args = s:last_errors
  else
    let args = a:000
  endif

  " No set yet, pick a default
  if len(args) == 0
    if ide#plugin#PluginExists("syntastic")
      let args = [":syntastic"]
    elseif ide#plugin#PluginExists("projux")
      if &filetype == "python" || &filetype == "ruby"
        let args = [":lint"]
      else
        let args = [":build"]
      endif
    elseif ide#plugin#PluginExists("eclim")
      let args = [":eclim"]
    else
      return
    endif
  endif

  " Syntastic handles errors on its own
  if ide#util#NameRangeMatch(args[0], ":s", ":syntastic")
    :SyntasticCheck
    let loclist = g:SyntasticLoclist.current()
    call setloclist(0, loclist.filteredRaw())
    return
  endif

  " Eclim handles errors on its own
  if ide#util#NameRangeMatch(args[0], ":e", ":eclim")
    call call("ide#eclim#Errors", args)
    return
  endif

  " Must be a projux keyword
  if ide#util#NameRangeMatch(args[0], ":b", ":build") &&
      \ ! empty(s:last_build_errors)
    let errlist = s:last_build_errors
  elseif ide#util#NameRangeMatch(args[0], ":l", ":lint") &&
      \ ! empty(s:last_lint_errors)
    let errlist = s:last_lint_errors
  elseif ide#util#NameRangeMatch(args[0], ":t", ":test") &&
      \ ! empty(s:last_test_errors)
    let errlist = s:last_test_errors
  elseif ide#util#NameRangeMatch(args[0], ":c", ":coverage") &&
      \ ! empty(s:last_coverage_errors)
    let errlist = s:last_coverage_errors
  elseif ide#util#NameRangeMatch(args[0], ":a", ":all")
    if empty(s:last_build_errors)
      let errlist = g:IdeGetErrors(":build")
      call setloclist(0, errlist)
      let s:last_build_errors = getloclist(0)
    endif
    if empty(s:last_lint_errors)
      let errlist = g:IdeGetErrors(":lint")
      call setloclist(0, errlist)
      let s:last_lint_errors = getloclist(0)
    endif
    let errlist = s:last_build_errors + s:last_lint_errors
  else
    let errlist = call('g:IdeGetErrors', args)
  endif

  call setloclist(0, errlist)

  " Let syntastic do its job...
  call ide#syntastic#DisplayErrors('location')

  if ide#util#NameRangeMatch(args[0], ":b", ":build")
    let s:last_build_errors = getloclist(0)
  elseif ide#util#NameRangeMatch(args[0], ":l", ":lint")
    let s:last_lint_errors = getloclist(0)
  elseif ide#util#NameRangeMatch(args[0], ":t", ":test")
    let s:last_test_errors = getloclist(0)
  elseif ide#util#NameRangeMatch(args[0], ":c", ":coverage")
    let s:last_coverage_errors = getloclist(0)
  endif

  let s:last_errors = args
endfunction " }}}


" Gets errors.
"
" This function is called whenever an arg is passed to the 'errors' commmand.
" A default implementation is available as g:IdeDefaultGetErrors using projux.
"
" Errors should be returned as a dictionary in the loclist format (see
" :help setqflist for details).
"
" Args:
"   a:1: Type of errors 'build', etc
if !exists("*g:IdeGetErrors")
  function! g:IdeGetErrors(...) abort " {{{
    return call("g:IdeDefaultGetErrors", a:000)
  endfunction " }}}
endif

" Default load errors implementation
function! g:IdeDefaultGetErrors(...) abort " {{{
  if a:0 == 0
    let handler = g:IdeCmdHandler('project')
  elseif len(a:1) > 0
    if a:1[0] == ':'
      let handler = g:IdeCmdHandler(a:1[1:])
    else
      let handler = g:IdeCmdHandler(a:1)
    endif
  else
    let handler = ''
  endif
  if handler == 'projux'
    return call("ide#projux#GetErrors", a:000)
  endif

  call ide#util#EchoError("GetErrors not implemented")
  return []
endfunction " }}}


" Auto-fixes source code.
"
" Examples:
"   fix                        : General code fix
"   fix imports                : Organize imports
"
" This is intended to be overriden by filetype specific settings. The keywords
" used depend on the implementation. A default implementation is available as
" g:IdeDefaultFix using eclim depending on the 'fix' setting in
" g:ide_filetype_settings.
"
" Args:
"   a:*: keywords
if !exists("*g:IdeFix")
  function! g:IdeFix(...) abort " {{{
    return call("g:IdeDefaultFix", a:000)
  endfunction " }}}
endif

" Default fix implementation.
function! g:IdeDefaultFix(...) abort " {{{
  if g:IdeCmdHandler('fix') == 'eclim'
    return call("ide#eclim#Fix", a:000)
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Fix not implemented for " . &filetype)
  else
    return ide#util#EchoError("Fix not implemented")
  endif
endfunction " }}}


" Generates source code.
"
" Examples:
"   gen import                   : Adds import for item under cursor
"   gen implementation           : Generates implementation of class/method
"   gen test                     : Generates test implementation
"   gen constructor              : Generates constructor method
"   gen getter                   : Generates getter
"   gen setter                   : Generates setter
"   gen property                 : Generates getter/setter
"   gen delegate                 : Generates delegate methods
"
" This is intended to be overriden by filetype specific settings. The keywords
" used depend on the implementation. A default implementation is available as
" g:IdeDefaultGen using eclim depending on the 'gen' setting in
" g:ide_filetype_settings.
"
" Args:
"   a:*: keywords
if !exists("*g:IdeGen")
  function! g:IdeGen(...) abort " {{{
    return call("g:IdeDefaultGen", a:000)
  endfunction " }}}
endif

" Default gen implementation.
function! g:IdeDefaultGen(...) abort " {{{
  if g:IdeCmdHandler('gen') == 'eclim'
    return call("ide#eclim#Gen", a:000)
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Gen not implemented for " . &filetype)
  else
    return ide#util#EchoError("Gen not implemented")
  endif
endfunction " }}}


" Mv (move).
"
" Examples:
"   :mv foo              : Move current file to directory 'foo'
"   :mv foo/bar.c        : Move current file to 'foo' and rename to bar.c
"   :mv foo              : Move file to foo
"   :mv foo/test.java    : Move file to foo and rename to test.java
"   :mv com/foo          : Move file to com/foo (update pkg to com.foo)
"
" Moves current file to different dir. If a full path dir is not provided then
" the dir is searched for relative to the current project dir. If multiple
" directories are possible they have already been presented to the user before
" this function is called.
"
" This may be overridden by filetype specific implementations (e.g. to account
" for java package renaming, etc). A default implementation is available as
" g:IdeDefaultMove using eclim depending on the 'move' setting in
" g:ide_filetype_settings otherwise shell commands are used.
"
" Args:
"   dest: Full path to new directory.
if !exists("*g:IdeMove")
  function! g:IdeMove(dest) abort " {{{
    return g:IdeDefaultMove(a:dest)
  endfunction " }}}
endif

" Default mv implementation.
function! g:IdeDefaultMove(dest) abort " {{{
  if g:IdeCmdHandler('move') == 'eclim'
    return call("ide#eclim#Move", a:000)
  endif

  " Default implementation
  echomsg "mv " . expand("%:p") . " " . a:dest
  call system(shellescape("mv " . expand("%:p") . " " . a:dest))
  exec "edit " . a:dest . "/" . expand("%:p:t")
endfunction " }}}


" Helper function to perform pre-processing before calling g:IdeMove
function! g:IdeProcessMove(target) abort " {{{
  if &modified
    return ide#util#EchoError(
      \ "Current file has modifications. Save file before moving")
  endif

  let file_name = ide#util#Filename(a:target)
  let dir_name = ide#util#Dirname(a:target)

  if stridx(file_name, ".") == -1
    " If no extension used then assume a dir specified
    let dir_name .= "/" . file_name
    let file_name = ""
  endif

  let results = g:IdeFindFiles(dir_name, ['type', 'd'])

  if len(results) == 0
    return ide#util#EchoError("Destination not found")
  elseif len(results[1]) == 1
    if empty(results[0])
      let path = results[1][0]
    else
      let path = results[0] . "/" . results[1][0]
    endif
    call g:IdeMove(empty(file_name) ? path : path . "/" . file_name)
  else
    let file_name = empty(file_name) ? expand("%:t") : file_name
    let dests = []
    for path in results[1]
      call add(dests, path . "/" . file_name)
    endfor
    call ide#util#ChooseFile(
      \ "file_list", g:ide_list_view_pos, g:ide_list_view_size,
      \ results[0], dests, "g:IdeFileChosenCb", g:IdeMove)
  endif
endfunction " }}}


" Rename.
"
" Examples:
"   :rename com.test             : Rename cur pkg to com.test
"   :rename Bar                  : Rename class under cursor to Bar
"   :rename Foo Bar              : Rename class Foo to Bar
"   :rename bar                  : Rename fn under cursor to bar
"   :rename foo bar              : Rename fn foo to bar

" Renames code specified by the optional args. The args supported are
" up to the the filetype specific settings to define. Some examples are:
" package, class, function/method, ...  The current word under cursor is
" available using expand("<cWORD>"). A default implementation is available as
" g:IdeDefaultRename using eclim depending on the 'rename' setting in
" g:ide_filetype_settings.
"
" Args:
"   a:*: Package/Class/Fn name(s)
if !exists("*g:IdeRename")
  function! g:IdeRename(...) abort " {{{
    return call("g:IdeDefaultRename", a:000)
  endfunction " }}}
endif

" Default rename implementation.
function! g:IdeDefaultRename(...) abort " {{{
  if g:IdeCmdHandler('rename') == 'eclim'
    return call("ide#eclim#Rename", a:000)
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Rename not implemented for " . &filetype)
  else
    return ide#util#EchoError("Rename not implemented")
  endif
endfunction " }}}


" Show.
"
" Example:
"   show hierarchy                : Show class / fn call hierarchy
"   show classpath                : Show current classpath
"   show process                  : Show running process info
"
" Shows additional information related to selected code. This function is
" intended to be overridden by filetype specifc settings. The keywords supported
" depend on the implementation. A default implementation is available as
" g:IdeDefaultShow using eclim depending on the 'show' setting in
" g:ide_filetype_settings.
"
" Args:
"   a*: keywords ('hierarchy', etc)
if !exists("*g:IdeShow")
  function! g:IdeShow(...)
    return call("g:IdeDefaultShow", a:000)
  endfunction " }}}
endif

" Default show implementation
function! g:IdeDefaultShow(...) abort " {{{
  if g:IdeCmdHandler('show') == 'eclim'
    return call("ide#eclim#Show", a:000)
  endif

  " Default implementation
  if !empty(&filetype)
    return ide#util#EchoError("Show not implemented for " . &filetype)
  else
    return ide#util#EchoError("Show not implemented")
  endif
endfunction " }}}


" Toggles breakpoint.
"
" A default implementation is provided using g:IdeDefaultToggleBreakpoint
" for python.
if !exists("*g:IdeToggleBreakpoint")
  function! g:IdeToggleBreakpoint() abort " {{{
    return g:IdeDefaultToggleBreakpoint()
  endfunction " }}}
endif

" Default toggle breakpoint
function! g:IdeDefaultToggleBreakpoint(context) abort " {{{
  " Filetype specific implementations
  if &filetype == "python"
    let breakpoint = "import pdb; pdb.set_trace();"

    let line_num = winline()
    let exists = 0

    " Search for breakpoint up/down 10 lines
    for i in range(line_num-10, line_num+10)
      if i > 0 && getline(i) =~ breakpoint
        let line_num = i
        let exists = 1
        break
      endif
    endfor

    if exists
      silent exec string(line_num-1) . "," . string(line_num+1) . "delete"
    else
      let line = getline(line_num)
      let indent = ""
      for i in range(0, len(line))
        if line[i] == " "
          let indent .=  " "
        else
          break
        endif
      endfor

      call append(line_num - 1, "")
      call append(line_num - 1, indent . breakpoint)
      call append(line_num - 1, "")
    endif
  endif

  if !empty(&filetype)
    return ide#util#EchoError(
      \ "ToggleBreakpoint not implemented for " . &filetype)
  else
    return ide#util#EchoError("ToggleBreakpoint not implemented")
  endif
endfunction " }}}


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tabbing (cycling) function implementations.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Selects next external view
function! g:IdeNextExternalView() abort " {{{
  if ! ide#mac#IsTerminalAttached()
    call ide#mac#PositionTerminalRelativeToMacVim(g:ide_terminal_view_pos, 1)
  endif
  if ! ide#mac#IsBrowserAttached()
    call ide#mac#PositionBrowserRelativeToMacVim(g:ide_browser_view_pos, 1)
  endif

  call ide#view#NextExternalView()
  call ide#util#InvokeLater(':call ide#mac#ActivateMacVim()')
endfunction " }}}


" Selects prev external view
function! g:IdePrevExternalView() abort " {{{
  if ! ide#mac#IsTerminalAttached()
    call ide#mac#PositionTerminalRelativeToMacVim(g:ide_terminal_view_pos, 1)
  endif
  if ! ide#mac#IsBrowserAttached()
    call ide#mac#PositionBrowserRelativeToMacVim(g:ide_browser_view_pos, 1)
  endif

  call ide#view#PrevExternalView()
  call ide#mac#ActivateMacVim()
endfunction " }}}


" Next colorscheme
function! g:IdeNextColorscheme() abort " {{{
  if s:next_colorscheme >= 0
    let cur = s:next_colorscheme
  else
    let cur = g:last_colorscheme + 1
  endif
  if cur >= len(g:ide_colorschemes)
    let cur = 0
  endif

  let cs_settings = g:ide_colorschemes[cur]
  call ide#util#SetColorScheme(cs_settings[0], cs_settings[1])
  if len(cs_settings) > 2 && !empty(cs_settings[2])
    exec "highlight Normal guibg=" . cs_settings[2]
  endif

  if cur + 1 >= len(g:ide_colorschemes)
    let s:next_colorscheme = 0
  else
    let s:next_colorscheme = cur + 1
  endif
endfunction " }}}


" Prev colorscheme
function! g:IdePrevColorscheme() abort " {{{
  if s:next_colorscheme >= 0
    let cur = s:next_colorscheme - 2
  else
    let cur = g:last_colorscheme - 1
  endif

  if cur < 0
    let cur += len(g:ide_colorschemes)
  endif

  let cs_settings = g:ide_colorschemes[cur]
  call ide#util#SetColorScheme(cs_settings[0], cs_settings[1])
  if len(cs_settings) > 2 && !empty(cs_settings[2])
    exec "highlight Normal guibg=" . cs_settings[2]
  endif

  if cur + 1 >= len(g:ide_colorschemes)
    let s:next_colorscheme = 0
  else
    let s:next_colorscheme = cur + 1
  endif
endfunction " }}}


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper Functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Returns the command (format, lint, build, ...) handler for the current
" file. If a command handler cannot be determined then the last one used
" is returned if set. If not set then the default settings are returned.
function! g:IdeCmdHandler(cmd) abort " {{{
  if !empty(&filetype)
    if has_key(g:ide_filetype_settings, &filetype)
      let settings = g:ide_filetype_settings[&filetype]
      if has_key(settings, a:cmd)
        let s:default_cmd_handler[a:cmd] = settings[a:cmd]
        return s:default_cmd_handlers[a:cmd]
      endif
    endif
  endif

  if has_key(s:default_cmd_handlers, a:cmd)
    return s:default_cmd_handlers[a:cmd]
  endif

  if has_key(g:ide_filetype_settings['default'], a:cmd)
    return g:ide_filetype_settings['default'][a:cmd]
  else
    return ''
  endif
endfunction " }}}


" Displays missing plugin error (global because can be called from autocmds).
function! g:IdeMissingPluginError(plugin) abort " {{{
  return ide#util#EchoError("Plugin not installed: " . a:plugin)
endfunction " }}}


"  Returns default base directory to use.
"
"  This is either the project directory if the cur file is in the project
"  path, or the current files directory.
function! s:GetDefaultBaseDir() abort " {{{
  let cur_dir = expand("%:p:h")
  let project_dir = g:IdeProjectDir(expand("%:p"))
  if stridx(cur_dir, project_dir) != -1
    return project_dir
  else
    return cur_dir
  endif
endfunction " }}}
