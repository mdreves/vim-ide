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
" Conque term specific functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Opens conque-term terminal.
"
" Args:
"   pos: 'right', 'left', 'top', 'bottom'
"   size: Size in lines (if pos top/bottom) or chars (if pos right/left)
function! ide#conque_term#OpenTerminal(pos, size) abort " {{{
  call ide#util#OpenSplitWindow(a:pos, a:size)
  let existing_buf = 0
  for buf_num in keys(ide#util#GetBufferNamesByNum())
    if getbufvar(buf_num + 0, "&filetype") ==# "conque_term"
      let existing_buf = buf_num + 0
      break
    endif
  endfor
  if existing_buf != 0
    exec ":buffer " . existing_buf
  else
    :ConqueTerm bash
  endif
  if exists("g:ConqueTerm_Syntax") && ! empty(g:ConqueTerm_Syntax)
    syntax enable
    exec "colorscheme " . g:ConqueTerm_Syntax
  endif
endfunction " }}}

" Closes conque-term terminal.
"
" Args:
"   a:1: True if terminal should exit (default is hide)
function! ide#conque_term#CloseTerminal(...) abort " {{{
  let buf_name = substitute(g:ConqueTerm_BufName, '\\', '', 'g')
  let buf_win_num = bufwinnr(buf_name)
  if buf_win_num != -1
    exec buf_win_num . " wincmd w"
    if a:0 > 0 && a:1
      exec ":bw"
      call conque_term#get_instance().close()
    else
      exec ":q"
    endif
  endif
endfunction " }}}
