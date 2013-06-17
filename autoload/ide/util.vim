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

" Ugly side-effecting state variables...
let s:last_gen_id = 0  " Monotonically increasing counter to provide unique ids
let s:invoke_later_stack = []  " Stack of commands that need to be invoked
let s:MAX_INVOKE_LATER_STACK = 10

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General Purpose Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Gets OS type.
function! ide#util#Os() abort " {{{
  if has("mac") || has("macunix")
    return "mac"
  elseif has("unix")
    return "linux"
  elseif has("win32") || has("win64")
    return "win"
  else
    if split(system("uname"))[0] == "Darwin"
      return "mac"
    else
      return "unknown"
    endif
  endif
endfunction " }}}


" Generates an id that is unique amongst other id's generated
function! ide#util#GenId() abort " {{{
  let s:last_gen_id += 1
  return s:last_gen_id
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Eval/Invocation Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Evalulates a callable expression.
"
" A callable expression is either a function (which is called directly)
" or a command that is exected.
"
" Args:
"   fn_or_cmd: Function name or command expr (commands must start with ':').
"   ... : additional args if fn is used.
function! ide#util#EvalCall(fn_or_cmd, ...)
  if a:fn_or_cmd[0] ==? ":"
    if a:0 > 0
      exec a:fn_or_cmd . " " . a:1
    else
      exec a:fn_or_cmd
    endif
  else
    return call(a:fn_or_cmd, a:000)
  endif
endfunction


" Evaluates a variable either by reading directly or executing command.
"
" Args:
"   var_or_cmd: Var or command expr (commands must start with ':').
function! ide#util#EvalVar(var_or_cmd)
  if type(a:var_or_cmd) != type("")
    let var_or_cmd = string(a:var_or_cmd)
  else
    let var_or_cmd = a:var_or_cmd
  endif

  if var_or_cmd[:4] ==? ":call"
    return ide#util#EvalCall(var_or_cmd[6:])
  elif var_or_cmd[0] ==? ":"
    redir => result
    silent! exec var_or_cmd[1:]
    redir END

    return split(result, '\n')[0]
  else
    return a:var_or_cmd
  endif
endfunction


" Evaluates a variable and a pattern and checks for match.
"
" Args:
"   var_or_cmd: Var or var command expr (commands must start with ':').
"   pat_or_cmd: Pattern or pattern command expr (commands must start with ':').
"     Multiple patterns to match may be separated by |
function! ide#util#EvalPatternMatch(var_or_cmd, pat_or_cmd)
  let var = ide#util#EvalVar(a:var_or_cmd)
  let pat = ide#util#EvalVar(a:pat_or_cmd)
  for value in split(pat, "|")
    if var =~ value
      return 1
    endif
  endfor
  return 0
endfunction


" This function allows the creation of lowercase user commands.
"
" Shortcuts are created for all combinations between the start of the
" abbreviation and the end. For example, if start is 'fo' and end is 'foo'
" then abbreviations will be mapped for both 'fo' and 'foo'.
"
" Args:
"   start_abbr: Start of abbreviation.
"   end_abbr: End of abbreviation.
"   expansion: Expansion.
function! ide#util#LowercaseUserCmd(start_abbr, end_abbr, expansion) abort " {{{
  for offset in range(len(a:start_abbr) - 1, len(a:end_abbr) - 1)
    let abbreviation = a:end_abbr[:offset]
    exec "cabbr " . abbreviation .
      \ ' <c-r>=getcmdpos() == 1 && getcmdtype() == ":" ? "' .
      \ a:expansion . '" : "' . abbreviation . '"<cr>'
  endfor
endfunction " }}}


" Invoke a command to run later (similar to Swing invokeLater)
"
" Args:
"   cmd: Command to invoke
"   a:1: Time to wait (milliseconds)
function! ide#util#InvokeLater(cmd, ...) abort " {{{
  " Only support a limited stack deep
  if len(s:invoke_later_stack) > s:MAX_INVOKE_LATER_STACK
    return
  endif

  call add(s:invoke_later_stack, a:cmd)

  if exists("s:invoke_later_updatetime")
    " Another invoke in progress, put on stack...
    return
  endif

  let s:invoke_later_updatetime = &updatetime
  let &updatetime = a:0 > 0 ? a:1 : 1

  call ide#util#InvokeLaterWait()
endfunction " }}}

function! ide#util#InvokeLaterWait() " {{{
  augroup ide_invoke_later_augroup
    autocmd CursorHold *
      \ if exists("s:invoke_later_updatetime") |
      \   let &updatetime = s:invoke_later_updatetime |
      \   unlet s:invoke_later_updatetime |
      \ endif |
      \ if len(s:invoke_later_stack) > 0 |
      \   let stack = s:invoke_later_stack |
      \   let s:invoke_later_stack = [] |
      \   call ide#util#InvokeCmds(stack) |
      \ endif |
      \ autocmd! ide_invoke_later_augroup
  augroup END
endfunction " }}}

function! ide#util#InvokeCmds(cmds) abort " {{{
  for cmd in a:cmds
    exec cmd
  endfor

  if len(s:invoke_later_stack) > 0
    " more tasks added, recursive call to invoke later
    let s:invoke_later_updatetime = &updatetime
    let &updatetime = 1
    call ide#util#InvokeLaterWait()
  endif
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Text Selection Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Returns currently selected text.
"
" The sel_mode is intended to be passed through from an operatorfunc callback
" ('line', 'char', 'block') or a visualmode() callback ('v', 'V'). In addition
" the special mode 'expr' is supported for use with formatexpr, etc where the
" v:lnum, v:count, and v:char variables will be set.
"
" Args:
"   sel_mode: 'v' charwise visual, 'V' linewise visual, 'char' charwise
"     motion, 'line' linewise motion, 'block' for blockwise motion,
"     'expr' for formatexpr, 'cword' for <cWORD>, 'clear" to clear
"   a:1: True to return <cWORD> if no visual selection.
"
" Returns:
"   String of currently selected text.
function! ide#util#GetSelectedText(sel_mode, ...) abort " {{{
  if a:sel_mode ==? "expr"
   if ! empty(v:char)
      return ""  " we don't suppport automatic formatting
    endif

    return join(getline(v:lnum, v:lnum + v:count - 1), "\n")
  endif

  let saved_unnamed_register = getreg('@"')  " Don't overwrite what user has...
  let saved_unnamed_register_type = getregtype('@"')
  let saved_selection = &selection
  let &selection = "inclusive"

  " Yank visualy selected text
  if a:sel_mode ==# "v"
    silent exec "normal! `<v`>y"
  elseif a:sel_mode ==# "V"
    silent exec "normal! `<V`>y"
  elseif a:sel_mode ==# "char"
    silent exec "normal! `[v`]y"
  elseif a:sel_mode ==# "line"
    silent exec "normal! `[V`]y"
  elseif a:sel_mode ==# "block"
    silent exec "normal! `[\<C-V>`]y"
  elseif a:sel_mode ==? "cword" || a:0 > 0 && a:1
    " Word under cursor
    call setreg('@"', expand("<cWORD>"))
  else
    echoerr "Unknown selection mode: " . a:sel_mode
  endif

  let text_selection = getreg('@"')

  let &selection = saved_selection
  call setreg('@"', saved_unnamed_register, saved_unnamed_register_type)

  return text_selection
