" A more powerful f

if exists("g:loaded_extf") || &cp
  finish
endif
let g:loaded_extf = 100  " version number
let s:save_cpo = &cpo
set cpo&vim

hi ExtfIncSearch cterm=underline

if !hasmapto('<Plug>Extf')
  nmap <unique> f <Plug>Extf
endif
if !hasmapto('<Plug>ExtF')
  nmap <unique> F <Plug>ExtF
endif

function! s:pos_list(str, pat) abort
  let l:pos_list = []
  let l:last_pos = stridx(a:str, a:pat)
  while l:last_pos > -1
    call add(l:pos_list, l:last_pos)
    let l:last_pos = stridx(a:str, a:pat, l:last_pos + 1)
  endwhile
  if b:extf_direction == -1
    call reverse(filter(l:pos_list, 'v:val < b:extf_orig_cnum - 1'))
  elseif b:extf_direction == 1
    call filter(l:pos_list, 'v:val > b:extf_orig_cnum - 1')
  endif
  return l:pos_list
endfunction


function! s:beep() abort
  exec "normal \<Esc>"
endfunction


" function! s:echo_pattern() abort
"   echo '/' . b:extf_pattern
" endfunction


function! s:clear_highlight() abort
  if b:extf_highlight_id > 1
    call matchdelete(b:extf_highlight_id)
    let b:extf_highlight_id = -1
  endif
endfunction


function! s:add_highlight(col) abort
  call s:clear_highlight()
  let b:extf_highlight_id = matchadd('ExtfIncSearch',
        \ '\%'.b:extf_orig_lnum.'l'.
        \ '\%'.a:col.'c'.
        \ '.\{'.len(b:extf_pattern).'}')
endfunction


function! s:initiate(direction) abort
  let b:extf_direction = a:direction  "1: right, -1: left
  let b:extf_line = getline('.')
  let b:extf_orig_lnum = line('.')
  let b:extf_orig_cnum = col('.')

  let b:extf_pattern = ''
  let b:extf_pos_list = []
  let b:extf_highlight_id = -1

  " call s:echo_pattern()
  " redraw

  call feedkeys("\<Plug>_ExtfLoop")
endfunction


function! s:finish(successful) abort
  call s:clear_highlight()
  " echo
  " redraw

  if ! a:successful
    call cursor(b:extf_orig_lnum, b:extf_orig_cnum)
  endif
endfunction


function s:cycle_cursor(incr) abort
  if empty(b:extf_pos_list)
    call s:finish(0) | return
  endif

  let l:idx = index(b:extf_pos_list, col('.') - 1)
  let l:new_idx = (l:idx + a:incr * b:extf_direction) % len(b:extf_pos_list)
  if l:new_idx == l:idx
    call s:finish(1) | return
  endif

  let l:cursor_pos = get(b:extf_pos_list, l:new_idx) + 1

  call s:add_highlight(l:cursor_pos)
  call cursor(b:extf_orig_lnum, l:cursor_pos)

  call feedkeys("\<Plug>_ExtfLoop")
endfunction


function! s:normal_key() abort
  if ! getchar(1) 
    call feedkeys("\<Plug>_ExtfLoop") | return 
  endif

  let l:char = getchar()
  if l:char != "\x80kb" && l:char != "\x80kD"  " <BS> and <DEL>
    let l:pattern = b:extf_pattern . nr2char(l:char)
  elseif empty(b:extf_pattern)
    call s:finish(0) | return
  else
    let l:pattern = strpart(b:extf_pattern, 0, strlen(b:extf_pattern) - 1)
  endif

  if empty(l:pattern)
    let b:extf_pattern = ''
    let b:extf_pos_list = []

    call s:clear_highlight()
    " call s:echo_pattern()
    call cursor(b:extf_orig_lnum, b:extf_orig_cnum)
    call feedkeys("\<Plug>_ExtfLoop") | return 
  endif

  let l:pos_list = s:pos_list(b:extf_line, l:pattern)
  if empty(l:pos_list)
    "only f g h i j k l m p v F P \" % : are permitted to be re-emitted
    if index([102, 103, 104, 105, 106, 107, 108, 109,
          \ 112, 118, 70, 80, 34, 37, 58], l:char) > -1
      call feedkeys(nr2char(l:char)) 
    else
      call s:beep()
    endif
    call s:finish(1)
    return
  endif

  let b:extf_pattern = l:pattern
  let b:extf_pos_list = l:pos_list
  let l:cursor_pos = get(l:pos_list, 0) + 1

  " call s:echo_pattern()
  call s:add_highlight(l:cursor_pos)
  call cursor(b:extf_orig_lnum, l:cursor_pos)

  call feedkeys("\<Plug>_ExtfLoop")
endfunction

" <S-TAB> = <ESC>[Z, so <ESC> connot be used
map <silent> <unique> <script> <Plug>_ExtfLoop<C-c>   :call <SID>finish(0)<CR>
map <silent> <unique> <script> <Plug>_ExtfLoop<CR>    :call <SID>finish(1)<CR>
map <silent> <unique> <script> <Plug>_ExtfLoop<TAB>   :call <SID>cycle_cursor(1)<CR>
map <silent> <unique> <script> <Plug>_ExtfLoop<S-TAB> :call <SID>cycle_cursor(-1)<CR>
map <silent> <unique> <script> <Plug>_ExtfLoop        :call <SID>normal_key()<CR>
map <silent> <unique> <script> <Plug>Extf             :call <SID>initiate(1)<CR>
map <silent> <unique> <script> <Plug>ExtF             :call <SID>initiate(-1)<CR>


let &cpo = s:save_cpo
unlet s:save_cpo
