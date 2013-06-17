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
if exists("g:loaded_ide") || &cp || v:version < 700
  finish
endif

" Check if user disabled
if exists("g:ide") && g:ide == 0
 finish
endif

let g:ide = 1
let g:loaded_ide = 1

let s:save_cpo = &cpo
set cpo&vim

if !exists("g:basic_mode")
  let g:basic_mode = 0
endif

if !exists("g:ide_mike_mode")
  let g:ide_mike_mode = 0
endif

" Local plugin settings
runtime! plugin/ide/*.vim


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Startup
if !g:basic_mode
  augroup startup_augroup
    autocmd!
    autocmd VimEnter * :call g:IdeStartup()
  augroup END
endif

" Ideally we would match only view buffers, but this is simpler and
" the VIM quickfix buffers don't match BufWinLeave
augroup ide_view_augroup
  autocmd! BufWinEnter *
  autocmd! BufWinLeave *
  autocmd BufWinEnter * call ide#view#WindowOpenedCb(expand("<abuf>"))
  autocmd BufWinLeave * call ide#view#WindowClosedCb(expand("<abuf>"))
augroup END

" Filetype colorschemes, background color, local settings, and print margin
augroup ide_filetype_augroup
  autocmd! FileType *
  autocmd FileType *
    \ let file_type = expand("<amatch>") |
    \ if has_key(g:ide_filetype_settings, file_type) |
    \   let settings = g:ide_filetype_settings[file_type] |
    \ else |
    \   let settings = g:ide_filetype_settings['default'] |
    \ endif |
    \ if g:last_colorscheme == -1 && !g:basic_mode &&
    \     has_key(settings, 'colorscheme') && settings['colorscheme'] >= 0 |
    \   let g:last_colorscheme = settings['colorscheme'] |
    \   let cs_settings = g:ide_colorschemes[g:last_colorscheme] |
    \   call ide#util#SetColorScheme(cs_settings[0], cs_settings[1]) |
    \   if len(cs_settings) > 2 && !empty(cs_settings[2]) |
    \     exec "highlight Normal guibg=" . cs_settings[2] |
    \   endif |
    \ endif |
    \ if has_key(settings, 'local_settings') &&
    \    !empty(settings['local_settings']) |
    \   exec "setlocal " . settings['local_settings'] |
    \ endif |
    \ if !g:basic_mode && has_key(settings, 'margin') &&
    \    settings['margin'] >= 0 |
    \   call ide#util#SetPrintMargin(settings['margin']) |
    \ endif
augroup END


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if !exists("g:ide_lowercase_commands")
  let g:ide_lowercase_commands = 1
endif

if !exists("g:ide_enable_mappings") || g:ide_enable_mappings == 1

  " General Commands
  """"""""""""""""

  " open {dir xxx|file xxx|browser xxx|terminal|quickfix|location|...}
  command! -nargs=* Open call g:IdeOpen("local", <f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("o", "open", "Open")
    call ide#util#LowercaseUserCmd("od", "od", "Open dir")
    call ide#util#LowercaseUserCmd("of", "of", "Open file")
    call ide#util#LowercaseUserCmd("os", "os", "Open split")
    call ide#util#LowercaseUserCmd("ot", "ot", "Open tab")
  endif

  " eopen {dir xxx|file xxx|browser xxx|terminal|...}
  command! -nargs=* EOpen call g:IdeOpen("external", <f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("eo", "eopen", "EOpen")
    call ide#util#LowercaseUserCmd("gv", "gvim", "EOpen")
  endif

  " close {project|outline|terminal|quickfix|location|...}
  command! -nargs=* Close call g:IdeClose(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("clo", "close", "Close")
  endif

  " find {pat} {dir} {flags}
  command! -nargs=* Find call g:IdeFind(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("fin", "find", "Find")
  endif

  " grep {pat} {dir}
  command! -nargs=* Grep call g:IdeGrep(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("gr", "grep", "Grep")
  endif

  " google {words}
  command! -nargs=* Google call g:IdeGoogle(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("goo", "google", "Google")
  endif

  " help <subject>  (special case of open)
  command! -nargs=1 Help call g:IdeHelp(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("h", "help", "Help")
  endif

  " diff {file}
  command! -nargs=* Diff :call g:IdeDiff("local", <f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("diff", "diff", "Diff")
  endif

  " ediff {file} {file}
  command! -nargs=* EDiff :call g:IdeDiff("external", <f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("edif", "ediff", "EDiff")
  endif

  " git {option}
  command! -nargs=* Git :call g:IdeGit(<f-args>)
  " Workaround so Git can override fugative Git
  augroup ide_git_augroup
    autocmd! BufWinEnter *
    autocmd BufWinEnter * call ide#util#InvokeLater(
      \ "command! -buffer -nargs=* Git :call g:IdeGit(<f-args>)")
  augroup END
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("gi", "git", "Git")
    call ide#util#LowercaseUserCmd("git!", "git!", "Git!")
  endif

  " history {file|command|search|...}
  command! -nargs=* History :call g:IdeHistory(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("his", "history", "History")
  endif

  " clear {quicklist|location|sign|history file}
  command! -nargs=* Clear call g:IdeClear(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("cle", "clear", "Clear")
  endif

  " refresh
  command! -nargs=* Refresh call g:IdeRefresh()
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("ref", "refresh", "Refresh")
  endif

  " reset
  command! -nargs=* Reset call g:IdeReset()
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("rese", "reset", "Reset")
  endif

  " save session
  command! -nargs=* Save call g:IdeSave(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("save", "save", "Save")
  endif

  " rm session
  command! -nargs=* Rm call g:IdeRm(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("rm", "rm", "Rm")
  endif

  " tmux
  command! -nargs=* Tmux call g:IdeTmux(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("tmu", "tmux", "Tmux")
  endif

  " win {name}
  command! -nargs=* Win call g:IdeWin('local', <f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("win", "win", "Win")
  endif

  " ewin {name}
  command! -nargs=* EWin call g:IdeWin('external', <f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("ew", "ewin", "EWin")
  endif

  " buffers
  command! -nargs=* Buffers call g:IdeBuffers(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("buffers", "buffers", "Buffers")
  endif

  " mru
  command! -nargs=* Mru exec "MRU"
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("mru", "mru", "Mru")
  endif

  " fuz (fuzzy finder)
  command! -nargs=* Fuz exec "FufFile"
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("fuz", "fuz", "Fuz")
  endif

  " attach
  if has("gui_running")
    command! -nargs=+ Attach call g:IdeAttach(<f-args>)
    if g:ide_lowercase_commands
      call ide#util#LowercaseUserCmd("at", "attach", "Attach")
    endif
  endif

  " detach
  if has("gui_running")
    command! -nargs=+ Dettach call g:IdeDettach(<f-args>)
    if g:ide_lowercase_commands
      call ide#util#LowercaseUserCmd("det", "dettach", "Dettach")
    endif
  endif

  " plugin {ls|update|enable|disable} <plugin>
  command! -nargs=+ -complete=customlist,g:IdePluginComplete Plugin
    \ :call g:IdePlugin(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("pl", "plugin", "Plugin")
  endif

  " restart
  command! -nargs=* Restart exec "RestartVim"
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("restart", "restart", "Restart")
  endif


  " Project Commands
  """"""""""""""""

  " project {<proj>|ls|settings|refresh|}
  command! -nargs=* Project call g:IdeProject(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("proj", "project", "Project")
  endif

  " docs <tags>
  command! -nargs=* -complete=customlist,g:IdeDocsComplete Docs
    \ :call g:IdeDocs(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("doc", "docs", "Docs")
  endif

  " search <pattern>
  command! -nargs=* Search call g:IdeSearch(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("sea", "search", "Search")
  endif

  " format {buffer|file|dir|all}
  command! -nargs=* Format call g:IdeFormat(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("for", "format", "Format")
  endif

  " lint {file|dir|all}
  command! -nargs=* Lint call g:IdeLint(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("lin", "lint", "Lint")
  endif

  " build {file|dir|project|all}
  command! -nargs=* Build call g:IdeBuild(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("bui", "build", "Build")
  endif

  " test {<test_case>|file|dir|all}
  command! -nargs=* Test call g:IdeTest(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("te", "test", "Test")
  endif

  " coverage {<test_case>|file|dir|all}
  command! -nargs=* Coverage call g:IdeCoverage(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("cov", "coverage", "Coverage")
  endif

  " run
  command! -nargs=* Run call g:IdeRun(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("run", "run", "Run")
  endif

  " errors
  command! -nargs=* Errors call g:IdeErrors(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("er", "errors", "Errors")
  endif

  " fix {imports}
  command! -nargs=* Fix call g:IdeFix(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("fix", "fix", "Fix")
  endif

  " gen {import|impl|test|constructor|getter|setter|property|delegate}
  command! -nargs=* Gen call g:IdeGen(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("ge", "gen", "Gen")
  endif

  " mv <dir>
  command! -nargs=* Mv call g:IdeProcessMove(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("mv", "mv", "Mv")
  endif

  " rename <old> <new>
  command! -nargs=* Rename call g:IdeRename(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("ren", "rename", "Rename")
  endif

  " show {hierarchy|classpath|process}
  command! -nargs=1 Show call g:IdeShow(<f-args>)
  if g:ide_lowercase_commands
    call ide#util#LowercaseUserCmd("sho", "show", "Show")
  endif

  if ide#plugin#PluginExists("eclim")
    " Ant
    if g:ide_lowercase_commands
      call ide#util#LowercaseUserCmd("ant", "ant", "Ant")
    endif

    " Mvn
    if g:ide_lowercase_commands
      call ide#util#LowercaseUserCmd("mvn", "mvn", "Mvn")
    endif

    " dict <word>
    command -nargs=? Dict call eclim#web#WordLookup(
      \ 'http://dictionary.reference.com/search?q=<query>', '<args>')
    if g:ide_lowercase_commands
      call ide#util#LowercaseUserCmd("dic", "dict", "Dict")
    endif
  endif
endif


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if !exists("g:ide_enable_mappings") || g:ide_enable_mappings == 1

  " Toggle (T) Mappings
  """""""""""""""""

  " Toggle breakpoint with tb
  nnoremap <silent> tb :call g:IdeToggleBreakpoint()<cr>

  " Toggle chrome (browser view) with tc
  nnoremap <silent> tc :call ide#view#ToggleView("browser")<cr>

  " Toggle diff view with td
  nnoremap <silent> td :call ide#view#ToggleView("diff")<cr>

  " Toggle file/project explorer view with te
  nnoremap <silent> te :call ide#view#ToggleView("explorer")<cr>

  " Toggle folds with tf
  nnoremap <silent> tf :set invfoldenable foldenable?<cr>

  " Toggle git view with tg
  nnoremap <silent> tg :call ide#view#ToggleView("git")<cr>

  " Toggle help view with th
  nnoremap <silent> th :call ide#view#ToggleView("help")<cr>

  " Toggle insert (paste) with ti
  "set pastetoggle=<F10>
  " Also enable ctrl-c and ctrl-v for cut/paste (not needed on mac)
  "map <c-v> "+gP
  "map <c-v> <c-r>+
  "vnoremap <c-c> "+y
  nnoremap <silent> ti :set invpaste paste?<cr>

  " Toggle jump to buffer (e.g. buffer view) with tj
  nnoremap <silent> tj :call ide#view#ToggleView("buffers")<cr>

  " Toggle location list view with tl
  nnoremap <silent> tl :call ide#view#ToggleView("location")<cr>

  " Toggle mirror view with tm
  nnoremap <silent> tm :call ide#view#ToggleView("mirror")<cr>

  " Toggle line number display with tn
  nnoremap <silent> tn :set invnumber number?<cr>:set foldcolumn=0<cr>

  " Toggle outline view (Taglist/TaglistToo display) with to
  nnoremap <silent> to :call ide#view#ToggleView("outline")<cr>

  " Toggle project view with tp
  nnoremap <silent> tp :call ide#view#ToggleView("projects")<cr>

  " Toggle quickfix view  with tq
  nnoremap <silent> tq :call ide#view#ToggleView("quickfix")<cr>

  " Toggle split view with ts
  nnoremap <silent> ts :call ide#view#ToggleView("split")<cr>

  " Toggle terminal view  with tt
  nnoremap <silent> tt :call ide#view#ToggleView("terminal")<cr>

  " Toggle wrapping with tw
  nnoremap <silent> tw :set invwrap wrap?<cr>

  " Toggle search highlights with t/
  nnoremap <silent> t/ :set invhls hls?<cr>


  " Contextual (G) Mappings
  """""""""""""""""

  " Go to browser with gb
  nnoremap <silent> gb :call g:IdeOpen(
      \ "external", "browser ", expand("<cWORD>"))<cr>

  " Go to help with gh (overrides select mode)
  nnoremap <silent> gh :call g:IdeHelp(expand("<cWORD>"))<cr>

  " Go to doc ref with gr (overrides virtual repeat)
  nnoremap <silent> gr :call g:IdeDocs(expand("<cWORD>"))<cr>

  " Go to search with gs (overrides sleep)
  nnoremap <silent> gs :call g:IdeSearchContext(expand("<cWORD>"))<cr>

  " Go transmit to terminal with gt
  nnoremap <silent> gt vip :call <SID>TmuxTerminal()<cr>
  "vnoremap <silent> gt :call <SID>TmuxTerminal()<cr>

  function s:TmuxTerminal() range abort " {{{
    let handler = g:IdeCmdHandler('project')
    if handler == 'projux'
      call call("ide#projux#Init", a:000)
    endif
    let text = join(getline(a:firstline, a:lastline), "\n") . "\n\n"
	  return ide#tmux#Send(text, ide#tmux#GetOppositeSession())
  endfunction " }}}


  " Command Shortcuts
  """""""""""""""""

  " Build with <leader>b
  noremap <silent> <leader>b :call g:IdeBuild()<cr>

  " Show errors with <leader>e
  noremap <silent> <leader>e :call g:IdeErrors()<cr>

  " Format with <leader>f
  noremap <silent> <leader>f :call g:IdeFormat(":buffer")<cr>
  " Stupid go code replaces <leader>f with import 'fmt' code...
  " Workaround so Format can override Go import fmt
  augroup ide_go_augroup
    autocmd! BufWinEnter *.go
    autocmd BufWinEnter *.go map <buffer> <LocalLeader>f
        \ :call g:IdeFormat(':buffer')<CR>
  augroup END

  "nnoremap <silent> <leader>f :set operatorfunc=g:IdeFormatSelected<cr>g@
  "vnoremap <silent> <leader>f :<c-u>call g:IdeFormatSelected(
  "    \ visualmode())<cr>

  " Gen import with <leader>i
  noremap <silent> <leader>i :call g:IdeGen("import")<cr>

  " Lint with <leader>l
  noremap <silent> <leader>l :call g:IdeLint(":buffer")<cr>

  " Syntastic with <leader>s
  noremap <silent> <leader>s :call g:IdeErrors(":syntastic")<cr>

  " Test with <leader>t
  noremap <silent> <leader>t :call g:IdeTest(
      \ g:IdeCompanion(expand("%:p"), ":test"))<cr>

  " Run with <leader>r
  noremap <silent> <leader>r :call g:IdeRun(":again")<cr>


  " Mike mode
  """""""""""""""""
  if g:ide_mike_mode
    call ide#mikemode#Mappings()
  endif
endif


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" End Plugin Settings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let &cpo = s:save_cpo
unlet s:save_cpo
