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
if exists("g:loaded_ide_global_vars") || &cp || v:version < 700
  finish
endif
let g:loaded_ide_global_vars = 1

" Check if user disabled
if exists("g:ide") && g:ide == 0
 finish
endif


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Global Variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if g:ide_mike_mode
  call ide#mikemode#Vars()
endif


" Special constants
let g:MAX_EXTERNAL_WIN = -1
let g:MIN_EXTERNAL_WIN = -3
let g:EXTERNAL_GVIM_ID = -1  " Reserved id for external gvim window
let g:EXTERNAL_TERMINAL_ID = -2  " Reserved id for external terminal window
let g:EXTERNAL_BROWSER_ID = -3  " Reserved id for external browser window
let g:SPLIT_VIEW_ID = -4  " Reserved id for split view window
let g:DIFF_VIEW_ID = -5  " Reserved id for diff view window


" Color schemes
"   Syntax        : [colorscheme, background, bg_color]
"
"     colorscheme : Name of color scheme
"     background  : 'light' or 'dark'
"     bg_color    : Background color override (unset or "" for as is)
if !exists("g:ide_colorschemes")
  let default_colorscheme = ide#util#Os() ==? "mac" ? 'macvim' : 'default'
  let g:ide_colorschemes = [
    \ [default_colorscheme, "light"],
  \]
endif

let g:last_colorscheme = -1


" Filetype settings
"   {
"     filetype: {
"       'colorscheme': (int),
"       'local_settings': (string),
"       'margin_flags': (int),
"       '<def_cmd_impl>': (string),
"     }
"   }
"
"   colorscheme     : Offset into g:ide_colorschemes (or -1 for as is)
"   local_settings  : File specific local settings ("shiftwidth=2 textwidth=80")
"   margin_flags    : -1 (as is), 0 (no margin), 1 (margin), 2 (margin+errorhl)
"   project         : 'projux', 'eclim'
"   search          : 'projux', 'eclim'
"   format          : 'projux', 'eclim'
"   lint            : 'projux', 'eclim', 'pymode'
"   build           : 'projux', 'eclim'
"   test            : 'projux', 'eclim'
"   coverage        : 'projux'
"   run             : 'projux'
"   sanity          : 'projux'
"   errors          : 'syntastic', 'eclim'
if !exists("g:ide_filetype_settings")
  let g:ide_filetype_settings = {
    \ 'default': {
    \     'colorscheme': -1,
    \     'local_settings':  "",
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
    \     'errors': 'syntastic',
    \     'fix': 'eclim',
    \     'gen': 'eclim',
    \     'move': 'eclim',
    \     'rename': 'eclim',
    \     'show': 'eclim',
    \  },
    \ 'diff': {
    \     'colorscheme': 0,
    \     'local_settings':  "wrap",
    \     'margin': 0,
    \  },
    \ 'help': {
    \     'colorscheme': -1,
    \     'local_settings':  "wrap",
    \     'margin': 0,
    \  },
  \}
endif


" Returns the command (format, lint, build, ...) handler for the current
" file. If a command handler cannot be determined then the last one used
" is returned if set. If not set then the default settings are returned.
function! s:IdeCmdHandler(cmd) abort " {{{
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


" Workspace (default searches for 'workspace', 'work', 'source')
if !exists("g:ide_workspace")
  let g:ide_workspace = ""
endif


" On-save commands
if !exists("g:ide_format_on_save")
  let g:ide_format_on_save = 0
endif


" Window position/dimensions
if !exists("g:ide_win_x")
  let g:ide_win_x = 0
endif
if !exists("g:ide_win_y")
  let g:ide_win_y = 0
endif
if !exists("g:ide_win_width")
  let g:ide_win_width = 87
endif
if !exists("g:ide_win_height")
  let g:ide_win_height = 0
endif
if !exists("g:ide_list_win_height")
  let g:ide_list_win_height = 10
endif


" Buffers View
if !exists("g:ide_buffers_view_pos")
  let g:ide_buffers_view_pos = "bottom" " Position
endif
if !exists("g:ide_buffers_view_size")
  let g:ide_buffers_view_size = g:ide_list_win_height  " Size
endif


" Errors View
if !exists("g:ide_errors_view_pos")
  let g:ide_errors_view_pos = "bottom" " Position
endif
if !exists("g:ide_errors_view_size")
  let g:ide_errors_view_size = g:ide_list_win_height  " Size
endif


" Project View
if !exists("g:ide_projects_view_pos")
  let g:ide_projects_view_pos = "bottom"  " Position
