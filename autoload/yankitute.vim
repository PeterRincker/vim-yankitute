let s:supports_n_flag = v:version >= 704 || (v:version == 703 && has('patch627'))

function! yankitute#execute(cmd, start, end, reg) abort
  let [reg, cmd] = a:reg =~? '[a-z0-9"]' ? [a:reg, a:cmd] : ['"', a:reg . a:cmd]
  let sep = strlen(cmd) ? cmd[0] : '/'
	let [pat, replace, flags, join; _] = split(cmd[1:], '\v([^\\](\\\\)*\\)@<!%d' . char2nr(sep), 1) + ['', '', '', '']

  if pat != ''
    let @/ = pat
  endif

  if replace == ''
    let replace = '&'
  endif
  let is_sub_replace = replace =~ '^\\='
  let fn = 'yankitute#' . (is_sub_replace ? 'eval' : 'gather') . '(results,replace)'
  if is_sub_replace
    let replace = replace[2:]
  endif

  let flags = s:supports_n_flag ? ('n' . flags) : substitute(flags, '\Cn', '', 'g')
  let [flags, silent] = flags !~# 'c' ? [flags, 'silent '] : [substitute(flags, '\Cn', '', 'g'), '']

  let modified = &modified
  let results = []
  let v:errmsg = ''
  let win = winsaveview()
  try
    execute 'keepjumps ' . silent . a:start . ',' . a:end . 's' . sep . pat . sep . '\=' . fn . sep . flags
  catch
    let v:errmsg = substitute(v:exception, '.*:\zeE\d\+:\s', '', '')
    return 'echoerr v:errmsg'
  finally
    call winrestview(win)
    let &modified = modified
  endtry

  if !is_sub_replace
    for i in range(len(results))
      let m = results[i]
      let results[i] = substitute(replace, '\v%(%(\\\\)*\\)@<!%(\\(\d)|(\&))', '\=yankitute#replace(submatch(1),m)', 'g')
    endfor
  endif

  let [join, type] = join == '' ? ["\n", 'l'] : [join, 'c']
  call setreg(reg, join(results, join), type)
  return ''
endfunction

function! yankitute#gather(results, ...) abort
  call add(a:results, map(range(10), 'submatch(v:val)'))
  return submatch(0)
endfunction

function! yankitute#eval(results, replace) abort
  call add(a:results, eval(a:replace]))
  return submatch(0)
endfunction

function! yankitute#replace(char, matches) abort
  return get(a:matches, a:char == '&' ? 0 : a:char)
endfunction
