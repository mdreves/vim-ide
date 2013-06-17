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

" Initialize Eclim variables
function! ide#eclim#Init() abort " {{{
  let s:initialized = 1

  let s:plugin_exists = ide#plugin#PluginExists("eclim")
  if ! s:plugin_exists
    return
  endif

  let g:EclimProblemsQuickFixOpen = ":call ide#view#OpenView('quickfix')"

  if !exists("*g:EclimProjectKeepLocalHistory")
    let g:EclimProjectKeepLocalHistory = 1
  endif

  if !exists("*g:EclimCompletionMethod")
    let g:EclimCompletionMethod = 'omnifunc'
  endif
endfunction " }}}


" Eclim ToggleProjectExplorer function
function! ide#eclim#ToggleProjectExplorer(...) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  exec ":ProjectTreeToggle"
endfunction " }}}


" Eclim project implementation.
"
" Examples:
"   project ls
"   project settings
"   project refresh
"   project refresh all
"   project config          # C/CPP
"   project classpath       # Java
"   project create
"   project delete
"   project import
"   project rename
"   project move
"   project info
"   project open
"   project close
"   project natures
"   project nature add
"   project nature delete
"   project cd
"   project lcd
function! ide#eclim#Project(...) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  if a:0 == 0
    exec ":ProjectInfo"
  elseif ide#util#NameRangeMatch(a:1, "ls", "ls") ||
      \ ide#util#NameRangeMatch(a:1, "list", "list")
    exec ":ProjectList"
  elseif ide#util#NameRangeMatch(a:1, "settings", "settings")
    exec ":ProjectSettings"
  elseif ide#util#NameRangeMatch(a:1, "refresh", "refresh")
    if a:0 > 1 && (ide#util#NameRangeMatch(a:2, "all", "all") || a:2 ==? "*")
      exec ":ProjectRefreshAll"
    else
      exec ":ProjectRefresh"
    endif
  elseif ide#util#NameRangeMatch(a:1, "config", "config")
    if &filetype ==? "cpp" || &filetype ==? "c"
      exec ":CProjectConfigs"
    endif
  elseif ide#util#NameRangeMatch(a:1, "classpath", "classpath")
    if &filetype ==? "java"
      exec ":JavaClasspath -d \\n"
    endif
  elseif ide#util#NameRangeMatch(a:1, "create", "create")
    exec ":ProjectCreate " . join(a:000[1:], " ")
  elseif ide#util#NameRangeMatch(a:1, "delete", "delete")
    exec ":ProjectDelete " . join(a:000[1:], " ")
  elseif ide#util#NameRangeMatch(a:1, "import", "import")
    exec ":ProjectImport " . join(a:000[1:], " ")
  elseif ide#util#NameRangeMatch(a:1, "rename", "rename")
    exec ":ProjectRename " . join(a:000[1:], " ")
  elseif ide#util#NameRangeMatch(a:1, "move", "move")
    exec ":ProjectMove " . join(a:000[1:], " ")
  elseif ide#util#NameRangeMatch(a:1, "info", "info")
    exec ":ProjectInfo " . join(a:000[1:], " ")
  elseif ide#util#NameRangeMatch(a:1, "open", "open")
    exec ":ProjectOpen " . join(a:000[1:], " ")
  elseif ide#util#NameRangeMatch(a:1, "close", "close")
    exec ":ProjectClose " . join(a:000[1:], " ")
  elseif ide#util#NameRangeMatch(a:1, "natures", "natures")
    exec ":ProjectNatures " . join(a:000[1:], " ")
  elseif ide#util#NameRangeMatch(a:1, "nature", "nature")
    if a:0 > 1 && ide#util#NameRangeMatch(a:2, "add", "add")
      exec ":ProjectNatureAdd " . join(a:000[2:], " ")
    elseif a:0 > 1 && ide#util#NameRangeMatch(a:2, "delete", "delete")
      exec ":ProjectNatureRemove " . join(a:000[2:], " ")
    endif
  elseif ide#util#NameRangeMatch(a:1, "cd", "cd")
    exec ":ProjectCD"
  elseif ide#util#NameRangeMatch(a:1, "lcd", "lcd")
    exec ":ProjectLCD"
  else
    exec ":ProjectOpen " . a:1
  endif
endfunction " }}}


" Eclim Docs implementation
"
" Examples:
"   docs         # Java only
function! ide#eclim#Docs(...) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  if a:0 > 0
    let tags = join(a:000, " ")
  else
    let tags = expand("<cWORD>")
  endif

  if &filetype ==? "java"
    exec "JavaDocSearch " . tags
    return
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Docs not implemented for " . &filetype)
  else
    return ide#util#EchoError("Docs not implemented")
  endif
endfunction " }}}


" Eclim DocsComplete implementation
function! ide#eclim#DocsComplete(argLead, cmdLine, cursorPos) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if &filetype ==? "java"
    return eclim#java#search#CommandCompleteJavaSearch(
      \ a:argLead, a:cmdLine, a:cursorPos)
  endif

  return []