endfunction " }}}


" Gets selected text over range a,b (or visual selection '<,'>)
"
" Args:
"   a:firstline: First line in range
"   a:lastline: Last line in range
"
" Returns:
"   Currently selected text.
function! ide#util#GetSelectedTextRange() range abort " {{{
  return ide#util#GetSelectedText(visualmode())
endfunction " }}}


" Replaces selected text by text output form given shell cmd
"
" Args:
"   lnum: Starting num num
"   count: Number of lines
"   cmd: Shell command to run
"
" Returns:
"   Shell exit code
function! ide#util#ReplaceSelectedText(lnum, count, cmd) abort " {{{
  let text = join(getline(a:lnum, a:lnum + a:count - 1), "\n")
  " The following runs a command with the given text as stdin
  let results = system(a:cmd, text)
  if v:shell_error == 0
    let cur_line = line(".")
    let i = a:lnum
    for line in split(results, "\n")
      if i < a:lnum + a:count
        call setline(i, line)
      else
        call append(i - 1, line)
      endif
      let i += 1
    endfor
    " delete extra lines
    if i <= a:lnum + a:count - 1
      for lnum in range(i, a:lnum + a:count - 1)
        exec ":" . i . "d"
      endfor
    endif
    if cur_line <= line("$")
      exec ":" . cur_line
    endif
  endif
  return v:shell_error
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer/File Selection, Locations display
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Choose file from buffer list.
"
" Buffers can be opened with e/E (edit), s (split), t(tab), d/D (diff). They
" can be deleted with x (delete).
"
" Args:
"   no_hidden: True (1) to filter out hidden files.
"   buffer_name: Name of temp buffer used to display buffer list.
"   win_pos: Position of temp window ('left', 'right', 'top', 'bottom').
"   win_size: Width (left/right) or height (top/bottom) of temp window.
"   action_cb: Function called when action (e/E, s, etc) used on a chosen
"     buffer. It is passed the action used ('e', 'E', 't', etc), the buffer
"     num, and the buffer name as args.
"   a:1: Default action on enter.
function! ide#util#ChooseBuffer(
    \ no_hidden, buffer_name, win_pos, win_size, action_cb, ...)
  if a:no_hidden
    let tmp_names = []
    let names = []
    let nums = []
    for item in items(ide#util#GetBufferNamesByNum(a:no_hidden))
      if item[1] == "[No Name]"
        call add(tmp_names, item[1])
      else
        call add(tmp_names, fnamemodify(bufname(item[1]), ":p"))
      endif
      call add(nums, item[0] + 0)
    endfor

    if len(tmp_names) == 1
      let cur = 1
      " Flag modified files with a '*'
      if getbufvar(nums[0], "&mod")
        let names = ["*" . fnamemodify(tmp_names[0], ":p:t")]
      else
        let names = [" " . fnamemodify(tmp_names[0], ":p:t")]
      endif
    else
      let base_path = ide#util#GetCommonPath(tmp_names)
      let tmp_names = ide#util#RemoveCommonPath(base_path, tmp_names)
      let name_num_map = {}
      let i = 0
      for name in tmp_names
        if name == ''
          let name = 'No Name'  " can't have empty keys in dict
        endif
        let name_num_map[name] = nums[i]
        let i += 1
      endfor
      let tmp_names = sort(tmp_names)
      let nums = []
      let cur = 1
      let i = 1
      for name in tmp_names
        if name == ''
          let name = 'No Name'
        endif
        if name_num_map[name] == bufnr('')
          let cur = i
        endif
        call add(nums, name_num_map[name])
        " Flag modified files with a '*'
        if getbufvar(name_num_map[name], "&mod")
          call add(names, "*" . name)
        else
          call add(names, " " . name)
        endif
        let i = i + 1
      endfor
    endif

    let win_size = max([min([a:win_size, len(names)]), 3])
    call ide#util#OpenReadonlyWindow(
        \ a:buffer_name, names, a:win_pos, win_size, cur)
  else
    let names = []
    let nums = []
    for item in items(ide#util#GetBufferNamesByNum(a:no_hidden))
      if item[1] !=? "buffers"
        if getbufvar(item[0], "&mod")
          call add(
            \ names, item[0] . (len(item[0]) == 1 ? "*  " : "* ") . item[1])
        else
          call add(
            \ names, item[0] . (len(item[0]) == 1 ? "   " : "  ") . item[1])
        endif
        call add(nums, item[0])
      endif
    endfor

    let win_size = max([min([a:win_size, len(names)]), 3])
    call ide#util#OpenReadonlyWindow(
        \ a:buffer_name, names, a:win_pos, win_size)
  endif

  let w:action_cb = a:action_cb
  let w:buf_nums = nums
  let w:buf_count = len(nums)

  let w:default_action = "e"
  if a:0 > 0
    let w:default_action = a:1
  endif

  " map q to close window
  nnoremap <silent> <buffer> q
    \ :call ide#util#CloseWindow(bufname(''))<CR>

  " map x to delete
  nnoremap <silent> <buffer> x
    \ :let curbuf = bufname('') \|
    \ :let buf = w:buf_nums[line('.') - 1] \|
    \ :call remove(w:buf_nums, line('.') - 1) \|
    \ :set modifiable \|
    \ :silent exec line('.') . "d _" \|
    \ :set nomodifiable \|
    \ :let buf_count = len(w:buf_nums) \|
    \ :wincmd w \|
    \ if buf_count == 0 \|
      \ :exec "qa" \|
    \ elseif buf == bufnr('') \|
      \ call ide#util#CloseWindow(curbuf) \|
      \ :exec "bd " . buf \|
    \ else \|
      \ :exec "bd " . buf \|
      \ :wincmd w \|
    \ endif<CR>

  " map enter to default action
  nnoremap <silent> <buffer> <cr> :call feedkeys(w:default_action)<CR>

  " map t to open tab
  nnoremap <silent> <buffer> t
    \ :call <SID>InvokeActionOnBuffer('t', w:action_cb, w:buf_nums)<CR>

  " map s to open split view
  nnoremap <silent> <buffer> s
    \ :call <SID>InvokeActionOnBuffer('s', w:action_cb, w:buf_nums)<CR>

  " map e to edit in current window
  nnoremap <silent> <buffer> e
    \ :call <SID>InvokeActionOnBuffer('e', w:action_cb, w:buf_nums)<CR>

  " map E to edit in current window
  nnoremap <silent> <buffer> E
    \ :call <SID>InvokeActionOnBuffer('E', w:action_cb, w:buf_nums)<CR>

  " map d to open diff
  nnoremap <silent> <buffer> d
    \ :call <SID>InvokeActionOnBuffer('d', w:action_cb, w:buf_nums)<CR>

  " map D to edit in current window
  nnoremap <silent> <buffer> D
    \ :call <SID>InvokeActionOnBuffer('D', w:action_cb, w:buf_nums)<CR>
