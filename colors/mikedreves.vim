""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim Color File
"
" Author: Mike Dreves
"
" Terms:
"   Most terminals only support 8 colors! (must set TERM=xterm-color)
"     0 - back
"     1 - red
"     2 - green
"     3 - yellow
"     4 - blue
"     5 - magenta
"     6 - cyan
"     7 - grey
"     8 - white
"   You can run 'tput colors' to verify how many are supported
"   To get more colors, install ncurses-term and set TERM=xterm-256color
"
" Syntax Definition:
"   syn keyword Foo hello       " word 'hello' is associated with group Foo
"   syn match Bar '[a-zA-z]*'   " anything matching regex assoc with group Bar
"   syn region Baz start=/\v"/ skip=/\v\\./ end=/\v"/  " matches string
"
" Syntax Groups:
"   hi Foo guifg=#ffffff        " Use white foreground for Foo group
"
" Syntax Linking:
"   hi def link Foo Function    " associate Foo matches with 'Function' group
"   hi def link Bar MyGroup     " associate Bar matches with 'MyGroup' group
"
" References:
"   Chart: http://upload.wikimedia.org/wikipedia/en/1/15/Xterm_256color_chart.svg
"   :help group-name
"   :help highlight
"   http://learnvimscriptthehardway.stevelosh.com/chapters/45.html
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

highlight clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name="mikedreves"


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Arrays of [gui{fg/bg}, cterm{fg/bg}]
let s:colors = {}

let s:colors.black = ['#000000', '232']                " standard black
let s:colors.white = ['#ffffff', '231']                " standard white
let s:colors.red = ['#ff0000', '196']                  " standard red
let s:colors.green = ['#00ff00', '46']                 " standard green
let s:colors.blue = ['#0000ff', '12']                  " standard blue

let s:colors.selection_blue = ['#aacbfb', '153']       " blue for selections