endif
if !exists("g:ide_projects_view_size")
  let g:ide_projects_view_size = g:ide_list_win_height  " Size
endif
if !exists("g:ide_projects_buf_pat")
  " projects is projux, ProjectList_ is eclim
  let g:ide_projects_buf_pat = "^projects$|ProjectList_"  " Buffer pattern
endif
if !exists("g:ide_projects_opener")
  function! g:DefaultProjectsOpener(...) abort
    return g:IdeProject("ls")
  endfunction
  let g:ide_projects_opener = "g:DefaultProjectsOpener"  " Opener
endif
if !exists("g:ide_projects_closer")
  function! g:DefaultProjectsCloser(...) abort
    return ide#view#CloseViewWindow('projects')
  endfunction
  let g:ide_projects_closer = "g:DefaultProjectsCloser"  " Closer
endif


" File/Project Explorer View
if !exists("g:ide_explorer_view_pos")
  if g:IdeCmdHandler('project') != "eclim" &&
      \ ide#plugin#PluginExists("nerdtree")
    let g:ide_explorer_view_pos = g:NERDTreeWinPos  " Position
  elseif has("gui_running")
    let g:ide_explorer_view_pos = "right"  " Position
  else
    let g:ide_explorer_view_pos = "bottom"  " Position
  endif
endif
if !exists("g:ide_explorer_view_size")
  if g:IdeCmdHandler('project') != "eclim" &&
      \ ide#plugin#PluginExists("nerdtree")
    let g:ide_explorer_view_size = g:NERDTreeWinSize  " Size
  elseif has("gui_running")
    let g:ide_explorer_view_size = g:ide_win_width  " Size
  else
    let g:ide_explorer_view_size = g:ide_list_win_height  " Size
  endif
endif
if !exists("g:ide_explorer_buf_pat")
  " NERD_tree_ is nerdtree, ProjectTree_ is eclim
  let g:ide_explorer_buf_pat = "NERD_tree_|ProjectTree_"  " Buffer pattern
endif
if !exists("g:ide_explorer_opener")
  function! g:DefaultExplorerOpener(...) abort
    if a:0 == 0 && g:IdeCmdHandler('project') == "eclim"
      return ide#eclim#ToggleProjectExplorer()
    elseif ide#plugin#PluginExists("nerdtree")
      if a:0 > 0
        exec "NERDTree " . a:1
      else
        :NERDTree
      endif
      call ide#view#PositionViewWindow("explorer")
      return
    endif
    call g:IdeMissingPluginError("nerdtree")
  endfunction
  let g:ide_explorer_opener = "g:DefaultExplorerOpener"  " Opener
endif
if !exists("g:ide_explorer_closer")
  function! g:DefaultExplorerCloser() abort
    if g:IdeCmdHandler('project') == "eclim"
      return ide#eclim#ToggleProjectExplorer()
    else
      :NERDTreeClose
      return
    endif
    call g:IdeMissingPluginError("nerdtree")
  endfunction
  let g:ide_explorer_closer = "g:DefaultExplorerCloser"  " Closer
endif


" Outline View
"
" NOTE: Do not try to install both taglist and taglisttoo. Also, taglisttoo
"   does not currently support horizontal views
if !exists("g:ide_outline_view_pos")
  if has("gui_running")
    if ide#plugin#PluginExists("taglist.vim") ||
        \ ide#plugin#PluginExists("taglisttoo")
      let g:ide_outline_view_pos = "g:Tlist_Use_Right_Window ? 'right' : 'left'"
    else
      let g:ide_outline_view_pos = "right"
    endif
  else
    let g:ide_outline_view_pos = "bottom"
  endif
endif
if !exists("g:ide_outline_view_size")
  if ide#plugin#PluginExists("taglist.vim") ||
    \ ide#plugin#PluginExists("taglisttoo")
    let g:ide_outline_view_size = "g:Tlist_WinWidth"  " Size
  elseif has("gui_running")
    let g:ide_outline_view_size = 50
  else
    let g:ide_outline_view_size = g:ide_list_win_height  " Size
  endif
endif
if !exists("g:ide_outline_buf_pat")
  if ide#plugin#PluginExists("taglist.vim") ||
    \ ide#plugin#PluginExists("taglisttoo")
    let g:ide_outline_buf_pat = "TagList"  " Buffer pattern
  else
    let g:ide_outline_buf_pat = ""
  endif
