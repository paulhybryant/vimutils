" vim: set sw=2 ts=2 sts=2 et tw=78 foldlevel=0 foldmethod=marker filetype=vim nospell:

" Returns true iff is NERDTree open/active
function! vimutils#IsNTOpen() abort " {{{
  return exists("t:NERDTreeBufName") && (bufwinnr(t:NERDTreeBufName) != -1)
endfunction
" }}}


" Calls NERDTreeFind iff NERDTree is active, current window contains a
" modifiable file, and we're not in vimdiff
function! vimutils#SyncNTTree() abort " {{{
  if &modifiable && vimutils#IsNTOpen() && strlen(expand('%')) > 0 && !&diff
    if !exists('t:NERDTreeBufName') || bufname('%') != t:NERDTreeBufName
      NERDTreeFind
      wincmd p
    endif
  endif
endfunction
" }}}


" Sort words selected in visual mode in a single line, separated by space
function! vimutils#SortWords(delimiter, numeric) range abort " {{{
  if a:firstline != a:lastline
    echoerr "Can only sort words in a single line."
  endif
  " yank current visual selection to reg x
  normal gv"xy
  " split the words selected and sort
  if a:numeric
    let @x = join(sort(map(split(@x, a:delimiter), 'str2nr(v:val)'), 'n'), a:delimiter)
  else
    let @x = join(sort(split(@x, a:delimiter)), a:delimiter)
  endif
  " re-select area and delete
  normal gvd
  " paste sorted words back in
  normal "xP
endfunction
" }}}


" Functions for settping up tabline mappsing for different OSes {{{
function! s:SetupTablineMappingForMac() abort
  silent! nmap <silent> <unique> ¡ <Plug>AirlineSelectTab1
  silent! nmap <silent> <unique> ™ <Plug>AirlineSelectTab2
  silent! nmap <silent> <unique> £ <Plug>AirlineSelectTab3
  silent! nmap <silent> <unique> ¢ <Plug>AirlineSelectTab4
  silent! nmap <silent> <unique> ∞ <Plug>AirlineSelectTab5
  silent! nmap <silent> <unique> § <Plug>AirlineSelectTab6
  silent! nmap <silent> <unique> ¶ <Plug>AirlineSelectTab7
  silent! nmap <silent> <unique> • <Plug>AirlineSelectTab8
  silent! nmap <silent> <unique> ª <Plug>AirlineSelectTab9
endfunction

function! s:SetupTablineMappingForLinux() abort
  if has('gui_running')
    silent! nmap <silent> <unique> <M-1> <Plug>AirlineSelectTab1
    silent! nmap <silent> <unique> <M-2> <Plug>AirlineSelectTab2
    silent! nmap <silent> <unique> <M-3> <Plug>AirlineSelectTab3
    silent! nmap <silent> <unique> <M-4> <Plug>AirlineSelectTab4
    silent! nmap <silent> <unique> <M-5> <Plug>AirlineSelectTab5
    silent! nmap <silent> <unique> <M-6> <Plug>AirlineSelectTab6
    silent! nmap <silent> <unique> <M-7> <Plug>AirlineSelectTab7
    silent! nmap <silent> <unique> <M-8> <Plug>AirlineSelectTab8
    silent! nmap <silent> <unique> <M-9> <Plug>AirlineSelectTab9
  else
    silent! nmap <silent> <unique> 1 <Plug>AirlineSelectTab1
    silent! nmap <silent> <unique> 2 <Plug>AirlineSelectTab2
    silent! nmap <silent> <unique> 3 <Plug>AirlineSelectTab3
    silent! nmap <silent> <unique> 4 <Plug>AirlineSelectTab4
    silent! nmap <silent> <unique> 5 <Plug>AirlineSelectTab5
    silent! nmap <silent> <unique> 6 <Plug>AirlineSelectTab6
    silent! nmap <silent> <unique> 7 <Plug>AirlineSelectTab7
    silent! nmap <silent> <unique> 8 <Plug>AirlineSelectTab8
    silent! nmap <silent> <unique> 9 <Plug>AirlineSelectTab9
  endif
