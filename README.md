# BoxDraw

Draw pretty boxes in Vim

> This README was converted by hand from the
> [vimdoc](https://github.com/jessepav/vim-boxdraw/blob/master/doc/boxdraw.txt)
> included with the plugin. Please see that file for the definitive
> documentation.

## INSTALL

This plugin is written in `vim9script` and requires Vim v9.1 or higher.

* [`vim-plug`](https://github.com/junegunn/vim-plug)

  `Plug 'jessepav/vim-boxdraw'`

* Manual installation:

  Copy files from the `plugin`, `autoload`, and `doc` directories to your `.vim`
  directory.

## OVERVIEW

BoxDraw provides a command to draw boxes using ASCII or Unicode box-drawing
characters. It can also draw horizontal, vertical, and diagonal lines, and
select existing boxes.

*(We use images in the examples below because many fonts won't display all the
box types correctly.)*

### Box Styles

![box types image](https://raw.githubusercontent.com/jessepav/vim-boxdraw/master/images/boxtypes.png)

### Diagonal Lines

![diagonal lines image](https://raw.githubusercontent.com/jessepav/vim-boxdraw/master/images/diagonals.png)

### Line Joining

When you draw a "box" that is just a vertical or horizontal line, we
attempt to join the ends intelligently by examining the surrounding
characters:

![line joining image](https://raw.githubusercontent.com/jessepav/vim-boxdraw/master/images/line-joins.png)

## USAGE

Once the plugin is loaded, it provides one command:

```
  :BoxDraw [box-type or command] [force] [empty]
```

You make a selection in block-wise visual mode (setting `'virtualedit'` to
`block` is very useful in this regard), and then invoke `:BoxDraw` with the
desired arguments. Or you can use the [`boxdraw-mappings`](#mappings) below.

|  Argument   |   Description  |
| ----------- | -------------- |
|  box-type / command |  Either one of the named box types above (`single`, `rounded`, `double`, `ascii`, `clear`), or `IBID`, to use the same box type as last time, or a special command (`SELECTBOX`, `DIAGONAL_BACKWARD`, `DIAGONAL_FORWARD`), each of which will be described below. |
|    force    |  Use `true` or `1` to disable intelligent box joining, and just draw the type of box indicated, overwriting any existing box characters encountered. |
|    empty    |  Use `true` or `1` to replace the interior of the box with spaced, thus "emptying" it. |

### Selection

If the command provided to `BoxDraw` is `SELECTBOX`, we examine the character
under the cursor, and attempt to visually select the box that the character
belongs to. This works for stand-alone boxes, or the enclosing box of a
table, but not for table cells. It also works better for box-types other than
`ascii`, since they have different characters for each of the four corners.

### Diagonal Lines

If the command is `DIAGONAL_FORWARD` or `DIAGONAL_BACKWARD`, we draw a
diagonal line starting at the bottom-left (for `FORWARD`) or top-left (for
`BACKWARD`) corner of the visual selection, and proceed until the line reaches
a selection boundary, horizontal or vertical.


## MAPPINGS

If the global variable `g:boxdraw_skip_mappings` is unset or is `0`, then
these mappings will be provided when the plugin is loaded:

```
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

  # Normal mode selection
  nnoremap <Leader><Leader>bl <Cmd>BoxDraw SELECTBOX<CR>

  # One-key meta shortcuts
  vnoremap <M-b> <Esc><Cmd>BoxDraw<CR>
  vnoremap <M-B> <Esc><Cmd>BoxDraw IBID true<CR>
  vnoremap <M-l> <Esc><Cmd>BoxDraw SELECTBOX<CR>
  nnoremap <M-l> <Cmd>BoxDraw SELECTBOX<CR>
```


## AUTHOR

Jesse Pavel

jpavel@gmail.com\
https://github.com/jessepav/vim-boxdraw

## LICENSE

MIT