endfunction " }}}


" Invokes action on currently selected buffer.
"
" Args:
"   action: Action ('e', 'E', 't', 's', 'd', 'D').
"   action_cb: Action callback.
function! s:InvokeActionOnBuffer(action, action_cb, buf_nums) abort " {{{
  let buf_num = w:buf_nums[line('.') - 1]
  let buf_name = bufname('')
  exec winnr("#") . " winc w"
  call ide#util#CloseWindow(buf_name)
  call call(a:action_cb, [a:action, buf_num, bufname(buf_num)])
endfunction " }}}


" Opens temporary window for choosing file.
"
" Args:
"   buffer_name: Name to use for temporary buffer.
"   win_pos: Position of temp window ('left', 'right', 'top', 'bottom').
"   win_size: Width (left/right) or height (top/bottom) of temp window.
"   base_path: Base path of file names given.
"   file_names: List of file names to display
"   action_cb: Action callback called when selection made. The callback is
"     passed the action chosen ('t', 's', etc) and the filename chosen.
"   default_action: Default action when <CR> used ('t', 's', 'e', 'd'). If
"     a function is passed then the function will be called with the selected
"     file as an argument.
function! ide#util#ChooseFile(
    \ buffer_name, win_pos, win_size, base_path, file_names,
    \ action_cb, ...) abort " {{{
  if len(a:file_names) == 1 && empty(a:file_names[0])
    let names = [ide#util#SafeExpand(a:base_path)]
    let base = ""
  else
    let names = a:file_names
    let base = a:base_path
  endif

  call ide#util#OpenReadonlyWindow(a:buffer_name, names, a:win_pos, a:win_size)

  let w:action_cb = a:action_cb

  let w:default_action = "t"
  if a:0 > 0
    let w:default_action = a:1
  endif
  if len(names) == 1 && type(w:default_action) != 2 &&
      \ ide#util#IsDir(empty(base) ? names[0] : base . "/" . names[0])
    let w:default_action = "e"
  endif
  let w:base_path = base

  " map q to close window
  nnoremap <silent> <buffer> q
    \ :call ide#util#CloseWindow(bufname(''))<CR>

  if type(w:default_action) == 2

    " map enter to call funcref
    nnoremap <silent> <buffer> <cr>
      \ :if empty(w:base_path) \|
      \   let file_name = getline('.') \|
      \ else \|
      \   let file_name = w:base_path . '/' . getline('.') \|
      \ endif \|
      \ call ide#util#CloseWindow(bufname('')) \|
      \ call w:default_action(file_name)<CR>

  else

    " map enter to default action
    nnoremap <silent> <buffer> <cr> :call feedkeys(w:default_action)<CR>

  endif

  " map t to open tab
  nnoremap <silent> <buffer> t
    \ :call <SID>InvokeActionOnFile('t', w:action_cb, w:base_path)<CR>

  " map s to open split view
  nnoremap <silent> <buffer> s
    \ :call <SID>InvokeActionOnFile('s', w:action_cb, w:base_path)<CR>

  " map e to edit in current window
  nnoremap <silent> <buffer> e
    \ :call <SID>InvokeActionOnFile('e', w:action_cb, w:base_path)<CR>

  " map E to edit in new GVIM window
  nnoremap <silent> <buffer> E
    \ :call <SID>InvokeActionOnFile('E', w:action_cb, w:base_path)<CR>

  " map d to open diff
  nnoremap <silent> <buffer> d
    \ :call <SID>InvokeActionOnFile('d', w:action_cb, w:base_path)<CR>

  " map D to open gvimdiff
  nnoremap <silent> <buffer> D
    \ :call <SID>InvokeActionOnFile('D', w:action_cb, w:base_path)<CR>
endfunction " }}}


" Invokes action on currently selected file.
"
" Args:
"   action: Action ('e', 'E', 't', 's', 'd', 'D').
"   action_cb: Action callback.
"   base_path: Base path.
function! s:InvokeActionOnFile(action, action_cb, base_path) abort " {{{
  if empty(a:base_path)
    let file_name = getline('.')
  else
    let file_name = a:base_path . '/' . getline('.')
  endif
  let buf_name = bufname('')
  exec winnr("#") . " winc w"
  call ide#util#CloseWindow(buf_name)
  call call(a:action_cb, [a:action, file_name])
endfunction " }}}


" Make location list.
"
" Creates a setloclist/setqflist compatible location list from a list of
" lines of the form: <filename>:<line>:<col>:<message> ({E|W}xxx).
" The <col> and ({E|W}xxx) portions are optional.
"
" Args:
"   lines: List of lines.
"   a:1: 1 to add type/nr for errors (default), 0 to not add
"
" Returns:
"   Dict with keys: 'filename', 'valid', 'lnum', 'text'
"   and optional keys: 'bufnr', 'col', 'type', 'nr'
function! ide#util#MakeLocationList(lines, ...)
  let llist = []
  for l in a:lines
    let entry = {}
    let parts = split(l, ":")
    if len(parts) < 3
      continue
    endif

    " Trim spaces from ends of filename
    let entry['filename'] = substitute(parts[0], '^\s*\(.\{-}\)\s*$', '\1', '')
    let bufnr = bufnr(entry['filename'])
    if bufnr != -1
      let entry['bufnr'] = bufnr
    endif
    let entry['valid'] = 1
    let entry['lnum'] = substitute(parts[1], '^\s*\(.\{-}\)\s*$', '\1', '')
    if len(parts) > 3 && parts[2] + 0 != 0
      let entry['col'] = parts[2]
      let slice_idx = 3
    else
      let slice_idx = 2
    endif
    let txt = join(parts[(slice_idx+0):], ":")

    " Search for ending (Exxx) or (Wxxx)
    if a:0 == 0 || a:1 == 1
      let entry['type'] = 'E'
      let err_info_idx = strridx(txt, "(")
      if err_info_idx != -1 && len(txt) > err_info_idx + 3
        let type = txt[err_info_idx + 1]
        let errnr = strpart(txt, err_info_idx + 2)
        let err_info_end = strridx(errnr, ")")
        if err_info_end != -1
          let errnr = strpart(errnr, 0, err_info_end)
          if errnr + 0 != 0
            " Syntastic only likes 'W' or 'E' not 'C', etc
            let entry['type'] = type == 'W' ? 'W' : 'E'
            let entry['nr'] = errnr
            let txt = strpart(txt, 0, err_info_idx)
          endif
        endif
      endif
    endif

    " Trim spaces from ends of text
    let entry['text'] = substitute(txt, '^\s*\(.\{-}\)\s*$', '\1', '')

    call add(llist, entry)
  endfor

  return llist
endfunction " }}}


" Show list of locations.
"
" Args:
"   list_type: List to get locations form ('quickfix' or 'location')
"   buffer_name: Name of temp buffer used to display list.
"   win_pos: Position of temp window ('left', 'right', 'top', 'bottom').
"   win_size: Width (left/right) or height (top/bottom) of temp window.
function! ide#util#ShowLocations(list_type, buffer_name, win_pos, win_size)
  if a:list_type == 'quickfix'
    let err_list = getqflist()
  else
    let err_list = getloclist(0)
  endif

  " If locations are all for the cur file then don't show file name, else
  " show files but remove common path
  let show_file = 0
  let cur_buf = bufnr('')
  let file_names = []
  for item in err_list
    if ! item['valid']
      continue
    endif

    if item['bufnr'] != cur_buf
      let show_file = 1
    endif

    let name = bufname(item['bufnr'])
    if name == "[No Name]"
      call add(file_names, name)
    else
      call add(file_names, fnamemodify(name, ":p"))
    endif
  endfor

  if show_file
    let base_path = ide#util#GetCommonPath(file_names)
    let file_names = ide#util#RemoveCommonPath(base_path, file_names)
  endif

  let err_prefixes = []
  let fileline_prefixes = []
  let i = 0
  let max_err_len = 0
  let max_fileline_len = 0
  for item in err_list
    if ! item['valid']
      continue
    endif

    let err_prefix = toupper(item['type'])
    if item['nr'] != -1 && item['nr'] != 0
      let err_prefix .= item['nr']
    endif
    if ! empty(err_prefix)
      let err_prefix .= ' '
    endif

    let max_err_len = max([strlen(err_prefix), max_err_len])
    call add(err_prefixes, err_prefix)

    if show_file
      let fileline_prefix = file_names[i] . ':' . item['lnum']
    else
      let fileline_prefix = item['lnum']
    endif
    let max_fileline_len = max([strlen(fileline_prefix), max_fileline_len])
    call add(fileline_prefixes, fileline_prefix)
    let i += 1
  endfor

  let lines = []
  let i = 0
  let padding = '                                                             '
  for item in err_list
    if ! item['valid']
      continue
    endif

    let line = ' '  " Start with a space
    let line .=
        \ err_prefixes[i] .
        \ strpart(padding, 0, max_err_len - len(err_prefixes[i]))
    if max_err_len > 0
      let line .= '| '
    endif
    let line .= fileline_prefixes[i] .
        \ strpart(padding, 0, max_fileline_len - len(fileline_prefixes[i]))
    if max_err_len > 0
        let line .= ' |'
    endif
    let line .= ' ' . item['text']
    call add(lines, line)
    let i += 1
  endfor

  let win_size = max([min([a:win_size, len(lines)]), 3])
  call ide#util#OpenReadonlyWindow(
      \ a:buffer_name, lines, a:win_pos, win_size)

  " Add some basic highlighting
  call matchadd("Number", '[ :[]\zs\d\+\ze')
  call matchadd("String", "'.*'")
  call matchadd("String", '".*"')
  " NOTE: \zs means start pattern match and \ze means end it
  "    These highlight the W/Exxx parts of lines starting with ' W/Exxx |'
  call matchadd("WarningMsg", '^ \zsW[0-9 ]*\ze |')
  call matchadd("ErrorMsg", '^ \zs[A-VX-Z][0-9 ]*\ze |')

  let w:list_type = a:list_type

  " map q to close window
  nnoremap <silent> <buffer> q
    \ :call ide#util#CloseWindow(bufname(''))<CR>

  " map enter to jump to location
  nnoremap <silent> <buffer> <cr>
    \ :if w:list_type == 'quickfix' \|
      \ let cmd = "cc " . line('.') \|
    \ else \|
      \ let cmd = "ll " . line('.') \|
    \ endif \|
    \ call ide#util#CloseWindow(bufname('')) \|
    \ exec cmd \|
    \ call ide#syntastic#DisplayErrors('location')<CR>
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Window/Buffer Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Sets window dimensions.
"
" Args:
"   a:1 : width.
"   a:2 : height.
function! ide#util#SetWinDimensions(...) abort " {{{
  if a:0 > 0
    let g:ide_win_width = a:1
  endif
  if a:0 > 1
    let g:ide_win_height = a:2
  endif
  exec "set columns=" . g:ide_win_width . " lines=" . g:ide_win_height
