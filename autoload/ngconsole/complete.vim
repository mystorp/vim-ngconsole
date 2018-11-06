let s:completeItems = ngconsole#readJson(ngconsole#joinPath([expand("<sfile>:p:h"), "../completions.json"]))

function! ngconsole#complete#autoComplete(buffile)
    if stridx(a:buffile, g:ngconsole_root) != 0
        return
    endif
    au! TextChangedI <buffer> call s:completeFn()
    au! CompleteDone <buffer> call s:fixCursor()
endfunction

function! s:completeFn()
    let l:text = getline(line("."))
    if len(trim(l:text)) == 0
        return
    endif
    let l:col = col(".")
    let l:regexp = '\(\%([a-z0-9\$_]\{-}\)\.\)*\([a-z0-9\$_]\{-}\)$'
    let l:result = matchlist(l:text, l:regexp)
    if len(l:result) == 0
        return
    endif
    let l:invokeChains = split(l:result[0], '\.', v:true)
    if len(l:invokeChains) < 2
        return
    endif
    let l:input = remove(l:invokeChains, -1)
    let l:data = s:completeItems
    let l:invalid = v:false
    for identifer in l:invokeChains
        if type(l:data) == v:t_list
            let l:invalid = v:true
            break
        endif
        let l:data = get(l:data, identifer)
        if l:data is 0
            let l:invalid = v:true
        endif
    endfor
    if l:invalid
        return
    endif
    if type(l:data) == v:t_list
        let l:matchedKeys = l:data
    else
        let l:matchedKeys = keys(l:data)
    endif
    call complete(l:col, len(l:input) == 0 ? l:matchedKeys : filter(l:matchedKeys, 'stridx(v:val, l:input) == 0'))
endfunction

function! s:fixCursor()
    let l:text = v:completed_item.word
    if l:text =~ '\(\)$'
        call cursor(line("."), col(".") - 1)
    endif
endfunction
