" =============================================================================
" Filename: autoload/lightline/delphinus/components.vim
" Author: delphinus
" License: MIT License
" Last Change: 2018-03-24T23:37:51+0900.
" =============================================================================

scriptencoding utf-8

if g:lightline_delphinus_use_nerd_fonts_glyphs
  let s:mo_glyph = ''
  let s:help_glyph = ''
  let s:ale_linting_glyph = '   '
else
  let s:mo_glyph = '+'
  let s:help_glyph = '?'
  let s:ale_linting_glyph = '....'
endif

if g:lightline_delphinus_use_powerline_glyphs
  let s:ro_glyph = ''
else
  let s:ro_glyph = 'RO'
endif

function! lightline#delphinus#components#modified() abort
  return &filetype =~# 'help\|vimfiler\|gundo' ? '' :
        \ &modified ? s:mo_glyph : &modifiable ? '' :
        \ '-'
endfunction

function! lightline#delphinus#components#readonly() abort
  return &filetype ==# 'help' ? s:help_glyph :
        \ &filetype !~# 'vimfiler\|gundo' && &readonly ? s:ro_glyph :
        \ ''
endfunction

function! lightline#delphinus#components#filepath() abort
  if &buftype ==# 'terminal'
    return ''
  endif
  if &filetype ==# 'denite'
    let l:ctx = get(b:, 'denite_context', {})
    return get(l:ctx, 'sorters', '')
  endif
  let l:ro_string = '' !=# lightline#delphinus#components#readonly() ? lightline#delphinus#components#readonly() . ' ' : ''
  if &filetype ==# 'vimfilter' || &filetype ==# 'unite' || winwidth(0) < 70
    let l:path_string = ''
  else
    let l:path_string = substitute(expand('%:h'), $HOME, '~', '')
    if winwidth(0) < 120 && len(l:path_string) > 30
      let l:path_string = substitute(l:path_string, '\v([^/])[^/]*%(/)@=', '\1', 'g')
    endif
  endif

  return l:ro_string . l:path_string
endfunction

function! lightline#delphinus#components#filename() abort
  return (&buftype ==# 'terminal' ? b:term_title . ' (' . b:terminal_job_pid . ')' :
        \ &filetype ==# 'vimfiler' ? vimfiler#get_status_string() :
        \ &filetype ==# 'unite' ? unite#get_status_string() :
        \ &filetype ==# 'denite' ? denite#get_status_sources() :
        \ '' !=# expand('%:t') ? expand('%:t') : '[No Name]') .
        \ ('' !=# lightline#delphinus#components#modified() ? ' ' . lightline#delphinus#components#modified() : '')
endfunction

function! lightline#delphinus#components#fugitive() abort
  if winwidth(0) < 100
    return ''
  endif
  try
    if &filetype !~? 'vimfiler\|gundo\|denite' && exists('*fugitive#head')
      return fugitive#head()
    endif
  catch
  endtry
  return ''
endfunction

function! lightline#delphinus#components#fileformat() abort
  return &filetype ==# 'denite' ? '' :
        \ winwidth(0) > 120 ? &fileformat . (exists('*WebDevIconsGetFileFormatSymbol') ? ' ' . WebDevIconsGetFileFormatSymbol() : '') : ''
endfunction

function! lightline#delphinus#components#filetype() abort
  return &filetype ==# 'denite' ? '' :
        \ winwidth(0) > 120 ? (strlen(&filetype) ? &filetype . (exists('*WebDevIconsGetFileTypeSymbol') ? ' ' . WebDevIconsGetFileTypeSymbol() : '') : 'no ft') : ''
endfunction

function! lightline#delphinus#components#fileencoding() abort
  return &filetype ==# 'denite' ? '' :
        \ winwidth(0) > 120 ? (strlen(&fileencoding) ? &fileencoding : &encoding) : ''
endfunction

function! lightline#delphinus#components#mode() abort
  if &filetype ==# 'denite'
    let l:mode = denite#get_status('raw_mode')
    call lightline#link(tolower(l:mode[0]))
    return 'Denite'
  endif
  let l:fname = expand('%:t')
  return &buftype ==# 'terminal' ? 'TERMINAL' :
        \ l:fname =~# 'unite' ? 'Unite' :
        \ l:fname =~# 'vimfiler' ? 'VimFilter' :
        \ l:fname =~# '__Gundo__' ? 'Gundo' :
        \ winwidth(0) > 60 ? lightline#mode() : ''
endfunction

function! lightline#delphinus#components#charcode() abort
  if &filetype ==# 'denite'
    return ''
  endif
  if winwidth(0) <= 120
    return ''
  endif
  " if char on cursor is `Λ̊`, :ascii returns below.
  " <Λ> 923, 16進数 039b, 8進数 1633 < ̊> 778, 16進数 030a, 8進数 1412
  redir => l:tmp | silent! ascii | redir END
  let l:chars = []
  call substitute(l:tmp, '<.>\s\+\d\+,\s\+\S\+ \x\+,\s\+\S\+ \d\+', '\=add(l:chars, submatch(0))', 'g')
  if len(l:chars) == 0
    return ''
  endif
  let l:ascii = []
  for l:c in l:chars
    let l:m = matchlist(l:c, '<\(.\)>\s\+\d\+,\s\+\S\+ \(\x\+\)')
    if len(l:m) > 0
      call add(l:ascii, printf('%s %s', l:m[1], l:m[2]))
    endif
  endfor
  return join(l:ascii, ', ')
endfunction

let s:ale_linting = 0

function! lightline#delphinus#components#ale_pre() abort
  let s:ale_linting = 1
  call lightline#update()
endfunction

function! lightline#delphinus#components#ale_post() abort
  let s:ale_linting = 0
  call lightline#update()
endfunction

function! lightline#delphinus#components#ale_error() abort
  return s:ale_string(0)
endfunction

function! lightline#delphinus#components#ale_warning() abort
  return s:ale_string(1)
endfunction

function! lightline#delphinus#components#ale_ok() abort
  return s:ale_string(2)
endfunction

function! s:ale_string(mode)
  if !exists('g:ale_buffer_info') || &filetype ==# 'denite'
    return ''
  endif
  if s:ale_linting
    " it shows an icon in linting with the `warning` color.
    return a:mode == 1 ? s:ale_linting_glyph : ''
  endif

  let l:buffer = bufnr('%')
  let l:counts = ale#statusline#Count(l:buffer)
  let [l:error_format, l:warning_format, l:no_errors] = g:ale_statusline_format

  if a:mode == 0 " Error
    let l:errors = l:counts.error + l:counts.style_error
    return l:errors ? printf(l:error_format, l:errors) : ''
  elseif a:mode == 1 " Warning
    let l:warnings = l:counts.warning + l:counts.style_warning
    return l:warnings ? printf(l:warning_format, l:warnings) : ''
  endif

  return l:counts.total ? '' : l:no_errors
endfunction

function! lightline#delphinus#components#lineinfo() abort
  return &filetype ==# 'denite' ? denite#get_status_linenr() :
        \ printf('%3d:%-2d', line('.'), col('.'))
endfunction

function! lightline#delphinus#components#percent() abort
  let l:line = &filetype ==# 'denite' ? denite#get_status('line_cursor') : line('.')
  let l:total = &filetype ==# 'denite' ? denite#get_status('line_total') : line('$')
  return l:total ? printf('%d%%', 100 * l:line / l:total) : '0%'
endfunction