if &background == "light" || &diff

  let s:colors.primary_black = ['#444444', '238']      " primary black
  let s:colors.primary_beige = ['#fffcef', '230']      " primary beige
  let s:colors.secondary_beige = ['#fffbf0', '230']    " secondary beige
  let s:colors.secondary_grey = ['#656763', '236']     " secondary grey
  let s:colors.highlight_grey = ['#888a85', '102']     " grey for highlights
  let s:colors.status_grey = ['#babdb6', '145']        " grey for status
  let s:colors.gutter_grey = ['#cdcac2', '187']        " grey for gutter
  let s:colors.comment_grey = ['#656763', '236']       " grey for comment
  let s:colors.comment_blue = ['#0000ee', '20']        " comment blue
  let s:colors.primary_blue = ['#00008b', '18']        " primary blue
  let s:colors.secondary_blue = ['#3a5fcd', '62']      " secondary blue
  let s:colors.primary_red = ['#8b0000', '88']         " primary red
  let s:colors.primary_cyan = ['#2f618a', '24']        " primary cyan
  let s:colors.secondary_cyan = ['#1874cd', '63']      " secondary cyan
  let s:colors.primary_magenta = ['#8b008b', '90']     " primary magenta
  "let s:colors.primary_magenta = ['#9e2058', '125']    " primary magenta

  " General
  if &diff
    let s:colors.primary_fg = s:colors.black
    let s:colors.primary_bg = s:colors.white
  else
    let s:colors.primary_fg = s:colors.primary_black
    let s:colors.primary_bg = s:colors.primary_beige
  endif
  let s:colors.secondary_fg = s:colors.secondary_grey
  if &diff
    let s:colors.secondary_bg = s:colors.white
  else
    let s:colors.secondary_bg = s:colors.secondary_beige
  endif
  let s:colors.select_fg = ['', '']
  let s:colors.select_bg = s:colors.selection_blue
  let s:colors.highlight_fg = s:colors.white
  let s:colors.highlight_bg = s:colors.highlight_grey
  let s:colors.gutter_fg = s:colors.gutter_grey
  if &diff
    let s:colors.gutter_bg = s:colors.white
    let s:colors.extended_gutter_bg = s:colors.white
  else
    let s:colors.gutter_bg = s:colors.secondary_beige
    let s:colors.extended_gutter_bg = s:colors.primary_beige
  endif
  let s:colors.status_bg = s:colors.status_grey
  let s:colors.status_fg = s:colors.black
  let s:colors.inactive_status_fg = s:colors.black
  let s:colors.inactive_status_bg = s:colors.secondary_grey
  let s:colors.fold_fg = s:colors.white
  let s:colors.fold_bg = s:colors.secondary_blue
  let s:colors.split_fg = s:colors.secondary_fg
  let s:colors.split_bg = s:colors.secondary_bg
  let s:colors.cursor = s:colors.highlight_grey

  " Specials
  let s:colors.special_text = s:colors.blue            " -- INSERT --, etc
  let s:colors.special_title = s:colors.blue           " -- OPTIONS --, etc
  let s:colors.special_key = s:colors.red              " ESC, etc
  let s:colors.special_question = s:colors.red         " vim question ?, etc
  let s:colors.special_parenmatch_fg = s:colors.white
  let s:colors.special_parenmatch_bg = s:colors.highlight_grey
  let s:colors.special_directory = s:colors.blue       " directory listings
  let s:colors.special_tag = s:colors.primary_magenta  " tags (help, etc)

  " Tabs
  let s:colors.tab_fg = s:colors.gutter_fg
  let s:colors.tab_bg = s:colors.gutter_bg
  let s:colors.tab_select_fg = s:colors.select_fg
  let s:colors.tab_select_bg = s:colors.select_bg

  " Context Menu
  let s:colors.menu_fg = s:colors.gutter_fg
  let s:colors.menu_bg = s:colors.gutter_bg
  let s:colors.menu_select_fg = s:colors.select_fg
  let s:colors.menu_select_bg = s:colors.select_bg
  let s:colors.menu_bar = s:colors.status_bg
  let s:colors.menu_thumb = s:colors.status_fg

  " Errors/Warnings
  let s:colors.error_fg = s:colors.white
  let s:colors.error_bg = s:colors.red
  let s:colors.warning_fg = s:colors.red
  let s:colors.warning_bg = ['', '']

  " TODO
  let s:colors.todo_fg = ['#006400', '22']
  let s:colors.todo_bg = ['#9Aff9a', '120']

  " Diff
  let s:colors.diff_add_fg = s:colors.black
  let s:colors.diff_add_bg = ['#cee5de', '151']
  let s:colors.diff_delete_bg = ['#d3cbb5', '187']
  let s:colors.diff_delete_fg = s:colors.diff_delete_bg  " ----- lines
  let s:colors.diff_modify_fg = s:colors.black
  let s:colors.diff_modify_bg = ['#dbc7e8', '182']
  let s:colors.diff_text_fg = s:colors.diff_modify_fg
  let s:colors.diff_text_bg = ['#b5a1c2', '96']

  " Syntax
  let s:colors.comment = s:colors.comment_blue  " /* comments */, <SID>, <c-r>
  let s:colors.line_comment = s:colors.comment_blue  " // comments
  let s:colors.import = s:colors.primary_magenta
  let s:colors.literal = s:colors.primary_red  " number, boolean
  let s:colors.string = s:colors.primary_magenta
  let s:colors.special_string = s:colors.comment_grey  " \n, etc
  let s:colors.bracket = s:colors.comment_grey  " {}
  let s:colors.paren = s:colors.comment_grey  " ()
  let s:colors.keyword = s:colors.primary_blue  " dark blue
  let s:colors.annotation = s:colors.primary_red
  let s:colors.class = s:colors.primary_cyan
  let s:colors.function = s:colors.class
  let s:colors.identifier = s:colors.function
  let s:colors.special = s:colors.import