endfunction " }}}


" Sets window position.
"
" Args:
"   a:1 : x.
"   a:2 : y.
function! ide#util#SetWinPosition(...) abort " {{{
  if a:0 > 0
    let g:ide_win_x = a:1
  endif
  if a:0 > 1
    let g:ide_win_y = a:2
  endif
  exec "winpos " . g:ide_win_x . " " . g:ide_win_y
endfunction " }}}


" Returns current buffer names by num.
"
" VIM doesn't support getting the buffer name for quickfix windows, this does.
"
" Args:
"   a:1 : True to only get visible (default False).
" Returns:
"   {buf_num: buf_name}.
function! ide#util#GetBufferNamesByNum(...) abort " {{{
  if a:0 == 1 && a:1
    redir => buflist_str
    silent! ls
    redir END
  else
    redir => buflist_str
    silent! ls!
    redir END
  endif

  let buflist = split(buflist_str, "\n")
  let results = {}
  for line in buflist
    let data = split(line, '"')
    let buf_num = split(data[0])[0] + 0  " remove spaces and convert to int
    if len(data) > 1
      let buf_name = data[1]
    else
      let buf_name = ""
    endif
    let results[buf_num] = buf_name  " Note: dict converts buf_num to str
  endfor
  return results
endfunction " }}}


