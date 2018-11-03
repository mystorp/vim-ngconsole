" if exists("s:loaded")
"     finish
" endif
" let s:loaded = 1
" 
let s:sep = "/"
if has("win32") || has("win64")
    let s:sep = "\\"
endif
function! s:normalizeDirectory(dir)
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

let s:ngconsole_root = s:normalizeDirectory(get(g:, "ngconsole_root", ""))
let s:ngconsole_resources_root = s:normalizeDirectory(get(g:, "ngconsole_resources_root", ""))

function! s:checkConfigrations()
    let l:isTypeValid = type(s:ngconsole_root) == v:t_string && type(s:ngconsole_resources_root) == v:t_string
    let l:isDir = isdirectory(s:ngconsole_root) && isdirectory(s:ngconsole_resources_root)
    return l:isTypeValid && l:isDir
endfunction

function! s:getBranch(repo)
    let l:text = readfile(join([a:repo, ".git", "HEAD"], s:sep))[0]
    return split(l:text, "/")[-1]
endfunction

function! s:readJson(file)
    let l:text = join(readfile(a:file), "")
    return json_decode(l:text)
endfunction

function! s:writeJson(file, data)
    let l:text = encode_json(a:data)
    writefile(a:file, l:text)
endfunction

if exists("s:highlightCache")
    unlet s:highlightCache
endif
" {resources: {file: data}, buffers: {file: resourceFile}}
let s:highlightCache = {'resources': {}, 'buffers': {}}

function! s:highlightCache.onBufRead(file)
    if stridx(a:file, s:ngconsole_root) != 0
        return
    endif
    let l:branch = s:getBranch(s:ngconsole_root)
    let l:branch2 = s:getBranch(s:ngconsole_resources_root)
    if l:branch !~ l:branch2
        echoerr "ngconsole[" . l:branch . "] not match ngconsole[" . l:branch2 . "]"
        return
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
    endif
    let l:resourceFile = join([s:ngconsole_resources_root, "resources", "pkg", l:version, "lang.json"], s:sep)
    let l:resourceData = s:readJson(l:resourceFile)
    let self.resources[l:resourceFile] = l:resourceData
    let self.buffers[a:file] = l:resourceFile
endfunction

function! s:highlightCache.onBufDelete(file)
    if !has_key(self.buffers, a:file)
        return
    endif
    let l:resourceFile = self.buffers[a:file]
    unlet self.buffers[a:file]
    unlet self.matches[a:file]
    let l:count = 0
    for [key, val] in items(self.buffers)
        if val == l:resourceFile
            let l:count += 1
        endif
    endfor
    if l:count == 0
        unlet self.resources[l:resourceFile]
    endif
endfunction

function! s:highlightCache.getResource(file)
    if !has_key(self.buffers, a:file)
        return v:false
    endif
    let l:resourceFile = self.buffers[a:file]
    return self.resources[l:resourceFile]
endfunction
" only highlight actived buffer
" when active buffer change, do highlight
function! s:highlightHtml(file)
    if stridx(a:file, s:ngconsole_root) != 0
        return
    endif
    let l:resources = s:highlightCache.getResource(a:file)
    if type(l:resources) != v:t_dict
        return
    endif
    let l:lineNumber = 0
    let l:matches = filter(getmatches(), "v:val.group == 'Visual'")
    filter(l:matches, 'matchdelete(v:val)')
    let l:regexp = '\%(data-\)\?localize\%(-title\|-placeholder\|-tip\)\?\s*=\s*\("\|''\)\(.\+\)\1'
    let l:interpolate = '{{.*}}'
    for text in getline(1, line("$"))
        let l:lineNumber += 1
        let l:matchResult = matchlist(text, l:regexp)
        " not match
        if len(l:matchResult) == 0
            continue
        endif
        let l:key = trim(l:matchResult[2])
        if len(l:key) == 0 || l:key =~ l:interpolate
            continue
        endif
        let l:matchEnd = stridx(text, l:matchResult[0]) + strlen(l:matchResult[0])
        let l:len = strlen(l:matchResult[2])
        let l:start = l:matchEnd - l:len
        if has_key(l:resources, l:key)
            call matchaddpos("Visual", [[l:lineNumber, l:start, l:len]])
        endif
    endfor
endfunction

" 根据 highlight 产生的列表及当前变更列表进行更新
function! s:updateHighlight(file)
endfunction

if s:checkConfigrations()
    au! BufRead *.html call s:highlightCache.onBufRead(expand("<afile>:p"))
    au! BufEnter *.html call s:highlightHtml(expand("<afile>:p"))
    au! TextChanged *.html call s:updateHighlight(expand("<afile>:p"))
    au! BufDelete *.html call s:highlightCache.onBufDelete(expand("<afile>:p"))
endif