else

  let s:colors.primary_black = ['#1e2426', '234']        " primary black
  let s:colors.secondary_black = ['#2c3032', '237']      " secondary black
  let s:colors.highlight_black = ['#2e3436', '233']      " black for highlights
  let s:colors.selection_black = ['#2e303b', '237']      " black for selections
  let s:colors.primary_light_grey = ['#babdb6', '145']   " primary light grey
  let s:colors.secondary_light_grey = ['#eeeeec', '254'] " secondary light grey
  let s:colors.primary_dark_grey = ['#555753', '236']    " primary dark grey
  let s:colors.secondary_dark_grey = ['#888a85', '102']  " secondary dark grey
  let s:colors.comment_grey = ['#656763', '239']         " grey for comment
  let s:colors.primary_red = ['#a14848', '124']          " primary red
  let s:colors.primary_green = ['#8ae234', '46']         " primary green
  let s:colors.primary_blue = ['#729fcf', '69']          " primary blue
  let s:colors.primary_orange = ['#fcaf3e', '208']       " primary orange
  let s:colors.primary_yellow = ['#d1d435', '184']       " primary yellow

  " General
  let s:colors.primary_fg = s:colors.primary_light_grey
  let s:colors.primary_bg = s:colors.primary_black
  let s:colors.secondary_fg = s:colors.primary_black
  let s:colors.secondary_bg = s:colors.secondary_black
  let s:colors.select_fg = ['', '']
  let s:colors.select_bg = s:colors.selection_black
  let s:colors.highlight_fg = s:colors.highlight_black
  let s:colors.highlight_bg = s:colors.primary_orange
  let s:colors.gutter_fg = s:colors.selection_black
  let s:colors.gutter_bg = s:colors.black
  let s:colors.extended_gutter_bg = s:colors.primary_black
  let s:colors.status_fg = s:colors.highlight_black
  let s:colors.status_bg = s:colors.primary_light_grey
  let s:colors.inactive_status_fg = s:colors.highlight_black
  let s:colors.inactive_status_bg = s:colors.secondary_dark_grey
  let s:colors.fold_fg = ['#d3d7cf', '188']
  let s:colors.fold_bg = ['#204a87', '24']
  let s:colors.split_fg = s:colors.white
  let s:colors.split_bg = s:colors.secondary_dark_grey
  let s:colors.cursor = s:colors.primary_light_grey

  " Specials
  let s:colors.special_text = s:colors.primary_blue      " -- INSERT --, etc
  let s:colors.special_title = s:colors.primary_orange   " -- OPTIONS --, etc
  let s:colors.special_key = ['#ef2929', '196']          " ESC, etc
  let s:colors.special_question = s:colors.primary_blue  " vim question ?, etc
  let s:colors.special_parenmatch_fg = s:colors.highlight_black
  let s:colors.special_parenmatch_bg = s:colors.primary_orange
  let s:colors.special_directory = s:colors.white        " directory listings
  let s:colors.special_tag = s:colors.primary_green      " tags (help, etc)

  " Tabs
  let s:colors.tab_fg = s:colors.secondary_dark_grey
  let s:colors.tab_bg = ['#0a1012', '16']
  let s:colors.tab_select_fg = s:colors.secondary_light_grey
  let s:colors.tab_select_bg = s:colors.primary_dark_grey

  " Context Menu
  let s:colors.menu_fg = s:colors.secondary_light_grey
  let s:colors.menu_bg = s:colors.highlight_black
  let s:colors.menu_select_fg = s:colors.primary_black
  let s:colors.menu_select_bg = s:colors.white
  let s:colors.menu_bar = s:colors.primary_dark_grey
  let s:colors.menu_thumb = s:colors.white

  " Errors/Warnings
  let s:colors.error_fg = s:colors.white
  let s:colors.error_bg = s:colors.red
  let s:colors.warning_fg = s:colors.comment_grey
  let s:colors.warning_bg = s:colors.primary_yellow

  " Todo
  let s:colors.todo_fg = s:colors.comment_grey
  let s:colors.todo_bg = s:colors.primary_yellow

  " Diff
  let s:colors.diff_add_fg = ['', '']
  let s:colors.diff_add_bg = ['#1f2b2d', '16']
  let s:colors.diff_delete_fg = s:colors.highlight_black
  let s:colors.diff_delete_bg = ['#0e1416', '16']
  let s:colors.diff_modify_fg = ['', '']
  let s:colors.diff_modify_bg = s:colors.highlight_black
  let s:colors.diff_text_fg = ['', '']
  let s:colors.diff_text_bg = s:colors.black

  " Syntax
  let s:colors.comment = s:colors.primary_green " /* .. */ comments
  let s:colors.line_comment = s:colors.comment_grey " // comments
  let s:colors.import = s:colors.primary_yellow
  let s:colors.literal = s:colors.primary_red  " number, boolean
  let s:colors.string = s:colors.primary_green  " special case literal
  let s:colors.special_string = s:colors.comment_grey  " \n, etc
  let s:colors.bracket = s:colors.comment_grey  " {}
  let s:colors.paren = s:colors.comment_grey  " ()
  let s:colors.keyword = s:colors.white
  let s:colors.annotation = s:colors.literal
  let s:colors.class = s:colors.primary_orange " s:colors.primary_blue
  let s:colors.function = s:colors.primary_orange
  let s:colors.identifier = s:colors.primary_orange
  let s:colors.special = s:colors.primary_blue  " <SID>, <c-r>, etc