endif
if !exists("g:ide_outline_opener")
  function! g:DefaultOutlineOpener(...) abort
    if ide#plugin#PluginExists("taglisttoo")
      :call taglisttoo#taglist#Taglist()
    elseif ide#plugin#PluginExists("taglist.vim")
      :TlistToggle
      :wincmd j
    else
      let g:ide_outline_opener =
        \ ':call g:IdeMissingPluginError("taglist or taglisttoo")'
    endif
  endfunction
  let g:ide_outline_opener = "g:DefaultOutlineOpener"  " Opener
endif
if !exists("g:ide_outline_closer")
  function! g:DefaultOutlineCloser(...) abort
    if ide#plugin#PluginExists("taglisttoo")
      :call taglisttoo#taglist#Taglist()
    elseif ide#plugin#PluginExists("taglist.vim")
      :TlistToggle
    else
      let g:ide_outline_closer =
        \ ':call g:IdeMissingPluginError("taglist or taglisttoo")'
    endif
  endfunction
  let g:ide_outline_closer = "g:DefaultOutlineCloser"  " Closer
endif


" Terminal View
if !exists("g:ide_mac_terminal")
  let g:ide_mac_terminal = "Terminal"
endif
if !exists("g:ide_mac_browser_min_bounds")
  let g:ide_mac_terminal_min_bounds = [570, 366]
endif
if !exists("g:ide_mac_browser_max_bounds")
  let g:ide_mac_terminal_max_bounds = [570, 900]
endif
if !exists("g:ide_terminal_view_pos")
  if has("gui_running")
    let g:ide_terminal_view_pos = "right" " Position
  else
    let g:ide_terminal_view_pos = "bottom" " Position
  endif
endif
if !exists("g:ide_terminal_view_size")
  if has("gui_running")
    let g:ide_terminal_view_size = 80  " Size
  else
    let g:ide_terminal_view_size = g:ide_list_win_height  " Size
  endif
endif
if !exists("g:ide_terminal_buf_pat")
  if ide#plugin#PluginExists("conque-term")
    function! g:ConqueTermBuf() abort
      if exists("g:ConqueTerm_BufName")
        return substitute(g:ConqueTerm_BufName, "\\", "", "g")
      else
        return ""
      endif
    endfunction
    let g:ide_terminal_buf_pat = ":call g:ConqueTermBuf"
  endif
endif
if !exists("g:ide_terminal_opener")
  function! g:DefaultTerminalOpener() abort
    if ide#util#Os() ==? "mac"
      call ide#mac#OpenTerminal(
        \ g:ide_terminal_view_pos, g:ide_terminal_view_size)
      call ide#view#WindowOpenedCb(g:EXTERNAL_TERMINAL_ID)
      return
    elseif ide#plugin#PluginExists("conque-term")
      call ide#conque_term#OpenTerminal(
        \ g:ide_terminal_view_pos, g:ide_terminal_view_size)
      call ide#view#WindowOpenedCb(bufnr("%"))
      return
    endif
    call g:IdeMissingPluginError("conque-term")
  endfunction
  let g:ide_terminal_opener = "g:DefaultTerminalOpener"  " Opener
endif
if !exists("g:ide_terminal_closer")
  function! g:DefaultTerminalCloser(...) abort
    if ide#util#Os() ==? "mac"
      " For VIM, close means minimize so do nothing unless exit is true
      if a:0 > 0 && a:1
        call ide#mac#CloseTerminal()
      endif
      call ide#view#WindowClosedCb(g:EXTERNAL_TERMINAL_ID)
      return
    elseif ide#plugin#PluginExists("conque-term")
      if a:0 > 0
        call ide#conque_term#CloseTerminal(a:1)
      else
        call ide#conque_term#CloseTerminal()
      endif
      return
    endif
    call g:IdeMissingPluginError("conque-term")
  endfunction
  let g:ide_terminal_closer = "g:DefaultTerminalCloser"  " Closer
endif


" Browser View
if !exists("g:ide_mac_browser")
  let g:ide_mac_browser = "Google Chrome"
endif
if !exists("g:ide_mac_browser_min_bounds")
  let g:ide_mac_browser_min_bounds = [950, 700]
endif
if !exists("g:ide_mac_browser_max_bounds")
  let g:ide_mac_browser_max_bounds = [1100, 800]
endif
if !exists("g:ide_browser_view_pos")
  let g:ide_browser_view_pos = "right" " Position
endif
if !exists("g:ide_browser_view_size")
  let g:ide_browser_view_size = 0  " Size (0 = remainder of screen for mac)
