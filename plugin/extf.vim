" A more powerful f

" Try to use native f/F + ;
" finish

if exists("g:loaded_extf") || &cp
  finish
endif
let g:loaded_extf = 100  " version number
let s:save_cpo = &cpo
set cpo&vim

hi link ExtfIncSearch IncSearch

function! s:plist(str, pat) abort
  let l:plist = []
  let l:last_pos = stridx(a:str, a:pat)
  while l:last_pos > -1
    call add(l:plist, l:last_pos)
    let l:last_pos = stridx(a:str, a:pat, l:last_pos + 1)
  endwhile
  if b:extf.drt == -1
    call reverse(filter(l:plist, 'v:val < b:extf.c - 1'))
  elseif b:extf.drt == 1
    call filter(l:plist, 'v:val > b:extf.c - 1')
  endif
  return l:plist
endfunction

function! s:clear_highlight() abort
  if b:extf.hl_id > 1
    call matchdelete(b:extf.hl_id)
    let b:extf.hl_id = -1
  endif
endfunction

function! s:add_highlight(l1, c1v, c1p, l2, c2v, c2p) abort
  let l:all_c = [a:c1v, a:c1p, a:c2v, a:c2p]
  let [l:l1, l:c1, l:l2, l:c2] = a:l1 == a:l2 ?
        \ [a:l1, min(l:all_c), a:l2, max(l:all_c)] :
        \ [a:l1, a:c1v, a:l2, a:c2p]
  return matchadd(b:extf.mode == 0 ? 'ExtfIncSearch' : 'Visual',
        \ '\%'.l:l1.'l\%'.l:c1.'c\_.*\%'.l:l2.'l\%'.l:c2.'c.')
endfunction

function! s:update_hl_sel(col) abort
  if a:col > 0 | let b:extf.cc = a:col | endif

  call s:clear_highlight()

  let [l:l, l:cc, l:d] = [b:extf.l, b:extf.cc, max([0, len(b:extf.pat) - 1])]
  if b:extf.mode == 0
    let b:extf.hl_id = s:add_highlight(l:l, l:cc, l:cc, l:l, l:cc, l:cc + l:d)
    call cursor(l:l, l:cc)
  elseif b:extf.mode == 1
    let [_, l:ol, l:oc, _] = getpos("'>")
    let b:extf.hl_id = s:add_highlight(l:l, l:cc, l:cc + l:d, l:ol, l:oc, l:oc)
    call cursor(l:l, l:cc)
  elseif b:extf.mode == 2
    let [_, l:ol, l:oc, _] = getpos("'<")
    let b:extf.hl_id = s:add_highlight(l:ol, l:oc, l:oc, l:l, l:cc, l:cc + l:d)
    call cursor(l:l, l:cc + l:d)
  endif

endfunction

" direction - -1: left   1: right
"      mode -  0: normal 1: visual
function! s:initiate(direction, mode) abort range
  if a:mode == 1
    call feedkeys("\<ESC>", 'inx')
    if visualmode() != 'v' | return 'gv' | endif
  endif

  " 0: normal 1: visual head 2: visual tail
  let l:m = a:mode == 'n' ? 0 : getpos('.') == getpos("'<") ? 1 : 2

  let b:extf = {
    \ 'mode'  : l:m,
    \ 'drt'   : a:direction,
    \ 'l' : l:m == 0 ? line('.') : l:m == 1 ? getpos("'<")[1] : getpos("'>")[1],
    \ 'c' : l:m == 0 ?  col('.') : l:m == 1 ? getpos("'<")[2] : getpos("'>")[2],
    \ 'pat'   : '',
    \ 'plist' : [],
    \ 'hl_id' : -1
    \ }
  call s:update_hl_sel(b:extf.c)  " setting cursor position won't work for <expr>

  call feedkeys("\<Plug>_ExtfLoop") | return ''
endfunction