endif


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! SetColor(id, fg, ...)
  " Sets color for given style id.
  "
  " Args:
  "  colors: Variable (s:colors.xxx) name with array of gui/cterm colors
  "  gui: 'none' or empty
  let hi_str = 'highlight ' . a:id . ' '
  if strlen(a:fg)
    let colors = get(s:colors, a:fg)
    if colors[0] != ''
      let hi_str .= 'guifg=' . colors[0] . ' '
    endif
    if colors[1] != ''
      let hi_str .= 'ctermfg=' . colors[1] . ' '
    endif
  endif

  if a:0 >= 1 && strlen(a:1)
    let colors = get(s:colors, a:1)
    if colors[0] != ''
      let hi_str .= 'guibg=' . colors[0] . ' '
    endif
    if colors[1] != ''
      let hi_str .= 'ctermbg=' . colors[1] . ' '
    endif
  endif

  if a:0 >= 2 && strlen(a:2)
    let hi_str .= 'gui=' . a:2 . ' cterm=' . a:2
  endif

  "echom hi_str
  execute hi_str
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Basic Display
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"-- Default colors --

"Default display
call SetColor('Normal', 'primary_fg', 'primary_bg')
"Display for area with no text
call SetColor('NonText', 'secondary_fg', 'secondary_bg')

"Conceal text
"call SetColor('Conceal', '', 'cursor')

"Cursor display
call SetColor('Cursor', '', 'cursor')
call SetColor('VCursor', '', 'cursor')
call SetColor('ICursor', '', 'cursor')
call SetColor('CursorLine', 'select_fg', 'select_bg')
call SetColor('CursorColumn', 'primary_fg', 'primary_bg')
"call SetColor('CursorLineNr', 'select_fg', 'select_bg')

"-- Window colors --

"Display when line numbers shown
call SetColor('LineNr', 'gutter_fg', 'gutter_bg')
"Text after max textwidth
call SetColor('ColorColumn', 'red', 'gutter_bg')
"Gutter next to line numbers (used for errors)
call SetColor('SignColumn', '', 'extended_gutter_bg')
"Gutter next to line numbers (for folded text info)
call SetColor('FoldColumn', '', 'gutter_bg')

"Status line (active window) when split used
call SetColor('StatusLine', 'status_fg', 'status_bg', 'none')
"Status line (inactive window) when split used
call SetColor(
  \ 'StatusLineNC', 'inactive_status_fg', 'inactive_status_bg', 'none')