endif
if !exists("g:ide_browser_opener")
  function! g:DefaultBrowserOpener(...) abort
    if ide#util#Os() ==? "mac"
      call ide#mac#OpenBrowser(
        \ g:ide_browser_view_pos, g:ide_browser_view_size)
      if a:0 > 0
        call ide#mac#OpenUrl(a:1)
      endif
      call ide#view#WindowOpenedCb(g:EXTERNAL_BROWSER_ID)
    else
      if a:0 > 0
        exec 'python import webbrowser; webbrowser.open("' . a:1 . '")'
      else
        exec 'python import webbrowser; webbrowser.open("http://google.com")'
      endif
    endif
  endfunction
  let g:ide_browser_opener = "g:DefaultBrowserOpener"  " Opener
endif
if !exists("g:ide_browser_closer")
  function! g:DefaultBrowserCloser(...) abort
    if ide#util#Os() ==? "mac"
      " For VIM, close means minimize so do nothing unless exit is true
      if a:0 > 0 && a:1
        call ide#mac#CloseBrowser()
      endif
      call ide#view#WindowClosedCb(g:EXTERNAL_BROWSER_ID)
    endif
  endfunction
  let g:ide_browser_closer = "g:DefaultBrowserCloser"  " Closer
endif


" Help View
if !exists("g:ide_help_view_pos")
  if has("gui_running")
    let g:ide_help_view_pos = "right" " Position
  else
    let g:ide_help_view_pos = "bottom" " Position
  endif
endif
if !exists("g:ide_help_view_size")
  if has("gui_running")
    let g:ide_help_view_size = g:ide_win_width  " Size
  else
    let g:ide_help_view_size = g:ide_list_win_height  " Size
  endif
endif


" Quickfix View
if !exists("g:ide_quickfix_view_pos")
  let g:ide_quickfix_view_pos = "bottom" " Position
endif
if !exists("g:ide_quickfix_view_size")
  let g:ide_quickfix_view_size = g:ide_list_win_height  " Size
endif


" Location View
if !exists("g:ide_location_view_pos")
  let g:ide_location_view_pos = "bottom" " Position
endif
if !exists("g:ide_location_view_size")
  let g:ide_location_view_size = g:ide_list_win_height  " Size
endif


" Git View
if !exists("g:ide_git_view_pos")
  if has("gui_running")
    let g:ide_git_view_pos = "right"  " Position
  else
    let g:ide_git_view_pos = "bottom"  " Position
  endif
endif
if !exists("g:ide_git_view_size")
  if has("gui_running")
    let g:ide_git_view_size = g:ide_win_width  " Size
  else
    let g:ide_git_view_size = g:ide_list_win_height  " Size
  endif
endif
if !exists("g:ide_git_buf_pat")
  let g:ide_git_buf_pat = "git_|\\\.git"  " Buffer pattern
endif
if !exists("g:ide_git_opener")
  let g:ide_git_opener = "ide#git#OpenGitView"  " Opener
endif
if !exists("g:ide_git_closer")
  let g:ide_git_closer = "ide#git#CloseGitView"  " Opener
endif


" Split View
if !exists("g:ide_split_view_pos")
  if has("gui_running")
    let g:ide_split_view_pos = "right" " Position
  else
    let g:ide_split_view_pos = "bottom" " Position
  endif
endif
if !exists("g:ide_split_view_size")
  if has("gui_running")
    let g:ide_split_view_size = g:ide_win_width  " Size
  else
    let g:ide_split_view_size = g:ide_list_win_height  " Size
  endif
endif


" Diff View
if !exists("g:ide_diff_view_pos")
  if has("gui_running")
    let g:ide_diff_view_pos = "right" " Position
  else
    let g:ide_diff_view_pos = "bottom" " Position
  endif
endif
if !exists("g:ide_diff_view_size")
  if has("gui_running")
    let g:ide_diff_view_size = g:ide_win_width  " Size
  else
    let g:ide_diff_view_size = g:ide_list_win_height  " Size
  endif
endif


" Mirror View
if !exists("g:ide_mirror_view_pos")
  if has("gui_running")
    let g:ide_mirror_view_pos = "right" " Position
  else
    let g:ide_mirror_view_pos = "bottom" " Position
  endif
endif
if !exists("g:ide_mirror_view_size")
  if has("gui_running")
    let g:ide_mirror_view_size = g:ide_win_width  " Size
  else
    let g:ide_mirror_view_size = g:ide_list_win_height  " Size
  endif
endif


" List (General case view)
if !exists("g:ide_list_view_pos")
  let g:ide_list_view_pos = "bottom" " Position
endif
if !exists("g:ide_list_view_size")
  let g:ide_list_view_size = g:ide_list_win_height  " Size
endif
if !exists("g:ide_list_buf_pat")
  let g:ide_list_buf_pat = "_list"  " Buffer pattern
endif