endfunction

function! s:SetupTablineMappingForWindows() abort
  silent! nmap <silent> <unique> ± <Plug>AirlineSelectTab1
  silent! nmap <silent> <unique> ² <Plug>AirlineSelectTab2
  silent! nmap <silent> <unique> ³ <Plug>AirlineSelectTab3
  silent! nmap <silent> <unique> ´ <Plug>AirlineSelectTab4
  silent! nmap <silent> <unique> µ <Plug>AirlineSelectTab5
  silent! nmap <silent> <unique> ¶ <Plug>AirlineSelectTab6
  silent! nmap <silent> <unique> · <Plug>AirlineSelectTab7
  silent! nmap <silent> <unique> ¸ <Plug>AirlineSelectTab8
  silent! nmap <silent> <unique> ¹ <Plug>AirlineSelectTab9
endfunction

let s:tablinefns = {
      \ 'mac' : function('s:SetupTablineMappingForMac'),
      \ 'linux' : function('s:SetupTablineMappingForLinux'),
      \ 'windows' : function('s:SetupTablineMappingForWindows'),
      \ }
function! vimutils#SetupTablineMappings(OS)
  let l:os = ''
  if a:OS.is_mac
    let l:os = 'mac'
  elseif a:OS.is_linux
    let l:os = 'linux'
  elseif a:OS.is_windows
    let l:os = 'windows'
  endif
  if !empty(l:os)
    call call(s:tablinefns[l:os], [])
  endif
endfunction
" }}}


" Remove trailing whitespaces and ^M chars
function! vimutils#StripTrailingWhitespace() abort " {{{
  " Preparation: save last search, and cursor position.
  let _s=@/
  let l = line(".")
  let c = col(".")
  " Do the business:
  %s/\s\+$//e
  " Clean up: restore previous search history, and cursor position
  let @/=_s
  call cursor(l, c)
endfunction
" }}}


" Allow using command :E to edit multiple files
" Only files (not directories) matched by the glob pattern will be edited
function! vimutils#MultiEdit(really, ...) abort " {{{
  if len(a:000)
    for globspec in a:000
      let l:files = split(glob(globspec), "\n")
      for fname in l:files
        if !isdirectory(fname)
          exec 'e'.(a:really).' '.(fname)
        endif
      endfor
    endfor
  else
    exec 'e'.(a:really)
  endif
endfunction
" }}}


" Highlight hex strings with the color the hex string represents {{{
let s:HexColored = 0
let s:HexColors = []

" Returns an approximate grey index for the given grey level
function! s:grey_number(x) abort " {{{
  if &t_Co == 88
    if a:x < 23
      return 0
    elseif a:x < 69
      return 1
    elseif a:x < 103
      return 2
    elseif a:x < 127
      return 3
    elseif a:x < 150
      return 4
    elseif a:x < 173
      return 5
    elseif a:x < 196
      return 6
    elseif a:x < 219
      return 7
    elseif a:x < 243
      return 8
    else
      return 9
    endif
  else
    if a:x < 14
      return 0
    else
      let l:n = (a:x - 8) / 10
      let l:m = (a:x - 8) % 10
      if l:m < 5
        return l:n
      else
        return l:n + 1
      endif
    endif
  endif
endfunction
" }}}

" Returns the actual grey level represented by the grey index
function! s:grey_level(n) abort " {{{
  if &t_Co == 88
    if a:n == 0
      return 0
    elseif a:n == 1
      return 46
    elseif a:n == 2
      return 92
    elseif a:n == 3
      return 115
    elseif a:n == 4
      return 139
    elseif a:n == 5
      return 162
    elseif a:n == 6
      return 185
    elseif a:n == 7
      return 208
    elseif a:n == 8
      return 231
    else
      return 255
    endif
  else
    if a:n == 0
      return 0
    else
      return 8 + (a:n * 10)
    endif
  endif
endfunction
" }}}