"Display for dividing bar when vertial split used
call SetColor('VertSplit', 'split_fg', 'split_bg', 'none')
"Display for folded text line
call SetColor('Folded', 'fold_fg', 'fold_bg')

"Title for menu used with tab-completion in command mode
call SetColor('WildMenu', 'status_fg', 'status_bg')

"call SetColor('Menu', 'status_fg', 'status_bg')
"call SetColor('Scrollbar', 'status_fg', 'status_bg')

"-- Search/Select colors --

"Display used for text selection
call SetColor('Visual', 'select_fg', 'select_bg')
"Display used for text selection in xterm (Not Owning Selection)
call SetColor('VisualNOS', 'select_fg', 'select_bg')
"Used to highlight last search match when hlsearch enabled
call SetColor('Search', 'highlight_fg', 'highlight_bg')
"Used to highlight increment matches when incserach enabled
"  NOTE: bg/fg are reverse to what is displayed
call SetColor('IncSearch', 'highlight_bg', 'highlight_fg')

"-- Specials --

"Highlight for -- INSERT --, -- VISUAL --, etc mode info
call SetColor('ModeMsg', 'special_text', '', 'none')
"Highlight for -- more --
call SetColor('MoreMsg', 'special_text', '', 'none')
"Highlight for --OPTIONS ---, etc
call SetColor('Title', 'special_title', '', 'none')
call SetColor('Subtitle', 'special_title', '', 'none')
"Highlight used for special chars: ESC, etc
call SetColor('SpecialKey', 'special_key', '', 'none')
"Displayed when vim asks a question
call SetColor('Question', 'special_question', '', 'none')
"Match paren color
call SetColor('MatchParen', 'special_parenmatch_fg', 'special_parenmatch_bg')
"Displayed when directory names listed using :n .
call SetColor('Directory', 'special_directory', '', 'none')
"call SetColor('Tooltip', 'special_text', '', 'none')

"-- Spelling --
"call SetColor('SpellBad', 'warning_fg', 'warning_bg', 'none')
"call SetColor('SpellCap', 'warning_fg', 'warning_bg', 'none')
"call SetColor('SpellLocal', 'warning_fg', 'warning_bg', 'none')
"call SetColor('SpellRare', 'warning_fg', 'warning_bg', 'none')

"-- Tabs --
call SetColor('TabLine', 'tab_fg', 'tab_bg')
call SetColor('TabLineFill', 'tab_bg', '')
call SetColor('TabLineSel', 'tab_select_fg', 'tab_select_bg', 'none')

"-- Completion menu --
call SetColor('Pmenu', 'menu_fg', 'menu_bg')
call SetColor('PmenuSel', 'menu_select_fg', 'menu_select_bg')
call SetColor('PmenuSbar', '', 'menu_bar')
call SetColor('PmenuThumb', 'menu_thumb', '')

"-- Error/Warning --

"Displayed for error messages (Pattern not found, etc)
call SetColor('ErrorMsg', 'error_fg', 'error_bg')
"Display for warning messages (search hit BOTTOM, etc)
call SetColor('WarningMsg', 'warning_fg', 'warning_bg')

"-- TODO --
call SetColor('Todo', 'todo_fg', 'todo_bg', 'none')