function! s:select_region(l1, c1v, c1p, l2, c2v, c2p) abort
  let l:all_c = [a:c1v, a:c1p, a:c2v, a:c2p]
  let [l:l1, l:c1, l:l2, l:c2] = a:l1 == a:l2 ?
        \ [a:l1, min(l:all_c), a:l2, max(l:all_c)] :
        \ [a:l1, a:c1v, a:l2, a:c2p]
  call setpos("'<", [0, l:l1, l:c1, 0])
  call setpos("'>", [0, l:l2, l:c2, 0])
  normal gv
endfunction

function! s:reset(ok) abort
  call s:clear_highlight()

  let [l:l, l:c, l:cc, l:d] = [b:extf.l, b:extf.c, b:extf.cc, max([0, len(b:extf.pat) - 1])]
  if b:extf.mode == 0
    call cursor(l:l, a:ok ? l:cc : l:c)
  elseif b:extf.mode == 1
    let [_, l:ol, l:oc, _] = getpos("'>")
    call s:select_region(l:l, a:ok ? l:cc : l:c, a:ok ? l:cc + l:d : l:c, l:ol, l:oc, l:oc)
  elseif b:extf.mode == 2
    let [_, l:ol, l:oc, _] = getpos("'<")
    call s:select_region(l:ol, l:oc, l:oc, l:l, a:ok ? l:cc : l:c, a:ok ? l:cc + l:d : l:c)
  endif
endfunction

function s:cycle_cursor(incr) abort
  if empty(b:extf.plist)
    call s:reset(0) | return
  endif

  let l:idx = index(b:extf.plist, b:extf.cc - 1)
  let l:new_idx = (l:idx + a:incr * b:extf.drt) % len(b:extf.plist)
  if l:new_idx == l:idx
    call s:reset(1) | return
  endif
  call s:update_hl_sel(get(b:extf.plist, l:new_idx) + 1)

  call feedkeys("\<Plug>_ExtfLoop")
endfunction

function! s:normal_key() abort
  if ! getchar(1)
    call s:update_hl_sel(0)
    call feedkeys("\<Plug>_ExtfLoop") | return
  endif

  let l:char = getchar()
  if l:char != "\x80kb" && l:char != "\x80kD"  " <BS> and <DEL>
    let b:extf.pat .= nr2char(l:char)
  else
    let b:extf.pat = b:extf.pat[:-2]
  endif

  if b:extf.pat == '' | call s:reset(0) | return
  endif

  let b:extf.plist = s:plist(getline(b:extf.l), b:extf.pat)
  if empty(b:extf.plist)
    let b:extf.pat = b:extf.pat[:-2]
    call s:reset(1)
    "only c d y f g h i j k l m p v F P \" % : @ are permitted to be re-emitted
    if index([99, 100, 121, 102, 103, 104, 105, 106, 107, 108, 109,
          \ 112, 118, 70, 80, 34, 37, 58, 64], l:char) > -1
      call feedkeys(nr2char(l:char))
    elseif l:char == 97  " a: insert after last char
      call feedkeys(string(len(b:extf.pat)) . 'li')
    else
      exec "normal \<Esc>"
    endif
    return
  endif
  call s:update_hl_sel(get(b:extf.plist, 0) + 1)

  call feedkeys("\<Plug>_ExtfLoop")
endfunction

" <S-TAB> = <ESC>[Z, so <ESC> connot be used
map <silent> <unique> <script> <Plug>_ExtfLoop<C-c>   :call <SID>reset(0)<CR>
map <silent> <unique> <script> <Plug>_ExtfLoop<CR>    :call <SID>reset(1)<CR>
map <silent> <unique> <script> <Plug>_ExtfLoop<TAB>   :call <SID>cycle_cursor(1)<CR>
map <silent> <unique> <script> <Plug>_ExtfLoop<S-TAB> :call <SID>cycle_cursor(-1)<CR>
map <silent> <unique> <script> <Plug>_ExtfLoop        :call <SID>normal_key()<CR>
nmap <silent> <unique> <script> <expr> f            <SID>initiate(1, 0)
nmap <silent> <unique> <script> <expr> F            <SID>initiate(-1, 0)
vmap <silent> <unique> <script> <expr> f            <SID>initiate(1, 1)
vmap <silent> <unique> <script> <expr> F            <SID>initiate(-1, 1)

let &cpo = s:save_cpo
unlet s:save_cpo