endfunction " }}}


" Eclim Search implementation
"
" Examples:
"   search -p ...     # Java, C/CPP, Ruby, PHP
"   search todo
"   search todo project
function! ide#eclim#Search(...) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  if a:0 == 0
    " Re-use previous search
    if !empty(s:last_search)
      exec ":Search " . join(a:000, " ")
    endif
    return
  endif

  let s:last_search = a:000

  if a:1 ==? "-p"
    if &filetype ==? "c" || &filetype ==? "cpp"
      exec ":CSearch " . join(a:000, " ")
      return
    elseif &filetype ==? "java"
      exec ":JavaSearch " . join(a:000, " ")
      return
    elseif &filetype ==? "ruby"
      exec ":RubySearch " . join(a:000, " ")
      return
    elseif &filetype ==? "php"
      exec ":PhpSearch " . join(a:000, " ")
      return
    endif
  elseif a:1 ==? "todo"
    if a:0 > 1 && (ide#util#NameRangeMatch(a:2, ":f", ":file") || a:2 ==? "%")
      exec ":Todo"
      return
    elseif a:0 == 1 ||
        \ (a:0 > 1 && ide#util#NameRangeMatch(a:2, ":p", ":project"))
      exec ":ProjectTodo"
      return
    endif
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Search not implemented for " . &filetype)
  else
    return ide#util#EchoError("Search not implemented")
  endif
endfunction " }}}


" Eclim SearchContext implementation (Java, Scala, C/CPP, Python, Ruby, PHP)
function! ide#eclim#SearchContext(context) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  if &filetype ==? "java"
    exec ":JavaSearchContext"
    return
  elseif &filetype ==? "scala"
    exec ":ScalaSearch"
    return
  elseif &filetype ==? "python"
    exec ":PythonSearchContext"
    return
  elseif &filetype ==? "ruby"
    exec ":RubySearchContext"
    return
  elseif &filetype ==? "c" || &filetype ==? "cpp"
    exec ":CSearchContext"
    return
  elseif &filetype ==? "php"
    exec ":PhpSearchContext"
    return
  endif

  if !empty(&filetype)
    return ide#util#EchoError("SearchContext not implemented for " . &filetype)
  else
    return ide#util#EchoError("SearchContext not implemented")
  endif
endfunction " }}}


" Eclim Build implementation (Java, Scala, C/CPP, Javascript, Python, Ruby,...)
"
" Examples:
"   build           # Java, Scala, Python, Ruby, ...
"   build :docs     # Java
function! ide#eclim#Build(...) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  if &filetype ==? "python"
      exec ":PyLint"
      exec ":Validate"
      return
  else
    if a:0 > 0 && ide#util#NameRangeMatch(a:1, ":do", ":docs")
      if &filetype ==? "java"
        exec ":Javadoc"
        return
      endif
    endif

    if a:0 == 0 || ide#util#NameRangeMatch(a:1, ":f", ":file") || a:1 ==? "%"
      if &filetype ==? "java" || &filetype ==? "scala" ||
          \ &filetype ==? "c" || &filetype ==? "cpp" ||
          \ &filetype ==? "css" || &filetype ==? "javascript" ||
          \ &filetype ==? "html" || &filetype ==? "xhtml" ||
          \ &filetype ==? "python" || &filetype ==? "ruby" ||
          \ &filetype ==? "xml" || &filetype ==? "dtd" || &filetype ==? "xsd"
          \ &filetype ==? "php"
        exec ":Validate"
        return
      endif
    elseif ide#util#NameRangeMatch(a:1, ":p", ":project") ||
        \ ide#util#NameRangeMatch(a:1, "a", "all") || a:1 ==? "*"
      exec ":ProjectBuild"
      return
    endif
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Build not implemented for " . &filetype)
  else
    return ide#util#EchoError("Build not implemented")
  endif
endfunction " }}}


" Eclim Lint implementation
"
" Examples:
"   lint              # Java, Python, Javascript, ...
"   lint :checkstyle  # Same as Java
function! ide#eclim#Lint(...) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  if &filetype ==? "python"
    if a:0 == 0 || ide#util#NameRangeMatch(a:1, ":f", ":file") || a:1 ==? "%"
      exec ":PyLint"
      return
    endif
  elseif &filetype ==? "java"
    let idx = 0
    if a:0 == 0 || ide#util#NameRangeMatch(a:1, ":f", ":file") || a:1 ==? "%"
      let a:target = "file"
      let idx += 1
    elseif a:1 == '.' || a:1 ==? "%/"
      let a:target = "dir"
      let idx += 1
    elseif ide#util#NameRangeMatch(a:1, ":p", ":project") ||
        \ ide#util#NameRangeMatch(a:1, ":a", ":all") || a:1 ==? "*"
      let a:target = "project"
      let idx += 1
    endif

    if idx >= a:0 || ide#util#NameRangeMatch(a:000[idx], ":c", ":checkstyle")
      exec ":Checkstyle"
      return
    endif
  else
    if a:0 == 0 || ide#util#NameRangeMatch(a:1, ":f", ":file") || a:1 ==? "%"
      if &filetype ==? "css" || &filetype ==? "javascript" ||
          \ &filetype ==? "html" || &filetype ==? "xhtml" ||
          \ &filetype ==? "python" || &filetype ==? "ruby" ||
          \ &filetype ==? "xml" || &filetype ==? "dtd" || &filetype ==? "xsd"
          \ &filetype ==? "php"
        exec ":Validate"
        return
      endif
    endif
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Lint not implemented for " . &filetype)
  else
    return ide#util#EchoError("Lint not implemented")
  endif
endfunction " }}}


" Eclim Test implementation (Java only).
"
" Examples:
"   test %         # or test file
"   test :all      # or test project
"   test FooTest
function! ide#eclim#Test(...) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  if &filetype ==? "java"
    if a:0 == 0 || ide#util#NameRangeMatch(a:1, ":f", ":file") || a:1 ==? "%"
      exec ":JUnit %"
      return
    elseif a:0 > 0 && (ide#util#NameRangeMatch(a:1, ":a", ":all") || a:1 ==? "*"
        \ || ide#util#NameRangeMatch(a:1, "p", "project"))
      exec ":JUnit *"
      return
    elseif a:0 > 0
      exec ":JUnit " . a:1
      return
    endif
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Test not implemented for " . &filetype)
  else
    return ide#util#EchoError("Test not implemented")
  endif
endfunction " }}}


" Eclim errors implementation
function! ide#eclim#Errors(...) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  call setqflist([])
  exec ":sign unplace *"
  exec ":ProjectProblems"
endfunction " }}}


" Eclim Format implementation (Java, XML).
"
" Examples:
"   format            # Java, XML
"   format :selected  # as above (Java)
"   format :file
"   format :imports
function! ide#eclim#Format(...) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  if &filetype ==? "java"
    if a:0 == 0 || ide#util#NameRangeMatch(a:1, ":s", ":selected")
      exec ":JavaFormat"
      return
    elseif ide#util#NameRangeMatch(a:1, ":f", ":file") || a:1 ==? "%"
      exec ":%JavaFormat"
      return
    elseif ide#util#NameRangeMatch(a:1, ":i", ":imports")
      exec ":JavaImportOrganize"
      return
    endif
  elseif &filetype ==? "xml"
    exec ":XmlFormat"
    return
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Format not implemented for " . &filetype)
  else
    return ide#util#EchoError("Format not implemented")
  endif
endfunction " }}}


" Eclim fix implementation (Java only).
function! ide#eclim#Fix(...) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  if &filetype ==? "java"
    exec ":JavaCorrect"
    return
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Fix not implemented for " . &filetype)
  else
    return ide#util#EchoError("Fix not implemented")
  endif
endfunction " }}}


" Eclim Gen implementation (Java).
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
function! ide#eclim#Gen(...) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  if &filetype ==? "java"
    if a:0 > 0 && ide#util#NameRangeMatch(a:1, "i", "import")
      exec ":JavaImport"
      return
    elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, "impl", "implementation")
      exec ":JavaImpl"
      return
    elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, "t", "test")
      exec ":JUnitImpl"
      return
    elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, "c", "constructor")
      exec ":JavaConstructor"
      return
    elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, "g", "getter")
      exec ":JavaGet"
      return
    elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, "s", "setter")
      exec ":JavaSet"
      return
    elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, "p", "property")
      exec ":JavaGetSet"
      return
    elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, "d", "delegate")
      exec ":JavaDelegate"
      return
    endif
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Gen not implemented for " . &filetype)
  else
    return ide#util#EchoError("Gen not implemented")
  endif
