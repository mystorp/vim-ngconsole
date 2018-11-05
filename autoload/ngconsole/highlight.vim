let s:highlightMatches = {}

highlight ngconsole_has_key term=bold,reverse cterm=bold ctermfg=15 ctermbg=2 gui=bold guifg=bg guibg=DarkGreen
highlight ngconsole_has_no_key term=reverse cterm=reverse ctermfg=1 guifg=White guibg=Red
highlight ngconsole_unknow_key term=underline cterm=underline ctermfg=3

function! ngconsole#highlight#renderHtml(buffile, ...)
    if stridx(a:buffile, g:ngconsole_root) != 0
        return v:false
    endif
    let l:resources = ngconsole#resources#getFor(a:buffile)
    if type(l:resources) != v:t_dict
        return v:false
    endif
    let l:shouldUpdate = a:0 > 0
    let l:lineNumber = 0
    let l:oldMatches = get(s:highlightMatches, a:buffile, [])
    let l:newMatches = []
    let l:regexp = '\%(data-\)\?localize\%(-title\|-placeholder\|-tip\)\?\s*=\s*\("\|''\)\(.\{-}\)\1'
    let l:interpolate = '{{.*}}'
    for text in getline(1, line("$"))
        let l:lineNumber += 1
        let l:matchResult = matchlist(text, l:regexp)
        " not match
        if len(l:matchResult) == 0
            continue
        endif
        let l:key = trim(l:matchResult[2])
        if len(l:key) == 0
            continue
        endif
        let l:matchEnd = stridx(text, l:matchResult[0]) + strlen(l:matchResult[0])
        let l:len = strlen(l:matchResult[2])
        let l:start = l:matchEnd - l:len
        if l:key =~ l:interpolate
            let l:group = "ngconsole_unknow_key"
        else
            if has_key(l:resources, l:key)
                let l:group = "ngconsole_has_key"
            else
                let l:group = "ngconsole_has_no_key"
            endif
        endif
        call add(l:newMatches, {'key': l:key, 'group': l:group, 'line': l:lineNumber, 'col': l:start, 'len': l:len, 'pk': l:lineNumber . ":" . l:start})
    endfor
    let l:matches = s:mergeMatches(l:oldMatches, l:newMatches)
    let s:highlightMatches[a:buffile] = l:matches
    if !l:shouldUpdate
        call ngconsole#highlight#bindChange()
    endif
    return v:true
endfunction

function! s:mergeMatches(old, new)
    let l:pkMap = {}
    let l:hasChanged = v:false
    for m in a:new
        let l:pkMap[m.pk] = m
    endfor
    for oldMatch in a:old
        let l:newMatch = get(l:pkMap, oldMatch.pk, v:false)
        if type(l:newMatch) == v:t_dict && oldMatch.key == l:newMatch.key
            let l:pkMap[oldMatch.pk] = oldMatch
        else
            call matchdelete(oldMatch.id)
            let l:hasChanged = v:true
        endif
    endfor
    for [k, m] in items(l:pkMap)
        if has_key(m, "id")
            continue
        endif
        let m.id = matchaddpos(m.group, [[m.line, m.col, m.len]])
        let l:hasChanged = v:true
    endfor
    return l:hasChanged ? values(l:pkMap) : a:old
endfunction

function! ngconsole#highlight#showResource(buffile)
    let l:line = line(".")
    let l:col = col(".")
    let l:text = ""
    let l:isInterpolate = v:false
    for m in get(s:highlightMatches, a:buffile, [])
        if m.line == l:line && m.col <= l:col && l:col <= (m.col + m.len - 1)
            let l:text = m.key
            let l:isInterpolate = m.group == "ngconsole_unknow_key"
            break
        endif
    endfor
    echo l:text
endfunction

function! ngconsole#highlight#bindChange()
    au! TextChanged,TextChangedI,TextChangedP <buffer> call ngconsole#highlight#renderHtml(expand("<afile>:p"), v:true)
    au! CursorMoved,CursorMovedI <buffer> call ngconsole#highlight#showResource(expand("<afile>:p"))
endfunction