" Returns the palette index for the given grey index
function! s:grey_color(n) abort " {{{
  if &t_Co == 88
    if a:n == 0
      return 16
    elseif a:n == 9
      return 79
    else
      return 79 + a:n
    endif
  else
    if a:n == 0
      return 16
    elseif a:n == 25
      return 231
    else
      return 231 + a:n
    endif
  endif
endfunction
" }}}

" Returns an approximate color index for the given color level
function! s:rgb_number(x) abort " {{{
  if &t_Co == 88
    if a:x < 69
      return 0
    elseif a:x < 172
      return 1
    elseif a:x < 230
      return 2
    else
      return 3
    endif
  else
    if a:x < 75
      return 0
    else
      let l:n = (a:x - 55) / 40
      let l:m = (a:x - 55) % 40
      if l:m < 20
        return l:n
      else
        return l:n + 1
      endif
    endif
  endif
endfunction
" }}}

" Returns the actual color level for the given color index
function! s:rgb_level(n) abort " {{{
  if &t_Co == 88
    if a:n == 0
      return 0
    elseif a:n == 1
      return 139
    elseif a:n == 2
      return 205
    else
      return 255
    endif
  else
    if a:n == 0
      return 0
    else
      return 55 + (a:n * 40)
    endif
  endif
endfunction
" }}}

" Returns the palette index for the given R/G/B color indices
function! s:rgb_color(x, y, z) abort " {{{
  if &t_Co == 88
    return 16 + (a:x * 16) + (a:y * 4) + a:z
  else
    return 16 + (a:x * 36) + (a:y * 6) + a:z
  endif
endfunction
" }}}

" Returns the palette index to approximate the given R/G/B color levels
function! s:color(r, g, b) abort " {{{
  " get the closest grey
  let l:gx = s:grey_number(a:r)
  let l:gy = s:grey_number(a:g)
  let l:gz = s:grey_number(a:b)

  " get the closest color
  let l:x = s:rgb_number(a:r)
  let l:y = s:rgb_number(a:g)
  let l:z = s:rgb_number(a:b)

  if l:gx == l:gy && l:gy == l:gz
    " there are two possibilities
    let l:dgr = s:grey_level(l:gx) - a:r
    let l:dgg = s:grey_level(l:gy) - a:g
    let l:dgb = s:grey_level(l:gz) - a:b
    let l:dgrey = (l:dgr * l:dgr) + (l:dgg * l:dgg) + (l:dgb * l:dgb)
    let l:dr = s:rgb_level(l:gx) - a:r
    let l:dg = s:rgb_level(l:gy) - a:g
    let l:db = s:rgb_level(l:gz) - a:b
    let l:drgb = (l:dr * l:dr) + (l:dg * l:dg) + (l:db * l:db)
    if l:dgrey < l:drgb
      " use the grey
      return s:grey_color(l:gx)
    else
      " use the color
      return s:rgb_color(l:x, l:y, l:z)
    endif
  else
    " only one possibility
    return s:rgb_color(l:x, l:y, l:z)
  endif
endfunction
" }}}

" Returns the palette index to approximate the '#rrggbb' hex string
function! s:rgb(rgb) abort " {{{
  let l:r = ("0x" . strpart(a:rgb, 1, 2)) + 0
  let l:g = ("0x" . strpart(a:rgb, 3, 2)) + 0
  let l:b = ("0x" . strpart(a:rgb, 5, 2)) + 0

  return s:color(l:r, l:g, l:b)
endfunction
" }}}