"-- Diff --
call SetColor('DiffAdd', 'diff_add_fg', 'diff_add_bg', 'none')
call SetColor('DiffDelete', 'diff_delete_fg', 'diff_delete_bg', 'none')
call SetColor('DiffChange', 'diff_modify_fg', 'diff_modify_bg', 'none')
call SetColor('DiffText', 'diff_text_fg', 'diff_text_bg', 'none')


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Syntax for Code
"
" Standard Names (vimdoc.sourceforge.net/htmldoc/syntax.html)
"   Comment (this file also supports LineComment for // comments)
"   PreProc
"     Include (#include, import)
"     Define (#define)
"     Macro (#define)
"     PreCondit (#if, #else, etc)
"   Constant
"     String
"     Character
"     Number
"     Boolean
"     Float
"   Statement
"     Conditional (if, then, else, switch)
"     Repeat (for, do, while)
"     Label (case, default)
"     Operator (sizeof, +, *, etc)
"     Exception (try, catch, throw)
"     Keyword (misc)
"   Type
"     StorageClass (static, register, volatile)
"     Structure (struct, union, enum)
"     Typedef (typedef)
"   Identifier (variable names)
"     Function (function name or method)
"   Special
"     SpecialChar (special char that is constant \n, etc)
"     Tag (ctrl-] jump word)
"     Delimiter (any char that needs special attention)
"     SpecialComment (special things inside comment)
"     Debug (debug statement)
"   Underlined (html links, etc)
"   Ignore (hidden)
"   Error (erroneous construct)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Use our own predefined highlight groups, then link to them
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call SetColor('Comment', 'comment', 'primary_bg', 'none')
call SetColor('LineComment', 'line_comment', 'primary_bg', 'none')
call SetColor('Import', 'import', '', 'none')
call SetColor('Literal', 'literal', '', 'none')
call SetColor('String', 'string', 'primary_bg', 'none')
call SetColor('SpecialString', 'special_string', '', 'none')
call SetColor('SpecialTag', 'special_tag', '', 'none')
call SetColor('Bracket', 'bracket', '', 'none')
call SetColor('Paren', 'paren', '', 'none')
call SetColor('Keyword', 'keyword', '', 'none')
call SetColor('Annotation', 'annotation', '', 'none')
call SetColor('Class', 'class', '', 'none')
call SetColor('Function', 'function', '', 'none')
call SetColor('Identifier', 'identifier', '', '')
call SetColor('Special', 'special', '', 'none')

" Standard mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" /*..*/, /
highlight! link Comment Comment

highlight! link PreProc Comment
" import, include, annotations
highlight! link Include Import
" #define
highlight! link Define Import
" Define
highlight! link Macro Import
" #if, #else
highlight! link Precondit Import

" Java primitive objects (String, Integer, ...)
highlight! link Constant Class
highlight! link String String
highlight! link Character String
highlight! link Number Literal
highlight! link Boolean Literal
highlight! link Float Literal

" new, for, ...
highlight! link Statement Keyword
" if, else, ...
highlight! link Conditional Keyword
" for, while, ...
highlight! link Repeat Keyword
" case, ...
highlight! link Label Keyword
" new, sizeof
highlight! link Operator Keyword
" try, catch, ...
highlight! link Exception Keyword
highlight! link Keyword Keyword

" void, primitives (int, boolean,...)
highlight! link Type Keyword
" public, protected, static, const
highlight! link StorageClass Keyword
" struct
highlight! link Structure Keyword
" typedef
highlight! link Typedef Keyword

" Method names, braces, ...
highlight! link Identifier Identifier
highlight! link Function Function

" comment @param, etc
highlight! link Special Comment
" \n, ...
highlight! link SpecialChar SpecialString
highlight! link Tag SpecialTag
" brackets, parens
highlight! link Delimiter Paren
" comment title
highlight! link SpecialComment Comment
highlight! link Debug Comment

highlight! link Todo Todo

highlight! link Underlined Normal

call SetColor('Ignore', 'primary_bg', 'primary_bg')

call SetColor('Error', 'error_fg', 'error_bg')


" NERDTree default overrides (nerdtree/syntax)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" ConqueTerm default overrides (conque_term/syntax)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
highlight! link ConquePrompt Title
highlight! link ConqueString String
highlight! link MySQLTableEnd SpecialString
highlight! link MySQLTableDivide SpecialString
highlight! link MySQLTableStart SpecialString
highlight! link MySQLTableBar SpecialString
highlight! link MySQLNull SpecialString
highlight! link MySQLQueryStat SpecialString

