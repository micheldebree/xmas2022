au FileType asm set ft=kickass
" au FileType asm hi def link kickAssMnemonic Error
" au FileType asm syn match kickAssConstant "\<[A-Z]\{3}2\?_\(IMM\|I\?ZP[XY]\?\|ABS[XY]\?\|IND\|REL\)\>"
set makeprg=make\ %<.prg
noremap <F6> :wa<CR>:silent! make %<.run<bar>copen<CR>:redraw!<CR>
noremap <S-F6> :wa<CR>:silent! make clean %<.prg <bar> vertical botright copen 80<CR>:redraw!<CR>
noremap <F7> :wa<CR>:make %<.debug<bar> cwindow<CR>:redraw!<CR>
noremap <F8> :wa<CR>:make %<.exe.prg<bar> cwindow<CR>:redraw!<CR>
noremap <F9> O.break<ESC>
noremap <F12> :!open http://www.theweb.dk/KickAssembler/webhelp/content/cpt_Introduction.html<CR>
set errorformat=%EError:\ %m,%Cat\ line\ %l\\,\ column\ %c\ in\ %f,%Z
set autoindent
set shiftwidth=2
set tabstop=2
set softtabstop=2
set smartindent
set expandtab
set foldmethod=marker
set foldlevel=0
set foldcolumn=3
set autochdir
au FileType asm set commentstring=//%s
" au BufWinLeave *.asm mkview
" au BufWinEnter *.asm silent! loadview
