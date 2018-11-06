let s:highlightMatches = {}

highlight ngconsole_has_key term=bold,reverse cterm=bold ctermfg=15 ctermbg=2 gui=bold guifg=bg guibg=DarkGreen
highlight ngconsole_has_no_key term=reverse cterm=reverse ctermfg=1 guifg=White guibg=Red
highlight ngconsole_unknow_key term=underline cterm=underline ctermfg=3

" TODO: 处理注释
function! ngconsole#highlight#renderHtml(buffile, ...)
    if stridx(a:buffile, g:ngconsole_root) != 0
        return v:false
    endif
    let l:resources = ngconsole#resources#getFor(a:buffile)
    if type(l:resources) != v:t_dict
        return v:false
    endif
    " 第二个参数表示是否更新，一般由 TextChanged 触发
    " 函数需要此标记以判断是否是第一次调用，如果是则
    " 绑定基于当前缓冲区的自动命令
    let l:shouldUpdate = a:0 > 0
    let l:lineNumber = 0
    let l:matches = get(s:highlightMatches, a:buffile, {})
    " 打上标记，等循环结束，仍然持有 invalid 的项需要清除
    for [k, m] in items(l:matches)
        let m.invalid = v:true
    endfor
    let l:regexp = '\%(data-\)\?localize\%(-title\|-placeholder\|-tip\)\?\s*=\s*\("\|''\)\(.\{-}\)\1'
    let l:interpolate = '{{.*}}'
    for lnum in s:getSmartRanges()
        let l:text = getline(lnum)
        let l:matchResult = matchlist(l:text, l:regexp)
        " not match
        if len(l:matchResult) == 0
            continue
        endif
        let l:key = trim(l:matchResult[2])
        if len(l:key) == 0
            continue
        endif
        let l:matchEnd = stridx(l:text, l:matchResult[0]) + strlen(l:matchResult[0])
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
        " 对每个翻译项来说，它的行列必定是唯一的
        let l:matchPK = lnum . ":" . l:start
        let l:match = get(l:matches, l:matchPK)
        if l:match is 0 " 新增
            let l:matches[l:matchPK] = {'id': matchaddpos(l:group, [[lnum, l:start, l:len]]), 'key': l:key}
        else
            if l:match.key == l:key " 没有变动
                unlet l:match.invalid
            else " 有变动：删除旧的，添加新的
                call matchdelete(l:match.id)
                let l:matches[l:matchPK] = {'id': matchaddpos(l:group, [[lnum, l:start, l:len]]), 'key': l:key}
            endif
        endif
    endfor
    let l:invalidKeys = []
    for [k,m] in items(l:matches)
        if has_key(m, "invalid")
            call add(l:invalidKeys, k)
            call matchdelete(m.id)
        endif
    endfor
    for key in l:invalidKeys
        unlet l:matches[key]
    endfor
    let s:highlightMatches[a:buffile] = l:matches
    if !l:shouldUpdate
        call ngconsole#highlight#bindChange()
    endif
    return v:true
endfunction

" 以当前行为分界线，获取如下行列表：
" [cline, cline-1, cline+1, cline-2, cline+2, ...]
" 当前窗口可见的行应当优先添加到列表，即如果 cline-N
" 当前不可见，但 cline+N 可见，则 cline+N 行优先级更高
function! s:getSmartRanges()
    let l:range = []
    let l:cline = line(".")
    let l:maxLine = line("$")
    let l:viewLineStart = l:cline - winline() + 1
    let l:viewLineEnd = min([l:viewLineStart + winheight(0) - 1, l:maxLine])
    let l:n = 1
    " 添加可见的行
    call add(l:range, l:cline)
    while (l:cline + n <= l:viewLineEnd) && (l:cline - n >= l:viewLineStart)
        call add(l:range, l:cline - n)
        call add(l:range, l:cline + n)
        let n += 1
    endwhile
    while l:cline + n <= l:viewLineEnd
        call add(l:range, l:cline + n)
        let n += 1
    endwhile
    while l:cline - n >= l:viewLineStart
        call add(l:range, l:cline - n)
        let n += 1
    endwhile
    " 合并剩余行
    return l:range + range(1, l:viewLineStart - 1) + range(l:viewLineEnd + 1, l:maxLine)
endfunction

function! ngconsole#highlight#showResource(buffile)
    let l:matches = get(s:highlightMatches, a:buffile, {})
    let l:col = col(".")
    let l:prefix = line(".") . ":"
    let l:text = ""
    let l:isInterpolate = v:false
    for pk in filter(keys(l:matches), 'stridx(v:val, l:prefix) == 0')
        let l:mcol = str2nr(substitute(pk, l:prefix, "", ""))
        let l:keystr = l:matches[pk].key
        if l:mcol <= l:col && l:col <= (l:mcol + strlen(l:keystr) - 1)
            let l:text = l:keystr
        endif
    endfor
    if len(l:text) > 0
        let l:resources = ngconsole#resources#getFor(a:buffile)
        let l:text = get(l:resources, l:text, "")
    endif
    echo l:text
endfunction

function! ngconsole#highlight#bindChange()
    au! TextChanged,TextChangedI,TextChangedP <buffer> call ngconsole#highlight#renderHtml(expand("<afile>:p"), v:true)
    au! CursorMoved,CursorMovedI <buffer> call ngconsole#highlight#showResource(expand("<afile>:p"))
endfunction