" C default overrides (vim/runtime/syntax)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
highlight! link cCommentL LineComment

" Scala default overrides (scala-dist/syntax)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Primitives, User defined types, ...
highlight! link scalaType Keyword
highlight! link scalaTypeSpecializer Class
" trait names
highlight! link scalaConstructor Class
" class names
highlight! link scalaClassName Class
highlight! link scalaClassSpecializer Class
" object apply
highlight! link scalaConstructorSpecializer Class
" val names
highlight! link scalaValName Identifier
" var names
highlight! link scalaVarName Identifier
highlight! link scalaOperator Keyword
highlight! link scalaMethodCall Normal
highlight! link scalaSymbol Keyword
highlight! link scalaStringEscape SpecialString
highlight! link scalaUnicode SpecialString
highlight! link scalaXmlTag String
highlight! link scalaXmlStart String
highlight! link scalaXmlEscape SpecialString
highlight! link scalaXmlEscapeSpecial SpecialString
highlight! link scalaXmlQuote SpecialString
highlight! link scalaComment Comment
highlight! link scalaDocComment Comment
highlight! link scalaDocTags Comment
highlight! link scalaLineComment LineComment

" Java default overrides (vim/runtime/syntax)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
highlight! link javaBraces Braces
highlight! link javaVarArg Keyword
" Primitive objects (String, etc)
highlight! link javaConstant Class
highlight! link javaAnnotation Annotation
highlight! link javaDocTags Comment
highlight! link javaDocParam Comment
highlight! link htmlComment Comment
highlight! link htmlCommentPart Comment
highlight! link javaLineComment LineComment

" Haskell default overrides (vim/runtime/syntax)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Clojure default overrides (VimClojure/syntax)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
highlight! link clojureParen0 Import
highlight! link clojureKeyword String
highlight! link clojureDefine Keyword
highlight! link clojureMacro Keyword
highlight! link clojureQuote Keyword
highlight! link clojureUnquote Keyword
highlight! link clojureDispatch Keyword
highlight! link clojureAnonArg Keyword
highlight! link clojureVarArg Keyword
highlight! link clojureSpecial Keyword

" Python default overrides (vim/runtime/syntax)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
highlight! link pythonEscape SpecialString
highlight! link pythonComment LineComment

" Go
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
highlight! link goComment LineComment

" VIM default overrides (vimruntime/syntax)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
highlight! link vimBracket Bracket
highlight! link vimParen Paren
highlight! link vimCommentTitle Import
" Javascript default overrides (vim/runtime/syntax)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
highlight! link javaScriptBraces Braces
highlight! link javaScriptSpecialCharacter SpecialString

" Less default overrides (/syntax)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
highlight! link lessVariable Identifier

" Css default overrides (vim/runtime/syntax)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" HTML default overrides (vim/runtime/syntax)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
highlight! link htmlTag Keyword
highlight! link htmlEndTag Keyword
highlight! link htmlTagName Keyword
highlight! link htmlSpecialTagName Keyword
highlight! link htmlArg Keyword
highlight! link htmlLink Special
highlight! link htmlTitle String

" XML default overrides (vim/runtime/syntax)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
highlight! link xmlTag Keyword
highlight! link xmlTagName Keyword
highlight! link xmlEndName Keyword
highlight! link xmlAttrib Keyword
highlight! link xmlNamespace Keyword
highlight! link xmlProcessingDelim Keyword
highlight! link xmlCdata Normal
highlight! link xmlCdataCdata Normal
highlight! link xmlCdataStart Keyword
highlight! link xmlCdataEnd Keyword
highlight! link xmlDocTypeDecl Special
highlight! link xmlDocTypeKeyword Special

" PHP default overrides (vim/runtime/syntax)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
highlight! link phpParent Parens
highlight! link phpBrackets Brackets

" Markdown default overrides (vim/runtime/syntax)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