" Gets list of visible buffers.
"
" Returns:
"   Dictionary of {buf_num: buf_name} of buffers that are visible.
function! ide#util#GetVisibleBuffers() abort " {{{
  let results = {}
  for tab_num in range(1, tabpagenr("$"))
    for buf_num in tabpagebuflist(tab_num)
      let results[buf_num] = bufname(buf_num)
    endfor
  endfor
  return results
endfunction " }}}


" Gets list of loaded but not visible buffers
"
" Returns:
"   Dictionary of {buf_num: buf_name} of bufs that are loaded by not visible.
function! ide#util#GetHiddenBuffers() abort " {{{
  let results = {}
  let visible_bufs = ide#util#GetVisibleBuffers()
  for buf_num in range(1, bufnr("$"))
    if bufloaded(buf_num) && !has_key(visible_bufs, buf_num)
      let results[buf_num] = bufname(buf_num)
    endif
  endfor
  return results
endfunction " }}}


" Gets list of file related buffers.
"
" Args:
"  a:1 : 1 to skip "[No Name]" buffers.
function! ide#util#GetOpenFileBuffers(...) abort " {{{
  let results = []
  let bufs = ide#util#GetBufferNamesByNum(1)
  for item in items(bufs)
    if empty(getbufvar(item[0]+0, "&buftype")) &&
        \ ! (a:0 > 0 && a:1 && item[0] == "[No Name]")
      call add(results, item[1])
    endif
  endfor
  return results
endfunction " }}}


" Closes named buffer.
"
" Args:
"   buf_name: Buffer name.
"
" Returns:
"   1 if success, 0 if not found.
function! ide#util#CloseBuffer(buf_name) "{{{
  let buf_num = bufnr("^" . a:buf_name . "$")
  if buf_num != -1
    exec "bd " . buf_num
    return 1
  endif
  return 0
endfunction " }}}


" Opens named readonly window for displaying data in.
"
" Args:
"   buf_name: Buffer name.
"   data: Data to display into window.
"   pos : 'left, 'right', 'top', 'bottom'
"   size: width (left/right) or height (top/bottom)
"   a:0: Cursor line (default 1)
function! ide#util#OpenReadonlyWindow(
    \ buf_name, data, pos, size, ...) abort " {{{
  let prev_win_num = winnr()
  let prev_file = expand("%:p")

  if bufwinnr(a:buf_name) == -1
    let modifier = ide#util#GetVimOpenModifiers(a:pos)
    exec modifier . " " . a:size . " sview " . escape(a:buf_name, " []")

    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal nowrap
    setlocal winfixheight
    setlocal nobuflisted
    setlocal noswapfile
    silent doautocmd WinEnter
  else
    let buf_win_num = bufwinnr(a:buf_name)
    if buf_win_num != winnr()
      exec buf_win_num . " wincmd w"
      silent doautocmd WinEnter
    endif
  endif

  call ide#util#ClearWindow(a:buf_name)

  setlocal noreadonly
  setlocal modifiable
  call append(1, a:data)
  silent 1,1delete _
  retab
  if a:0 > 0
    call cursor(a:1, 1)
  else
    call cursor(1, 1)
  endif
  setlocal readonly
  setlocal nomodifiable
  setlocal nomodified

  silent doautocmd BufEnter

  if prev_file != expand("%:p")
    let b:prev_win_num = prev_win_num
    let b:prev_file = prev_file

    augroup ide_readonly_window_augroup
      autocmd! BufWinLeave <buffer>
      exec "autocmd BufWinLeave <buffer> " .
        \ 'call ide#util#SelectWindow("' . escape(b:prev_file, '\') . '")' .
        \ " | doautocmd BufEnter"
    augroup END
  endif
endfunction " }}}


" Reopens a hidden buffer in a new window.
"
" NOTE: This won't work for some windows (help, taglist, etc)
"
" Args:
"   buf_num: Buffer number.
"   pos: Position to open in ('left', 'right', 'top', 'bottom')
"   size: Size of window
function! ide#util#ReopenWindow(buf_num, pos, size) abort " {{{
  " Check if buffer already has window, if so go to it
  let win_num = bufwinnr(a:buf_num)
  if win_num != -1
    exec win_num . " wincmd w"
    return
  endif

  " Open window
  let modifier = ide#util#GetVimOpenModifiers(a:pos)
  if a:pos ==? "top" || a:pos ==? "bottom"
    exec modifier . " new | " . a:size
  else
    exec modifier . " new"
  endif

  exec "open " . bufname(a:buf_num)
  call ide#util#WindowOpened(a:buf_num)
endfunction " }}}


" Closes first window associated with named buffer.
"
" Args:
"   buf_name: Buffer name.
"
" Returns:
"   1 if selected, 0 if not found.
function! ide#util#CloseWindow(buf_name) "{{{
  let buf_win_num = bufwinnr(bufnr("^" . a:buf_name . "$"))
  if buf_win_num != -1
    exec buf_win_num . " wincmd w"
    exec "q"
    return 1
  endif
  return 0
endfunction " }}}


" Selects first window associated with named buffer.
"
" Args:
"   buf_name: Buffer name.
"
" Returns:
"   1 if selected, 0 if not found.
function! ide#util#SelectWindow(buf_name) "{{{
  let buf_win_num = bufwinnr(bufnr("^" . a:buf_name . "$"))
  if buf_win_num != -1
    exec buf_win_num . " wincmd w"
    return 1
  endif
  return 0
endfunction " }}}


" Clears first window associated with named buffer.
"
" Args:
"   buf_name: Buffer name.
"
" Returns:
"   1 if selected, 0 if not found.
function! ide#util#ClearWindow(buf_name) "{{{
  if bufwinnr(a:buf_name) != -1
    let win_num = winnr()
    exec bufwinnr(a:buf_name) . " wincmd w"
    setlocal noreadonly
    setlocal modifiable
    silent 1,$delete _
    exec win_num . " wincmd w"
  endif
endfunction " }}}


" Gets list of windows open for buffer
"
" Args:
"   buf_num: Buffer number.
"
" Returns:
"   List of window numbers open for buffer.
function! ide#util#GetOpenWindows(buf_num) abort " {{{
  let results = []
  for win_num in range(1, winnr("$"))
    if winbufnr(win_num) == a:buf_num
      call add(results, string(win_num + 0))
    endif
  endfor
  return results
endfunction " }}}


" Opens split window.
"
" Args:
"   pos: 'right', 'left', 'top', 'bottom'
"   size: Size in lines (if pos top/bottom) or chars (if pos right/left)
function! ide#util#OpenSplitWindow(pos, size) abort " {{{
  let modifier = ide#util#GetVimOpenModifiers(a:pos)
  if a:pos ==? "top" || a:pos ==? "bottom"
    exec modifier . ' split "[Split]" | ' . a:size
  else
    exec modifier . ' split "[Split]"'
  endif
endfunction " }}}


" Gets VIM open modifier given a view position.
"
" These modifiers not only determine horizontal vs vertical layout, but ensure
" that the opening taking into account the entire visual space and not just
" the current VIM window (e.g. 'botright' will " open a view at the bottom
" that uses the full width of the main view).
"
" Args:
"   pos: View position ('top', 'left', 'right', 'bottom')
"
" Returns:
"   'botright', 'topleft', 'leftabove', or 'rightbelow'
function! ide#util#GetVimOpenModifiers(pos) abort " {{{
  if a:pos ==? "left"
    return "vertical topleft"
  elseif a:pos ==? "right"
    return "vertical botright"
  elseif a:pos ==? "bottom"
    return "botright"
  elseif a:pos ==? "top"
    return "topleft"
  else
    return ""
  endif
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Display Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Override the default background color for current window.
"
" Normally you can't have a different background for different windows, this
" cheats and makes use of the signs linehl to modify every line.
"
" Args:
"   color: color to set
function! ide#util#SetBgColor(color) abort " {{{
  exec "highlight BgOverride guibg=" . a:color
  exec "sign define bg_override linehl=BgOverride"
  for line_num in range(1, line('$'))
    exec "sign place " . line_num . " line=" . line_num . " name=bg_override"
      \ " buffer=" . bufnr("%")
  endfor
endfunction " }}}


" Clears background color override set by SetBgColor
function! ide#util#UnsetBgColor(color) abort " {{{
  exec "sign define bg_override linehl=" . a:color
  for line_num in range(1, line('$'))
    exec "sign unplace " . line_num . "buffer=" . bufnr("%")
  endfor
  exec "sign undefine bg_override"
endfunction " }}}


" Changes background style.
"
" Args:
"   style: 'light' (light background) or 'dark' (dark background)
function! ide#util#SetBackground(style) abort " {{{
  if ide#util#NameRangeMatch(a:style, "l", "light")
    set background=light
    let g:background = "light"
  elseif ide#util#NameRangeMatch(a:style, "d", "dark")
    set background=dark
    let g:background = "dark"
  endif
endfunction " }}}


" Toggles current background setting.
function! ide#util#ToggleBackground() abort " {{{
  if &background ==? "light"
    call ide#util#SetBackground("dark")
  else
    call ide#util#SetBackground("light")
  endif
endfunction " }}}


" Sets new color scheme and background
"
" Args:
"   colorscheme: Color scheme.
"   background: Background (light/dark).
function! ide#util#SetColorScheme(colorscheme, background) abort " {{{
  exec "setlocal background=" . a:background
  let g:background = a:background
  if has("gui_running")
    " Refresh issue, invoke later
    call ide#util#InvokeLater(':colorscheme ' . a:colorscheme .
      \ ' | highlight! link ColorColumn LineNr')
  else
    " Also make left col look like right column
    exec ':colorscheme ' . a:colorscheme .
      \ ' | highlight! link ColorColumn LineNr'
  endif
