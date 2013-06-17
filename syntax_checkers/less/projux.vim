if exists("g:loaded_syntastic_less_projux_checker")
    finish
endif
let g:loaded_syntastic_less_projux_checker=1

function! SyntaxCheckers_less_projux_IsAvailable()
    return !empty($PROJECT_NAME)
endfunction

function! SyntaxCheckers_less_projux_GetLocList()
  return ide#projux#GetErrors("%")
endfunction

call g:SyntasticRegistry.CreateAndRegisterChecker({
  \ 'filetype': 'less',
  \ 'name': 'projux'})
