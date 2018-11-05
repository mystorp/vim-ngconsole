let s:sep = "/"
if has("win32") || has("win64")
    let s:sep = "\\"
endif

function! ngconsole#normalizeDirectory(dir)
    if len(a:dir) == 0
        return dir
    endif
    let l:dir = expand(a:dir)
    if s:sep == "\\"
        let l:dir = sustitute(l:dir, "/", "\\", "g")
    endif
    while v:true
        let l:newdir = substitute(l:dir, s:sep . s:sep, s:sep, "g")
        if l:newdir == l:dir
            break
        endif
    endwhile
    return l:newdir
endfunction

function! ngconsole#checkConfigrations()
    let l:isTypeValid = type(g:ngconsole_root) == v:t_string && type(g:ngconsole_resources_root) == v:t_string
    let l:isDir = isdirectory(g:ngconsole_root) && isdirectory(g:ngconsole_resources_root)
    return l:isTypeValid && l:isDir
endfunction

function! ngconsole#getBranch(repo)
    let l:text = readfile(join([a:repo, ".git", "HEAD"], s:sep))[0]
    return split(l:text, "/")[-1]
endfunction

function! ngconsole#readJson(file)
    let l:text = join(readfile(a:file), "")
    return json_decode(l:text)
endfunction

function! ngconsole#writeJson(file, data)
    let l:text = encode_json(a:data)
    writefile(a:file, l:text)
endfunction

function! ngconsole#joinPath(parts)
    return join(a:parts, s:sep)
endfunction
