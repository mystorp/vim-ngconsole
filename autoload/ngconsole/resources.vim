let s:resources = {} " 资源名 => 资源对象
let s:buffers = {} " 缓冲区名 => 资源名

" 加载缓冲区对应的**资源对象**
function! ngconsole#resources#loadFor(buffile)
    if stridx(a:buffile, g:ngconsole_root) != 0
        return v:false
    endif
    let l:branch = ngconsole#getBranch(g:ngconsole_root)
    let l:branch2 = ngconsole#getBranch(g:ngconsole_resources_root)
    if l:branch !~ l:branch2
        echoerr "ngconsole[" . l:branch . "] not match ngconsole_resources[" . l:branch2 . "]"
        return v:false
    endif
    let l:parts = split(l:branch, "-")
    let l:version = ""
    if len(l:parts) == 2 && l:parts[-1] == "dev"
        let l:version = "e-vdi"
    endif
    if len(l:parts) == 3 && l:parts[1] == "OEM"
        let l:version = l:parts[-1]
    endif
    if strlen(l:version) == 0
        echoerr "read version error!"
        return v:false
    endif
    let l:resourceFile = ngconsole#joinPath([g:ngconsole_resources_root, "resources", "pkg", l:version, "lang.json"])
    if has_key(s:resources, l:resourceFile)
        let l:resourceData = s:resources[l:resourceFile]
    else
        let l:resourceData = ngconsole#readJson(l:resourceFile)
        let s:resources[l:resourceFile] = l:resourceData
    endif
    let s:buffers[a:buffile] = l:resourceFile
    return l:resourceData
endfunction

" 移除缓冲区对应的**资源对象**
function! ngconsole#resources#removeFor(buffile)
    if !has_key(s:buffers, a:buffile)
        return
    endif
    let l:resourceFile = s:buffers[a:buffile]
    unlet s:buffers[a:buffile]
    let l:count = 0
    for [key, val] in items(s:resources)
        if key == l:resourceFile
            let l:count += 1
        endif
    endfor
    if l:count == 0
        unlet s:resources[l:resourceFile]
    endif
endfunction

" 获取缓冲区对应的**资源对象**
function! ngconsole#resources#getFor(buffile)
    if !has_key(s:buffers, a:buffile)
        return v:false
    endif
    let l:resourceFile = s:buffers[a:buffile]
    return s:resources[l:resourceFile]
endfunction
