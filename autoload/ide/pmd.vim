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

" Initializes PMD variables
function! ide#pmd#Init() abort " {{{
  let s:initialized = 1

  if !exists("g:ide_pmd_cmd")
    let g:ide_pmd_cmd = "pmd"
  endif
  if !exists("g:ide_pmd_rulesets")
    let g:ide_pmd_rulesets = "ruleset/basic.xml"
  endif
endfunction " }}}


" PMD Lint implementation
function! ide#pmd#Lint(...) abort " {{{
  if ! s:initialized
    call ide#pmd#Init()
  endif

  let idx = 0
  if a:0 == 0 || ide#util#NameRangeMatch(a:1, "f", "file") || a:1 ==? "%"
    let a:target = "file"
    let idx += 1
  elseif ide#util#NameRangeMatch(a:1, "d", "dir") || a:1 ==? "%/"
    let a:target = "dir"
    let idx += 1
  elseif ide#util#NameRangeMatch(a:1, "p", "project") ||
      \ ide#util#NameRangeMatch(a:1, "a", "all") || a:1 ==? "*"
    let a:target = "project"
    let idx += 1
  endif

  if ide#util#NameRangeMatch(a:000[idx], "p", "pmd")
    let save_cpoptions = &cpoptions
    let save_format = &errorformat

    "command -nargs=? -complete=file Pmd :return <SID>Pmd_Run(<f-args>)
    set cpoptions-=F
    set errorformat=%f\ %l\ %m
    let tmp = tempname()
    if a:0 == 0
      let cmd = g:ide_pmd_cmd . " " . expand("%") . " text " .
        \ g:ide_pmd_rulesets
    else
      let cmd = g:ide_pmd_Cmd . " " . a:1 . " text " . g:ide_pmd_rulesets
    endif
    exe "silent !" . cmd . " > " . tmp
    exe "lfile " . tmp
    return delete(tmp)

    let &cpoptions = save_cpoptions
    let &errorformat = save_format
    return
  endif
endfunction " }}}