endfunction " }}}


" Displays print margin and highlights errors past the max line length
"
" Args:
"   mode: 0 (off), 1 (on), 2 (on with error hl for long lines)
function! ide#util#SetPrintMargin(mode) abort " {{{
  if a:mode == 0
    setlocal colorcolumn=0
  elseif a:mode > 0
    " Show print margin (draws lines at textwidth+1, +2, +3)
    setlocal colorcolumn=+1,+2,+3
  endif

  if a:mode == 2
    " Highlight text that is passed max line length
    highlight def link RightMargin Error
    if &textwidth != 0
      exec 'match RightMargin /\%>' . &textwidth . 'v.\+/'
    endif
  else
    highlight def link RightMargin Normal
  endif
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" String Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Matches names between a min and max sequence of chars.
"
" Args:
"   name: Name to match.
"   min_valid_name: Minimal name considered valid.
"   max_valid_name: Maximal name considered valid.
" Returns:
"   True if command matches name.
function! ide#util#NameRangeMatch(
    \ name, min_valid_name, max_valid_name) abort " {{{
  for offset in range(len(a:min_valid_name) - 1, len(a:max_valid_name) - 1)
    if a:name ==? a:max_valid_name[:offset]
      return 1
    endif
  endfor
  return 0
endfunction " }}}


" Split strings by cur_delim and then join by new_delim.
"
" Args:
"   str_or_list: Input string or list of input strings.
"   cur_delim: Current delim.
"   new_delim: Current delim.
"   a:1: 1 for only first occurance
"
" Returns:
"   String separated by new delimiter.
function! ide#util#ChangeDelimiter(
    \ str_or_list, cur_delim, new_delim, ...) abort " {{{
  if a:0 > 0 && a:1
    let flags = ""
  else
    let flags = "g"
  endif
  if type(a:str_or_list) == 1
    return substitute(a:str_or_list, a:cur_delim, a:new_delim, flags)
  else
    let results = []
    for str in a:str_or_list
      call add(results, substitute(str, a:cur_delim, a:new_delim, flags))
    endfor
    return results
  endif
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Keyword Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Expand keywords in array.
"
" Args:
"   arr: Array of params.
"   full: 0 for head, 1 for full expansion, 2 for full but not extension
"   trim_path: path to trim from start of params
"
" Returns:
"   Array of expanded terms.
function! ide#util#ExpandKeywords(arr, full, trim_path) abort " {{{
  let expanded_arr = []
  for item in a:arr
    if item ==? "%" || ide#util#NameRangeMatch(item, ":f", ":file")
      if a:full == 0
        let expanded = expand("%:p:t")
      elseif a:full == 1
        let expanded = expand("%:p")
      else
        let expanded = expand("%:p:r")
      endif
    elseif item ==? "%/" || ide#util#NameRangeMatch(item, ":d", ":dir/")
      if a:full == 0
        let expanded = fnamemodify(expand("%:p:h"), ":t")
      else
        let expanded = expand("%:p:h")
      endif
    elseif len(item) > 0 && item[0] ==? '*' || item[0] ==? ':'
      " Can't expand further, leave as is
      let expanded = item
    else
      if a:full == 0
        let expanded = fnamemodify(item, ":t")
      elseif a:full == 1
        let expanded = fnamemodify(item, ":p")
      else
        " The :r strips trailing '.' even if there are not extensions, this
        " fixes this
        let ends_in_period = len(item) > 0 ? item[len(item) - 1] == '.' : 0
        let no_ext = fnamemodify(item, ":r")
        if ends_in_period
          let no_ext = no_ext . "."
        endif
        let expanded = no_ext
      endif
    endif

    call add(expanded_arr, expanded)
  endfor
  return expanded_arr
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" File/Path Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Safely expands by checks if necessary.
function! ide#util#SafeExpand(name) abort " {{{
  if stridx(a:name, "%") != -1 || stridx(a:name, "~") != -1
    return expand(a:name))
  else
    return a:name
  endif
