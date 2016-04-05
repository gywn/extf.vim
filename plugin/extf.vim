" A more powerful f

if exists("g:loaded_extf") || &cp
  finish
endif
let g:loaded_extf = 100  " version number
let s:save_cpo = &cpo
set cpo&vim

" hi ExtfIncSearch cterm=underline
hi link ExtfIncSearch IncSearch 

if !hasmapto('<Plug>Extf')
  nmap <unique> f <Plug>Extf
endif
if !hasmapto('<Plug>ExtF')
  nmap <unique> F <Plug>ExtF
endif

function! s:plist(str, pat) abort
  let l:plist = []
  let l:last_pos = stridx(a:str, a:pat)
  while l:last_pos > -1
    call add(l:plist, l:last_pos)
    let l:last_pos = stridx(a:str, a:pat, l:last_pos + 1)
  endwhile
  if b:extf.drt == -1
    call reverse(filter(l:plist, 'v:val < b:extf.origc - 1'))
  elseif b:extf.drt == 1
    call filter(l:plist, 'v:val > b:extf.origc - 1')
  endif
  return l:plist
endfunction

function! s:clear_highlight() abort
  if b:extf.hl_id > 1
    call matchdelete(b:extf.hl_id)
    let b:extf.hl_id = -1
  endif
endfunction

function! s:add_highlight(col) abort
  call s:clear_highlight()
  let b:extf.hl_id = matchadd('ExtfIncSearch',
        \ '\%'.b:extf.origl.'l'.
        \ '\%'.a:col.'c'.
        \ '.\{'.len(b:extf.pat).'}')
  call cursor(b:extf.origl, a:col)
endfunction

function! s:initiate(direction) abort
  let b:extf = {
    \ 'drt'   : a:direction,
    \ 'origl' : line('.'),
    \ 'origc' : col('.'),
    \ 'pat'   : '',
    \ 'plist' : [],
    \ 'hl_id' : -1
    \ }

  call feedkeys("\<Plug>_ExtfLoop")
endfunction

function! s:reset(successful) abort
  call s:clear_highlight()
  if ! a:successful
    call cursor(b:extf.origl, b:extf.origc)
  endif

  unlet b:extf
endfunction

function s:cycle_cursor(incr) abort
  if empty(b:extf.plist)
    call s:reset(0) | return
  endif

  let l:idx = index(b:extf.plist, col('.') - 1)
  let l:new_idx = (l:idx + a:incr * b:extf.drt) % len(b:extf.plist)
  if l:new_idx == l:idx
    call s:reset(1) | return
  endif
  call s:add_highlight(get(b:extf.plist, l:new_idx) + 1)

  call feedkeys("\<Plug>_ExtfLoop")
endfunction

function! s:normal_key() abort
  if ! getchar(1)
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

  let b:extf.plist = s:plist(getline(b:extf.origl), b:extf.pat)
  if empty(b:extf.plist)
    "only c d f g h i j k l m p v F P \" % : @ are permitted to be re-emitted
    if index([99, 100, 102, 103, 104, 105, 106, 107, 108, 109,
          \ 112, 118, 70, 80, 34, 37, 58, 64], l:char) > -1
      call feedkeys(nr2char(l:char))
    elseif l:char == 97  " a: insert after last char
      call feedkeys(string(len(b:extf.pat) - 1) . 'li')
    else
      exec "normal \<Esc>"
    endif

    call s:reset(1)
    return
  endif
  call s:add_highlight(get(b:extf.plist, 0) + 1)

  call feedkeys("\<Plug>_ExtfLoop")
endfunction

" <S-TAB> = <ESC>[Z, so <ESC> connot be used
map <silent> <unique> <script> <Plug>_ExtfLoop<C-c>   :call <SID>reset(0)<CR>
map <silent> <unique> <script> <Plug>_ExtfLoop<CR>    :call <SID>reset(1)<CR>
map <silent> <unique> <script> <Plug>_ExtfLoop<TAB>   :call <SID>cycle_cursor(1)<CR>
map <silent> <unique> <script> <Plug>_ExtfLoop<S-TAB> :call <SID>cycle_cursor(-1)<CR>
map <silent> <unique> <script> <Plug>_ExtfLoop        :call <SID>normal_key()<CR>
map <silent> <unique> <script> <Plug>Extf             :call <SID>initiate(1)<CR>
map <silent> <unique> <script> <Plug>ExtF             :call <SID>initiate(-1)<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
