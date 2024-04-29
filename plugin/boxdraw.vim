vim9script

# A plugin to draw boxes, tables, etc.

const devmode = exists("g:module_export")

final boxdraw_mod: dict<func> = {}

if devmode
  g:module_export->filter('0')
  source <script>:p:h/../autoload/boxdraw.vim
  boxdraw_mod->filter('0')
  boxdraw_mod->extend({
    BoxDraw: g:module_export.BoxDraw,
  })
  command! -nargs=* BoxDraw boxdraw_mod.BoxDraw(<f-args>)
  echo "autoload/boxdraw.vim reloaded"
else
  import autoload "../autoload/boxdraw.vim"
  command! -nargs=* BoxDraw boxdraw.BoxDraw(<f-args>)
endif

if get(g:, "boxdraw_skip_mappings") == 0
  if mapcheck("<Leader>b", "v")->empty() || devmode
    # Not-forced not-emptied boxes
    vnoremap <Leader>bs <Esc><Cmd>BoxDraw single<CR>
    vnoremap <Leader>bd <Esc><Cmd>BoxDraw double<CR>
    vnoremap <Leader>br <Esc><Cmd>BoxDraw rounded<CR>
    vnoremap <Leader>ba <Esc><Cmd>BoxDraw ascii<CR>
    vnoremap <Leader>bc <Esc><Cmd>BoxDraw clear<CR>
    vnoremap <Leader>bb <Esc><Cmd>BoxDraw<CR>

    # Not-forced emptied boxes
    vnoremap <Leader>bes <Esc><Cmd>BoxDraw single false true<CR>
    vnoremap <Leader>bed <Esc><Cmd>BoxDraw double false true<CR>
    vnoremap <Leader>ber <Esc><Cmd>BoxDraw rounded false true<CR>
    vnoremap <Leader>bea <Esc><Cmd>BoxDraw ascii false true<CR>
    vnoremap <Leader>bec <Esc><Cmd>BoxDraw clear false true<CR>

    # Diagonals (always 'single' style)
    vnoremap <Leader>b/ <Esc><Cmd>BoxDraw DIAGONAL_FORWARD<CR>
    vnoremap <Leader>b\ <Esc><Cmd>BoxDraw DIAGONAL_BACKWARD<CR>

    # Selection
    vnoremap <Leader>bl <Esc><Cmd>BoxDraw SELECTBOX<CR>
  endif

  if mapcheck("<Leader>B", "v")->empty() || devmode
    # Forced not-emptied boxes
    vnoremap <Leader>BS <Esc><Cmd>BoxDraw single true<CR>
    vnoremap <Leader>BD <Esc><Cmd>BoxDraw double true<CR>
    vnoremap <Leader>BR <Esc><Cmd>BoxDraw rounded true<CR>
    vnoremap <Leader>BA <Esc><Cmd>BoxDraw ascii true<CR>
    vnoremap <Leader>BC <Esc><Cmd>BoxDraw clear true<CR>
    vnoremap <Leader>BB <Esc><Cmd>BoxDraw IBID true<CR>

    # Forced emptied boxes
    vnoremap <Leader>BES <Esc><Cmd>BoxDraw single true true<CR>
    vnoremap <Leader>BED <Esc><Cmd>BoxDraw double true true<CR>
    vnoremap <Leader>BER <Esc><Cmd>BoxDraw rounded true true<CR>
    vnoremap <Leader>BEA <Esc><Cmd>BoxDraw ascii true true<CR>
    vnoremap <Leader>BEC <Esc><Cmd>BoxDraw clear true true<CR>
  endif

  # Normal mode selection
  if mapcheck("<Leader><Leader>bl", "n")->empty() || devmode
    nnoremap <Leader><Leader>bl <Cmd>BoxDraw SELECTBOX<CR>
  endif

  # One-key meta shortcuts
  if mapcheck("<M-b>", "v")->empty() || devmode
    vnoremap <M-b> <Esc><Cmd>BoxDraw<CR>
  endif
  if mapcheck("<M-B>", "v")->empty() || devmode
    vnoremap <M-B> <Esc><Cmd>BoxDraw IBID true<CR>
  endif
  if mapcheck("<M-l>", "v")->empty() || devmode
    vnoremap <M-l> <Esc><Cmd>BoxDraw SELECTBOX<CR>
  endif
  if mapcheck("<M-l>", "n")->empty() || devmode
    nnoremap <M-l> <Cmd>BoxDraw SELECTBOX<CR>
  endif

endif  # boxdraw_skip_mappings