endfunction " }}}


" Checks if name is a directory.
function! ide#util#IsDir(name) abort " {{{
  if stridx(a:name, "%") != -1 || stridx(a:name, "~") != -1
    return isdirectory(expand(a:name))
  else
    return isdirectory(a:name)
  endif
endfunction " }}}


" Checks if name is a url.
function! ide#util#IsUrl(name) abort " {{{
  if stridx(a:name, "://") != -1 || a:name[-4:] ==? ".com" ||
      \ a:name[-4:] ==? ".net" || a:name[-4:] ==? ".gov"
    return 1
  else
    return 0
  endif
endfunction " }}}


" Gets hostname of a URL
"
" Args:
"   url: url
"
" Return:
"   Hostname portion of url (without 'www.')
function! ide#util#GetUrlHost(url) abort " {{{
  let url = substitute(a:url, 'https://', '', '')
  let url = substitute(url, 'http://', '', '')
  let idx = stridx(url, '/')
  if idx == -1
    return substitute(url, 'www.', '', '')
  else
    return substitute(url[:(idx - 1)], 'www.', '', '')
  endif
endfunction " }}}


" Splits a path around an embedded directory.
"
" Example:
"   SplitPath('/x/y/src/file.java', ['test, 'src'])  # ['/x/y', 'file.java']
"
" Args:
"   path: Current file or directory.
"   matches: List of possible inner directories to match.
"
" Return:
"   Array of [pre_split, post_split] or [] if not match.
function! ide#util#SplitPath(path, matches) abort " {{{
  if len(a:path) > 0 && a:path[0] ==? "/"
    let prefix = "/"
  else
    let prefix = ""
  endif

  let parts = split(a:path, '/')
  let i = 0
  for dir in reverse(parts[:])
    let i+=1
    if index(a:matches, dir) != -1
      let offset = len(parts)-i
      return [prefix . join(offset >= 1 ? parts[:(offset-1)] : [], '/'),
            \ join(parts[(offset+1):], '/')]
    endif
  endfor
  return []
endfunction " }}}


" Returns filename portion given path.
"
" Args:
"   path: Path.
function! ide#util#Filename(path) abort " {{{
  return substitute(a:path, '\(.*\/\)', "", "")
endfunction " }}}


