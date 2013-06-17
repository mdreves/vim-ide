""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
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

" Add consistent mappings for e (edit), s (split), d (diff)
"   NOTE: nerdtree already uses: t (tab),  q (quit)

" e (edit)
call NERDTreeAddKeyMap({
  \ 'key': 'e',
  \ 'callback': 'CustomNERDTreeEdit',
  \ 'scope': 'FileNode'
  \})

function! CustomNERDTreeEdit(filenode)
  call feedkeys("NERD_o")  " Simulate open key press
endfunction


" s (split)
call NERDTreeAddKeyMap({
  \ 'key': 's',
  \ 'callback': 'CustomNERDTreeSplit',
  \ 'scope': 'FileNode'
  \})

function! CustomNERDTreeSplit(filenode)
  let file_name = "/" . join(a:filenode.path.pathSegments, "/")
  call ide#view#CloseView("explorer")
  call ide#view#OpenView("split", file_name)
endfunction


" d (diff)
call NERDTreeAddKeyMap({
  \ 'key': 'd',
  \ 'callback': 'CustomNERDTreeDiff',
  \ 'scope': 'FileNode'
  \})

function! CustomNERDTreeDiff(filenode)
  let file_name = "/" . join(a:filenode.path.pathSegments, "/")
  call ide#view#CloseView("explorer")
  call ide#view#OpenView("diff", file_name)
endfunction