" Highlight the hex string
function! vimutils#HexHighlight() abort " {{{
  if !((&t_Co == 256) || has("gui_running"))
    echo "t_Co must be set to 256 or vim must be in gui mode."
    return
  endif

  if s:HexColored == 0
    let hexGroup = 0
    let lineNumber = 0
    while lineNumber <= line("$")
      let currentLine = getline(lineNumber)
      let hexLineMatch = 1
      while match(currentLine, '#\x\{6}', 0, hexLineMatch) != -1
        let hexMatch = matchstr(currentLine, '#\x\{6}', 0, hexLineMatch)
        if has("gui_running")
          execute 'hi HexColor' . hexGroup . ' guibg=' . hexMatch . ' guifg=White'
        else
          execute 'hi HexColor' . hexGroup . ' ctermbg=' . s:rgb(hexMatch) . ' ctermfg=White'
        endif
        execute 'call matchadd("HexColor' . hexGroup . '", "' . hexMatch .'")'
        let s:HexColors += ['HexColor' . hexGroup]
        let hexGroup += 1
        let hexLineMatch += 1
      endwhile
      let lineNumber += 1
    endwhile
    unlet lineNumber hexGroup
    let s:HexColored = 1
  elseif s:HexColored == 1
    for hexColor in s:HexColors
      exe 'highlight clear ' . hexColor
    endfor
    call clearmatches()
    let s:HexColored = 0
  endif
endfunction
" }}}
" }}}


" Wrapper for Decho to enable / disable it conveniently
function! vimutils#Decho(msg) abort " {{{
  if !exists('g:decho_enable')
    let g:decho_enable = 0
  endif
  if g:decho_enable && exists(":Decho")
    Decho a:msg
  endif
endfunction
" }}}


" Wrapper for Decho to echo debug information from a command execution
function! vimutils#DechoCmd(cmd) abort " {{{
  redir => l:msg
  silent execute a:cmd
  redir END
  silent execute "Decho '" . l:msg . "'"
endfunction
" }}}


" Enable jumping using location list when only one error exists
function! vimutils#LocationPrevious() abort " {{{
  try
    lprev
  catch /^Vim\%((\a\+)\)\=:E553/
    llast
  endtry
endfunction

function! vimutils#LocationNext()
  try
    lnext
  catch /^Vim\%((\a\+)\)\=:E553/
    lfirst
  endtry
endfunction
" }}}


" Insert charater char from current position until the cursor reaches column n
function! vimutils#FillWithCharTillN(char, n) abort " {{{
  let l:col = getpos('.')[2]
  if l:col >= a:n
    return
  endif

  let l:num_chars = a:n - l:col + 1
  if (strlen(getline('.')) == 0)
    let l:num_chars += 1
  endif
  exec "normal i" . repeat(a:char, l:num_chars)
endfunction
" }}}


" Map key to toggle options
" Display-altering option toggles
" nnoremap <leader>ts :let &spell = !&spell<CR>
" MapToggle <F2> spell
function! vimutils#MapToggle(key, opt) abort "  {{{
  let l:cmd = ':set ' . a:opt . '! \| set ' . a:opt . "?\<CR>"
  exec 'nnoremap ' . a:key . ' ' . l:cmd
  exec 'inoremap ' . a:key . " \<C-O>" . l:cmd
endfunction
" }}}


" Map key to toggle global variable. Value 1 will be assigned if original
" value is 0.
function! vimutils#MapToggleVar(key, var) abort " {{{
  execute 'nnoremap ' . a:key . ' :call <SID>ToggleVar(' . a:var . ')<CR>'
endfunction

function! s:ToggleVar(var)
  execute "let l:varval=g:" . a:var
  if l:varval > 0
    let l:varval = 0
  else
    let l:varval = 1
  endif
  execute "let g:" . a:var . "=l:varval"
endfunction
" }}}


" Highlight columns that is larger than textwidth
function! vimutils#HighlightTooLongLines() "  {{{
  if !exists('b:htll') || b:htll == 0
    let b:htll = 1
    highlight def link RightMargin Error
    " sign define errlongline text=>> texthl=ErrorMsg
    if &textwidth != 0
      let b:htllm = matchadd('ErrorMsg', '\%>' . &l:textwidth . 'v.\+', -1)
    endif
  else
    let b:htll = 0
    if (exists('b:htllm'))
      call matchdelete(b:htllm)
    endif
  endif
endfunction
" }}}


" Highlight columns from 81 - 120 to red
function! vimutils#ToggleColorColumn() abort " {{{
  if &colorcolumn
    let &colorcolumn = ""
  else
    let &colorcolumn = join(range(81,120), ',')
  endif