" Returns directory name given path.
"
" Args:
"   path: Path.
function! ide#util#Dirname(path) abort " {{{
  if a:path ==? "." || a:path ==? "%"
    return expand("%:p:h")
  elseif isdirectory(a:path)
    if a:path[-1] ==? "/"
      return simplify(a:path[:len(a:path)-2])
    else
      return simplify(a:path)
    endif
  endif

  if len(a:path) > 0 && a:path[-1] ==? "/"
    let expanded_path = ide#util#SafeExpand(a:path[:len(a:path)-2])
  else
    let expanded_path = ide#util#SafeExpand(a:path)
  endif

  let dir = substitute(expanded_path, '\(' . substitute(
    \ ide#util#Filename(expanded_path), '.', '\.', '') . '\)$', "", "")
  return simplify(dir[:len(dir) - 2])
endfunction " }}}


" Gets a list of paths between start and end dir.
"
" Example:
"    GetPaths('/foo/bar', '/foo/bar/baz')    : ['/foo/bar', '/foo/bar/baz']
"
" Args:
"   start_dir: Starting directory
"   stop_dir: Directory to stop at (included in paths).
"
" Returns:
"   List of paths
function! ide#util#GetPaths(start_dir, end_dir) abort " {{{
  let paths = []
  let start_path_names = split(
    \ fnamemodify(ide#util#Dirname(a:start_dir), ":p"), "/")
  let end_path_names = split(
    \ fnamemodify(ide#util#Dirname(a:end_dir), ":p"), "/")
  let start_offset = 0
  for offset in range(0, len(start_path_names) - 1)
    if start_path_names[offset] ==? end_path_names[offset]
      let start_offset = offset
    endif
  endfor
  for end_offset in range(start_offset, len(end_path_names) - 1)
    let path = "/" . join(end_path_names[:end_offset], "/")
    call add(paths, path)
  endfor
  return paths
endfunction " }}}


" Gets relative path based on base path.
"
" Args:
"   base: Base path.
"   path: Path to get relative path for.
"
" Returns:
"   Relative path.
function! ide#util#GetRelativePath(base, path) abort " {{{
  let l = len(a:base)
  if a:path[:(l-1)] ==? a:base
    if a:path[l] ==? "/"
      return a:path[(l+1):]
    else
      return a:path[(l):]
    endif
  endif
  return a:path
endfunction " }}}


" Finds common prefix among a list of paths.
"
" Args:
"   paths: List of paths.
"
" Returns:
"   Common path.
function! ide#util#GetCommonPath(paths) abort " {{{
  let path_lists = []
  for path in a:paths
    if ! empty(path)
      if stridx(path, "/") == -1
        return ""
      else
        call add(path_lists, split(path, "/"))
      endif
    endif
  endfor
  if len(path_lists) == 0
    return ""
  elseif len(path_lists) == 1
    let num_parts = len(path_lists[0])
    let path = join(path_lists[0][:(num_parts-2)], "/")
    if a:paths[0][0] == "/"
      return "/" . path
    else
      return path
    endif
  endif

  let common_path = []
  let offset = 0
  while 1
    for path_list in path_lists
      if offset == len(path_list) || path_list[offset] !=? path_lists[0][offset]
        if ! empty(common_path) && a:paths[0][0] == "/"
          return "/" . join(common_path, "/")
        else
          return join(common_path, "/")
        endif
      endif
    endfor
    call add(common_path, path_lists[0][offset])
    let offset += 1
  endwhile

  return ""
endfunction " }}}


" Removes common path from a list of paths.
"
" Args:
"   common_path: Path common to all paths.
"   paths: List of paths.
"
" Returns:
"   list of the original paths with the common path removed.
function! ide#util#RemoveCommonPath(common_path, paths) abort " {{{
  if empty(a:common_path)
    return a:paths
  else
    let l = len(a:common_path)
    let results = []
    for path in a:paths
      if path[:(l-1)] ==? a:common_path
        if path[l] ==? "/"
          call add(results, path[(l+1):])
        else
          call add(results, path[(l):])
        endif
      else
        call add(results, path)
      endif
    endfor
    return results
  endif
endfunction " }}}


" Finds files.
"
" If the first arg (a:1) starts with a '-' then the arg is passed as is to
" the unix find command, otherwise the args can be any one of:
"
" Args:
"   default_dirs: List of default dirs to search (used if none specified).
"   a:*: Pattern of files to search for (e.g. *.txt).
"   a:*: Dirs ('.', '/foo', ...) / flags (maxdepth, newer, mtime, ...).
"
" Returns:
"   List of files found.
function! ide#util#FindFiles(default_dirs, ...) abort " {{{
  let idx = 0
  let flags = ""

  if a:0 > 0 && a:1 == "!"
    let flags .= " \!"
    let idx += 1
  endif

  if idx >= len(a:000) | return [] | endif

  if a:000[idx][0] ==? "-"
    let flags .= " " . shellescape(join(a:000, " "))
  else
    " pattern (required)
    let flags .= " -name " . shellescape(a:000[idx])
    let idx += 1

    " optional dirs
    let dirs = []
    while idx < len(a:000)
      if empty(<SID>MatchFileSearchOptions(a:000[idx], ""))
        call add(dirs, a:000[idx])
        let idx += 1
      else
        break
      endif
    endwhile

    " optional flags
    while 1
      if idx < len(a:000) && a:000[idx] == "!"
        let flags .= " \!"
        let idx += 1
      endif

      if idx < len(a:000) - 1
        if a:000[idx+1][0] ==? '"' || a:000[idx+1][0] ==? "'"
          let arg_idx = <SID>ReadQuotedArg(a:000, idx+1)
          let opts = <SID>MatchFileSearchOptions(a:000[idx], arg_idx[0])
          let idx = arg_idx[1]
        else
          let opts = <SID>MatchFileSearchOptions(a:000[idx], a:000[idx+1])
          let idx += 2
        endif
        if !empty(opts)
          let flags .= opts
        endif
      else
        break
      endif
    endwhile

    if len(dirs) == 0
      let dirs = a:default_dirs
    endif

    " dirs + flags
    let flags = join(dirs, " ") . flags . " -print"
  endif

  let result = system("find " . flags)
  if !empty(result) && result !=? "\n"
    return split(result, "\n")
  else
    return []
  endif
endfunction " }}}


" Helper to match additional search options for 'file' cmd
function! s:MatchFileSearchOptions(option, value) abort " {{{
  if ide#util#NameRangeMatch(a:option, "type", "type")
    return " -type " . a:value
  elseif ide#util#NameRangeMatch(a:option, "atime", "atime")
    return " -atime " . a:value
  elseif ide#util#NameRangeMatch(a:option, "ctime", "ctime")
    return " -ctime " . a:value
  elseif ide#util#NameRangeMatch(a:option, "depth", "depth")
    return " -depth " . a:value
  elseif ide#util#NameRangeMatch(a:option, "grep", "grep")
    if a:value[0] ==? "'" || a:value[0] ==? '"'
      return " ! -type d -exec grep -q " . a:value . ' {} \;'
    else
      return " ! -type d -exec grep -q " . shellescape(a:value) . ' {} \;'
    endif
  elseif ide#util#NameRangeMatch(a:option, "group", "group")
    return " -group " . a:value
  elseif ide#util#NameRangeMatch(a:option, "maxdepth", "maxdepth")
    return " -maxdepth " . a:value
  elseif ide#util#NameRangeMatch(a:option, "mindepth", "mindepth")
    return " -mindepth " . a:value
  elseif ide#util#NameRangeMatch(a:option, "mtime", "mtime")
    return " -mtime " . a:value
  elseif ide#util#NameRangeMatch(a:option, "newer", "newer")
    return " -newer " . a:value
  elseif a:option =~ "newer"
    return " -" . a:option . " " . a:value
  elseif ide#util#NameRangeMatch(a:option, "perm", "perm")
    return " -perm " . a:value
  elseif ide#util#NameRangeMatch(a:option, "size", "size")
    return " -size " . a:value
  elseif ide#util#NameRangeMatch(a:option, "user", "user")
    return " -user " . a:value
  else
    return ""
  endif
endfunction " }}}


" Helper to read quoted in list of args
"
" Quoted args have a name staring with ' or " and end with an arg name ending
" in the same quote
"
" Returns [arg_name, new_offset]
function! s:ReadQuotedArg(args, offset) abort " {{{
  let quote_type = a:args[a:offset][0]
  let idx = a:offset
  let value = ""
  while idx < len(a:args)
    if a:args[idx][-1] !=? quote_type
      let value .= a:args[idx] . " "
      let idx += 1
    else
      let value .= a:args[idx]
      break
    endif
  endwhile
  return [value, idx]
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Error/Warning Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Displays warning message.
"
" Args:
"   msg: Warning messaage
function! ide#util#EchoWarning(msg) abort " {{{
  echohl WarningMsg
  echomsg a:msg
  echohl None
  let v:warningmsg = a:msg
endfunction " }}}


" Displays error message.
"
" Args:
"   msg: Warning messaage
function! ide#util#EchoError(msg) abort " {{{
  echohl ErrorMsg
  echomsg a:msg
  echohl None
  let v:errmsg = a:msg
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Shell Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Echo's shell command to echom.
"
" Args:
"   shell_cmd: Shell command
function! ide#util#EchoShellCmd(shell_cmd) abort " {{{
  let result = system(a:shell_cmd)
  if !empty(result) && result !=? "\n"
    for line in split(result, "\n")
      echom line
    endfor
  endif
endfunction " }}}


" Runs shell command and returns the results as separate lines.
"
" Args:
"   shell_cmd: Shell command
"
" Returns:
"   List of lines output from shell.
function! ide#util#InvokeShellCmd(shell_cmd) abort " {{{
  let results = system(a:shell_cmd)
  if !empty(results) && results !=? "\n"
    return split(results, "\n")
  else
    return []
  endif
endfunction " }}}
