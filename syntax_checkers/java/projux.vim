if exists("g:loaded_syntastic_java_projux_checker")
    finish
endif
let g:loaded_syntastic_java_projux_checker=1

function! SyntaxCheckers_java_projux_IsAvailable()
    return !empty($PROJECT_NAME)
endfunction

function! SyntaxCheckers_java_projux_GetLocList()
  return ide#projux#GetErrors("%")
endfunction

call g:SyntasticRegistry.CreateAndRegisterChecker({
  \ 'filetype': 'java',
  \ 'name': 'projux'})