endfunction
" }}}


" Copy selected text to system clipboard and prevent it from clearing
" clipboard when using ctrl+z
function! vimutils#CopyText() abort " {{{
  if &clipboard is# 'unnamedplus'
    let l:reg = getreg('+')
  else
    let l:reg = getreg('*')
  endif
  " Preserve single quotes
  let l:reg = substitute(l:reg, "'", "'\"'\"'", 'g')
  let l:reg = substitute(l:reg, '%', '%%', 'g')
  let l:reg = substitute(l:reg, '\\', '\\\\', 'g')
  " let l:reg = shellescape(substitute(l:reg, "\x0a", "", ""))
  " let l:cmd = '/bin/echo -n -- ''' . l:reg . ''' | xclipper -selection clipboard -i'
  " Printf is more portable, echo can be either a shell built-in or a binary.
  " the shell built-in echo doesn't accept -n in OSX.
  let l:cmd = 'printf -- ''' . l:reg . ''' | xclipper -selection clipboard -i'
  DebugEcho l:cmd
  call system(l:cmd)
endfunction
" }}}


" Insert repeated strings according to a pattern / template
function! vimutils#InsertRepeated(tmpl, lower, upper) abort " {{{
  let l:strs = split(a:tmpl, "%i", 1)
  for i in range(a:lower, a:upper)
    let l:str = join(l:strs, "" . i)
    put = l:str
  endfor
endfunction

" function! vimutils#InsertRepeated(tmpl, lower, upper)
" put =map(range(a:lower, a:upper), 'printf(''%d'', v:val)')
" endfunction
" }}}


" Test whether a specific syntax group exists
function! vimutils#SyntaxGroupExists(group_name) abort " {{{
  let l:syntaxes=""
  redir => l:syntaxes
  silent syntax
  redir END
  return stridx(l:syntaxes, a:group_name) > 0
endfunction
" }}}


" Get the definition of a syntax group
function! vimutils#GetSynGroup(group_name) abort " {{{
  let l:syngroup=""
  redir => l:syngroup
  execute "silent! syntax list " . a:group_name
  redir END
  let l:groups = split(l:syngroup, "\n")
  if len(l:groups) != 2
    return ""
  endif
  return maktaba#string#Strip(l:groups[1])
endfunction
" }}}


" Find the window among all windows that with w:id equals to wid
function! vimutils#FindWindowWithId(wid) abort " {{{
  for tabnr in range(1, tabpagenr('$'))
    for winnr in range(1, tabpagewinnr(tabnr, '$'))
      if gettabwinvar(tabnr, winnr, 'id') is a:wid
        return [tabnr, winnr]
      endif
    endfor
  endfor
  return [0, 0]
endfunction
" }}}


" Converts a file with MS-DOS line ending to UNIX line ending
function! vimutils#Dos2unixFunction() abort "{{{
  let _s=@/
  let l = line(".")
  let c = col(".")
  try
    set ff=unix
    w!
    "%s/\%x0d$//e
  catch /E32:/
    echo "Sorry, the file is not saved."
  endtry
  let @/=_s
  call cursor(l, c)
endfun
" }}}


" Initialization directories and settings for undo, swap and views.
function! vimutils#InitUndoSwapViews() abort " {{{
  let l:prefix = expand('~/.vim/')
  let l:dir_list = {
        \ '.vimbackup' : 'backupdir',
        \ '.vimviews' : 'viewdir',
        \ '.vimswap' : 'directory',
        \ '.vimundo' : 'undodir'
        \ }
  for [dirname, settingname] in items(l:dir_list)
    let l:directory = l:prefix . dirname . '/'
    if !isdirectory(l:directory)
      if exists('*mkdir')
        try
          call mkdir(l:directory, 'p')
        catch /E739:/
          echo 'Error: Failed to create directory: ' . l:directory
        endtry
      else
        echo 'Warning: mkdir not available. Unable to create directory:'
              \ l:directory
      endif
    endif
    " Escape spaces in the path
    let l:directory = substitute(l:directory, ' ', '\\\\ ', 'g')
    execute 'set' settingname . '=' . l:directory
  endfor
endfunction
" }}}


" Wrap the visually selected text in folds
function! vimutils#WrapInFold(fid, insert) range abort " {{{
  let l:line = getline(a:firstline)
  execute 'normal ' . a:firstline . 'GO'
  let l:indent = matchstr(l:line, '\v^\zs(\s*)\zeNeoBundle')
  if a:insert
    let l:foldpre = '  '
  else
    let l:foldpre = ' '
  endif
  let l:foldpre = l:indent. '"' . l:foldpre . '{{{' . a:fid
  call setline(a:firstline, l:foldpre)
  execute 'normal ' . (a:lastline + 1) . 'Go'
  call setline(a:lastline + 2, l:indent . '" }}}')
  call setpos('.', [bufnr('%'), a:firstline, 3, 0])
  if a:insert
    startinsert
  endif
endfunction
" }}}


" Sort a set of folded text blocks by its foldtext. Only sorts the top level
" folds. The folds must be all closed when this is called.
function! vimutils#SortFoldByFoldtext() range abort " {{{
  execute (a:firstline) . ',' . (a:lastline) . 'foldopen!'
  execute (a:firstline) . ',' . (a:lastline) . 'foldclose'
  let l:folds = s:GetFolds(a:firstline, a:lastline)
  let l:keys = sort(keys(l:folds))
  let l:lines = []
  for key in l:keys
    let l:fold = get(l:folds, key)
    for i in range(l:fold[0], l:fold[1])
      call add(l:lines, getline(i))
    endfor
  endfor
  call maktaba#buffer#Overwrite(a:firstline, a:lastline, l:lines)
  " The folds are messed up after that. doautocmd to rebuild the folds
  " TODO: How to avoid this?
  doautocmd
  execute a:firstline . 'foldopen'
endfunction

function! s:GetFolds(start, end) abort " {{{
  let l:folds = {}
  let l:foldend = a:start
  while l:foldend < a:end
    let l:foldstart = foldclosed(l:foldend)
    let l:foldend = foldclosedend(l:foldend)
    if l:foldstart == -1 || l:foldend == -1
      let l:foldend += 1
      continue
    endif
    let l:summary = matchstr(
          \ foldtextresult(l:foldstart),
          \ '\v^\+-+\s*[0-9]+ lines: \zs(.*)\ze')
    call extend(l:folds, { l:summary : [l:foldstart, l:foldend]})
    let l:foldend += 1
  endwhile
  return l:folds
endfunction
" }}}

" Use ranger as a file chooser in vim
" source: https://github.com/hut/ranger/blob/master/examples/vim_file_chooser.vim
function! vimutils#RangerChooser() abort
  let temp = tempname()
  " The option "--choosefiles" was added in ranger 1.5.1. Use the next line
  " with ranger 1.4.2 through 1.5.0 instead.
  "exec 'silent !ranger --choosefile=' . shellescape(temp)
  if has("gui_running")
      exec 'silent !xterm -e ranger --choosefiles=' . shellescape(temp)
  else
      exec 'silent !ranger --choosefiles=' . shellescape(temp)
  endif
  if !filereadable(temp)
      redraw!
      " Nothing to read.
      return
  endif
  let names = readfile(temp)
  if empty(names)
      redraw!
      " Nothing to open.
      return
  endif
  " Edit the first item.
  exec 'edit ' . fnameescape(names[0])
  " Add any remaning items to the arg list/buffer list.
  for name in names[1:]
      exec 'argadd ' . fnameescape(name)
  endfor
  redraw!
endfunction
" }}}

function! vimutils#ForEach(fn) range abort
  let l:col_l = col("'<") - 1
  let l:col_r = col("'>") - 1
  for l in range(a:firstline, a:lastline)
    let l:line = getline(l)
    exec a:fn . ' "' l:line[l:col_l:l:col_r] . '"'
  endfor
endfunction
