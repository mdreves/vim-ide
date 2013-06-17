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

let s:syntastic_notifiers = g:SyntasticNotifiers.New()

" Syntastic Lint implementation
function! ide#syntastic#Lint(...) abort " {{{
  if ! ide#plugin#PluginExists("syntastic")
    return ide#util#EchoError("Missing syntastic plugin")
  endif

  if a:0 == 0 || ide#util#NameRangeMatch(a:1, "f", "file") || a:1 ==? "%"
    exec ":SyntasticCheck"
  endif
endfunction " }}}

" Syntastic GetErrors implementation
function! ide#syntastic#GetErrors(...) abort " {{{
  if ! ide#plugin#PluginExists("syntastic")
    return ide#util#EchoError("Missing syntastic plugin")
  endif

  if a:0 == 0 || a:1 ==? 'lint'
    exec ":Errors"
  endif
endfunction " }}}

" Uses syntastic to display errors
"
" Args:
"   list_type: List to get locations form ('quickfix' or 'location')
function! ide#syntastic#DisplayErrors(list_type) abort " {{{
  if ide#plugin#PluginExists("syntastic")
    if a:list_type == 'quickfix'
      let err_list = getqflist()
    else
      let err_list = getloclist(0)
    endif

    let loclist = g:SyntasticLoclist.New(err_list)
    call s:syntastic_notifiers.refresh(loclist)
  endif

  let num_errors = len(getloclist(0))
  if num_errors == 1
    echo "1 error"
  elseif num_errors > 1
    echo num_errors . " errors"
  else
    echo "No errors"
  endif

  if exists("g:syntastic_auto_loc_list")
    if num_errors > 0
      if g:syntastic_auto_loc_list == 1
        call ide#view#OpenView("location")
      endif
    else
      if g:syntastic_auto_loc_list > 0
        call ide#view#CloseView("location")
      endif
    endif
  endif
endfunction " }}}
