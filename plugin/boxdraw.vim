vim9script

# A plugin to draw boxes, tables, etc.

final boxdraw_mod: dict<func> = {}

if exists("g:module_export")
  g:module_export->filter('0')
  source <script>:p:h/../autoload/boxdraw.vim
  boxdraw_mod->filter('0')
  boxdraw_mod->extend({
    BoxDraw: g:module_export.BoxDraw
  })
  command! -nargs=* BoxDraw boxdraw_mod.BoxDraw(<f-args>)
else
  import autoload "../autoload/boxdraw.vim"
  command! -nargs=* BoxDraw boxdraw.BoxDraw(<f-args>)
endif

# Not-forced not-emptied boxes
vnoremap <Leader>bs <Esc><Cmd>BoxDraw single<CR>
vnoremap <Leader>bd <Esc><Cmd>BoxDraw double<CR>
vnoremap <Leader>br <Esc><Cmd>BoxDraw rounded<CR>
vnoremap <Leader>ba <Esc><Cmd>BoxDraw ascii<CR>
vnoremap <Leader>bc <Esc><Cmd>BoxDraw clear<CR>
vnoremap <Leader>bb <Esc><Cmd>BoxDraw<CR>
vnoremap <M-b>      <Esc><Cmd>BoxDraw<CR>

# Not-forced emptied boxes
vnoremap <Leader>bes <Esc><Cmd>BoxDraw single false true<CR>
vnoremap <Leader>bed <Esc><Cmd>BoxDraw double false true<CR>
vnoremap <Leader>ber <Esc><Cmd>BoxDraw rounded false true<CR>
vnoremap <Leader>bea <Esc><Cmd>BoxDraw ascii false true<CR>
vnoremap <Leader>bec <Esc><Cmd>BoxDraw clear false true<CR>

# Forced not-emptied boxes
vnoremap <Leader>BS <Esc><Cmd>BoxDraw single true<CR>
vnoremap <Leader>BD <Esc><Cmd>BoxDraw double true<CR>
vnoremap <Leader>BR <Esc><Cmd>BoxDraw rounded true<CR>
vnoremap <Leader>BA <Esc><Cmd>BoxDraw ascii true<CR>
vnoremap <Leader>BC <Esc><Cmd>BoxDraw clear true<CR>
vnoremap <Leader>BB <Esc><Cmd>BoxDraw IBID true<CR>
vnoremap <M-B>      <Esc><Cmd>BoxDraw IBID true<CR>

# Forced emptied boxes
vnoremap <Leader>BES <Esc><Cmd>BoxDraw single true true<CR>
vnoremap <Leader>BED <Esc><Cmd>BoxDraw double true true<CR>
vnoremap <Leader>BER <Esc><Cmd>BoxDraw rounded true true<CR>
vnoremap <Leader>BEA <Esc><Cmd>BoxDraw ascii true true<CR>
vnoremap <Leader>BEC <Esc><Cmd>BoxDraw clear true true<CR>