endfunction " }}}


" Eclim mv implementation (Java).
function! ide#eclim#Move(dest) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  if &filetype ==? "java"
    " Check if package directory chosen
    let pkg_names = []
    let target_dir = ide#util#Dirname(a:target)
    let src_dirs = g:IdeSrcDirs(target_dir)
    if len(src_dirs) > 0 && stridx(a:target, src_dirs[0] . "/") != -1
      let pkg_names = split(target_dir[len(src_dirs[0]) + 1:], "/")
    endif
    if len(pkg_names) > 0
      let test_dirs = g:IdeTestDirs(target_dir)
      if len(test_dirs) > 0 && stridx(a:target, test_dirs[0] . "/") != -1
        let pkg_names = split(target_dir[len(test_dirs[0]) + 1:], "/")
      endif
    endif
    if len(pkg_names) > 0 && (pkg_names[0] ==# "com" ||
        \ pkg_names[0] ==# "org" || pkg_names[0] ==# "net")
      exec ":JavaMove " . join(pkg_names, ".")
      return
    endif
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Move not implemented for " . &filetype)
  else
    return ide#util#EchoError("Move not implemented")
  endif
endfunction " }}}


" Default rename implementation.
function! g:IdeDefaultRename(...) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  if &filetype ==? "java"
    if s:plugin_exists && a:0 > 0
      exec ":JavaRename " . a:1
      return
    endif
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Rename not implemented for " . &filetype)
  else
    return ide#util#EchoError("Rename not implemented")
  endif
endfunction " }}}


" Eclim show implementation (Java, C/CPP).
function! ide#eclim#Show(...) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  if &filetype ==? "java"
    if a:0 > 0 && ide#util#NameRangeMatch(a:1, "h", "hierarchy")
      exec ":JavaHierarchy"
      return
    elseif a:0 > 0 && ide#util#NameRangeMatch(a:1, "p", "process")
      exec ":Jps"
      return
    endif
  elseif &filetype ==? "c" || &filetype ==? "cpp"
    if a:0 > 0 && ide#util#NameRangeMatch(a:1, "h", "hierarchy")
      exec ":CCallHierarchy"
      return
    endif
  endif

  if !empty(&filetype)
    return ide#util#EchoError("Show not implemented for " . &filetype)
  else
    return ide#util#EchoError("Show not implemented")
  endif
endfunction " }}}


" Eclim history implementation.
"
" Examples:
"   history show
"   history clear
function! ide#eclim#History(...) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  if a:0 == 0 || a:1 ==? "show"
    exec ":History"
  else if a:1 ==? "clear"
    exec ":HistoryClear"
  endif
endfunction " }}}


" Eclim commands.
"
" Examples:
"   status         : PingEclim
"   settings       : EclimSettings
"   start          : EclimEnable
"   stop           : EclimDisable
"   kill           : EclimShutdown
function! ide#eclim#Cmd(...) abort " {{{
  if ! s:initialized
    call ide#eclim#Init()
  endif

  if ! s:plugin_exists
    return ide#util#EchoError("Missing eclim plugin")
  endif

  if a:0 == 0
    return
  endif

  if ide#util#NameRangeMatch(a:1, "status", "status")
    exec ":PingEclim"
  elseif ide#util#NameRangeMatch(a:1, "settings", "settings")
    exec ":EclimSettings"
  elseif ide#util#NameRangeMatch(a:1, "stop", "stop")
    exec ":EclimDisable"
  elseif ide#util#NameRangeMatch(a:1, "start", "start")
    exec ":EclimEnable"
  elseif ide#util#NameRangeMatch(a:1, "kill", "kill")
    exec ":EclimShutdown"
  endif
endfunction " }}}
