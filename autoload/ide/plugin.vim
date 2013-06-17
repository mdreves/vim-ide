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

let s:plugin_exists_map = {}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugin Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Checks if plugin exists.
"
" Args:
"   plugin: Plugin name.
"
" Returns:
"   True (1) if plugin exists.
function! ide#plugin#PluginExists(plugin) abort " {{{
  if has_key(s:plugin_exists_map, a:plugin)
    return s:plugin_exists_map[a:plugin]
  endif

  for path in split(&runtimepath, ",")
    if fnamemodify(path, ":t") ==? a:plugin
      let s:plugin_exists_map[a:plugin] = 1
      return s:plugin_exists_map[a:plugin]
    endif
  endfor
  let s:plugin_exists_map[a:plugin] = 0
  return s:plugin_exists_map[a:plugin]
endfunction " }}}


" Returns list of plugins backed by GIT.
"
" Args:
"   a:1: True (1) to return only GIT plugins.
function! ide#plugin#GetPlugins(...) abort " {{{
  let plugins = []
  for path in
      \ (split(&runtimepath, ",") + split(glob("$HOME/.vim/DISABLED/*"), "\n"))
    let file_name = fnamemodify(path, ":t")
    if a:0 > 0 && a:1
      if isdirectory(path . "/.git")
        call add(plugins, file_name)
      endif
    elseif file_name !=? ".vim" && file_name !=? "after" &&
        \ file_name !=? "vimfiles" && file_name !=? "runtime" &&
        \ file_name !=? "plugin"
      call add(plugins, file_name)
    endif
  endfor
  return plugins
endfunction " }}}


" Enables plugin.
"
" Args:
"   plugin: Plugin name.
function! ide#plugin#EnablePlugin(plugin) abort " {{{
  for path in split(glob("$HOME/.vim/DISABLED/*"), "\n")
    if fnamemodify(path, ":t") ==? a:plugin
      call system("mv " . path . " " . path . "/../../bundle")
    endif
  endfor
endfunction " }}}


" Disables plugin.
"
" Args:
"   plugin: Plugin name.
function! ide#plugin#DisablePlugin(plugin) abort " {{{
  for path in split(&runtimepath, ",")
    if fnamemodify(path, ":t") ==? a:plugin
      let disabled_dir = path . "/../../DISABLED"
      if !isdirectory(disabled_dir)
        call mkdir(disabled_dir)
      endif
      call system("mv " . path . " " . disabled_dir)
    endif
  endfor
endfunction " }}}


" Updates plugin.
"
" Args:
"   plugin: Plugin name or 'all' for all plugins.
function! ide#plugin#UpdatePlugin(plugin) abort " {{{
  for path in split(&runtimepath, ",")
    if fnamemodify(path, ":t") ==? a:plugin || a:plugin ==? "all" ||
        \ a:plugin == "*"
      if isdirectory(path . "/.git")
        echom "Updating " . a:plugin
        for line in split(system("cd " . path . "; git pull"), "\n")
          echom line
        endfor
      else
        echoe "Upgrade not supported for this plugin"
      endif
    endif
  endfor
endfunction " }}}


" Installs plugin.
"
" Args:
"   plugin: Plugin repo or 'all' for all required plugins.
function! ide#plugin#InstallPlugin(repo) abort " {{{
  for path in split(&runtimepath, ",")
    if fnamemodify(path, ":t") ==? "vim-ide"
      let install_dir = path . "/.."
      break
    endif
  endfor

  if a:repo ==? "all" || a:repo ==? "*"
    let repos = [
      \ "git://github.com/dhazel/conque-term.git",
      \ "git://github.com/vim-scripts/FuzzyFinder.git",
      \ "git://github.com/vim-scripts/L9.git",
      \ "git://github.com/vim-scripts/mru.vim.git",
      \ "git://github.com/scrooloose/nerdtree.git",
      \ "git://github.com/ervandew/taglisttoo.git",
      \ "git://github.com/klen/python-mode.git",
      \ "git://github.com/tomtom/tcomment_vim.git",
      \ "git://github.com/tpope/vim-fugitive.git",
      \ "git://github.com/xolox/vim-pyref.git",
      \ "git://github.com/mdreves/vim-scaladoc.git",
      \ "git://github.com/xolox/vim-session.git"
    \]
    if g:mike_mode
      " Tab/autocomplete
      call add(repos, "git://github.com/vim-scripts/Pydiction.git")
      call add(repos, "git://github.com/vim-scripts/pythoncomplete.git")
      call add(repos, "git://github.com/msanders/snipmate.vim.git")
      call add(repos, "git://github.com/tsaleh/vim-matchit.git")
      call add(repos, "git://github.com/tpope/vim-repeat.git")
      call add(repos, "git://github.com/tsaleh/vim-supertab.git")
      call add(repos, "git://github.com/tpope/vim-surround.git")

      " Syntax/docs
      call add(repos, "git://github.com/vim-scripts/autoproto.vim.git")
      call add(repos, "git://github.com/vim-scripts/VimClojure.git")
      call add(repos, "git://github.com/itspriddle/vim-jquery.git")

      " NO GIT
      " eclim
      " scala-dist
    endif
  else
    let repos = [a:repo]
  endif

  for git_repo in repos
    for line in split(system("cd " . path . "; git clone " . repo), "\n")
      echom line
    endfor
  endfor
endfunction " }}}
