if exists("s:loaded")
    finish
endif
let s:loaded = 1


let g:ngconsole_root = ngconsole#normalizeDirectory(get(g:, "ngconsole_root", ""))
let g:ngconsole_resources_root = ngconsole#normalizeDirectory(get(g:, "ngconsole_resources_root", ""))

if !ngconsole#checkConfigrations()
    finish
endif

" 读取 ngconsole 仓库中的 html 时缓存对应的 resources
au! BufRead *.html call ngconsole#resources#loadFor(expand("<afile>:p"))
" 高亮不存在的 localize-*="xx" 翻译
au! BufEnter *.html call ngconsole#highlight#renderHtml(expand("<afile>:p"))
" 缓冲区移除时，清理之前缓存的 resources
au! BufDelete *.html call ngconsole#resources#removeFor(expand("<afile>:p"))
" 为项目中基础代码的 API 提供 complete 支持，包括 angular 等 typescript
" 无法提供代码完成的一些 API 
au! BufRead *.js call ngconsole#complete#autoComplete(expand("<afile>:p"))
