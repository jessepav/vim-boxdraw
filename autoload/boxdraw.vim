vim9script

# These are some characters I might use to special-case joins in the future
# ╒ ╓ ╕ ╖ ╘ ╙ ╛ ╜ ╞ ╟ ╡ ╢ ╤ ╥ ╧ ╨ ╪ ╫

const singleBox =<< trim EOF
    ┌─┬─┐
    │ │ │
    ├─┼─┤
    │ │ │
    └─┴─┘
EOF

const roundedBox =<< trim EOF
    ╭─┬─╮
    │ │ │
    ├─┼─┤
    │ │ │
    ╰─┴─╯
EOF

const doubleBox =<< trim EOF
    ╔═╦═╗
    ║ ║ ║
    ╠═╬═╣
    ║ ║ ║
    ╚═╩═╝
EOF

const asciiBox =<< trim EOF
    +-+-+
    | | |
    +-+-+
    | | |
    +-+-+
EOF

# Used for erasing boxes
const clearBox = mapnew(singleBox, (_, v) => repeat(' ', strcharlen(v)))

# Index and map of box types
final boxes = [singleBox, doubleBox, roundedBox, asciiBox, clearBox]
final boxtypes = { 'single': 0, 'double': 1, 'rounded': 2, 'ascii': 3, 'clear': 4 }

# Keys by which we refer to our box-drawing characters
const NUMKEYS = 11
const [ HORZ,
      \ VERT,
      \ UL,
      \ UR,
      \ LL,
      \ LR,
      \ HORZDOWN,
      \ HORZUP,
      \ VERTRIGHT,
      \ VERTLEFT,
      \ HORZVERT ] = range(NUMKEYS)

# Indices to get the various box-drawing characters (ordered by key)
const BOXCHAR_INDICES = [
  [0, 1], [1, 0],                  # HORZ, VERT
  [0, 0], [0, 4], [4, 0], [4, 4],  # UL, UR, LL, LR
  [0, 2], [4, 2], [2, 0], [2, 4],  # HORZDOWN, HORZUP, VERTRIGHT, VERTLEFT
  [2, 2]                           # HORZVERT
]

# Each character cell is defined by the presence or absence of four component lines,
# corresponding to the four points of a center piece (plus sign). By doing a
# bitwise-or of the two box pieces we're combining, we get the resulting piece.

const TOP_MASK    = 0x01
const BOTTOM_MASK = 0x02
const LEFT_MASK   = 0x04
const RIGHT_MASK  = 0x08

# dict of bitmask -> corresponding type key
final maskKeyMap: dict<number> = {
  [BOTTOM_MASK + RIGHT_MASK]: UL,
  [LEFT_MASK + RIGHT_MASK]: HORZ,
  [LEFT_MASK + BOTTOM_MASK]: UR,
  [TOP_MASK + BOTTOM_MASK]: VERT,
  [TOP_MASK + RIGHT_MASK]: LL,
  [TOP_MASK + LEFT_MASK]: LR,
  [LEFT_MASK + RIGHT_MASK + BOTTOM_MASK]: HORZDOWN,
  [TOP_MASK + BOTTOM_MASK + RIGHT_MASK]: VERTRIGHT,
  [TOP_MASK + BOTTOM_MASK + LEFT_MASK]: VERTLEFT,
  [LEFT_MASK + RIGHT_MASK + TOP_MASK]: HORZUP,
  [LEFT_MASK + RIGHT_MASK + TOP_MASK + BOTTOM_MASK]: HORZVERT
}

# dict of type key -> bitmask
final keyMaskMap: dict<number> = {}
for [maskval, boxkey] in maskKeyMap->items()
  keyMaskMap[boxkey] = str2nr(maskval)
endfor

final keyCharMaps: list<dict<string>> = []   # dicts of key -> char for each box type
final charKeyMaps: list<dict<number>> = []   # dicts of char -> key for each box type
final charMaskMaps: list<dict<number>> = []  # dicts of char -> bitmask value for each box type

# current box type, used as an index into our boxes and maps lists
var curboxtype = 0

# We can force the overwrite of old characters when drawing
var force: bool = false

# I keep this as a function in case I support dynamically adding boxtypes in the future.
def GenMaps()
  for box in boxes
    final keyCharMap: dict<string> = {}
    final charKeyMap: dict<number> = {}
    final charMaskMap: dict<number> = {}
    for boxkey in range(NUMKEYS)
      const idx = BOXCHAR_INDICES[boxkey]
      const char = box[idx[0]][idx[1]]
      keyCharMap[boxkey] = char
      charKeyMap[char] = boxkey
      charMaskMap[char] = keyMaskMap[boxkey]
    endfor
    keyCharMaps->add(keyCharMap)
    charKeyMaps->add(charKeyMap)
    charMaskMaps->add(charMaskMap)
  endfor
enddef

GenMaps()

var HORZ_CHARS: string = ""
var VERT_CHARS: string = ""
var CORNER_CHARS: string = ""

for boxnum in range(boxtypes['ascii'] + 1)
  const charMap = keyCharMaps[boxnum]
  HORZ_CHARS ..= charMap[HORZ]
  VERT_CHARS ..= charMap[VERT]
  CORNER_CHARS ..= charMap[UL] .. charMap[UR] .. charMap[LL] .. charMap[LR]
endfor
CORNER_CHARS = CORNER_CHARS->substitute('\v(.)\1+', '\1', 'g')  # Remove duplicates

# CharValAt() sometimes needs to look beyond the bounds of our visually selected area,
# so we store the lines above and below the region in these variables.
var charlineabove: list<string>
var charlinebelow: list<string>

def CombineChars(c: string, oldchar: string): string
  if force
    return c
  endif
  const cmask = charMaskMaps[curboxtype]->get(c, -1)
  const oldcharmask = charMaskMaps[curboxtype]->get(oldchar, -1)
  if cmask == -1
    return oldchar
  elseif oldcharmask == -1
    return c
  else
    return keyCharMaps[curboxtype][maskKeyMap[or(cmask, oldcharmask)]]
  endif
enddef

# Return the key-type or mask of the character at (lnum,col) in charlists, or an
# errorVal (-1 or 0, see below) if (lnum,col) are invalid or if the character has no
# defined key-type or mask.  lnum and col are both 0-indexed
#
# If mask is true, we return the bitmask of the character, otherwise the key-type.
# errorVal is 0 when mask is true, and -1 when mask is false.
#
# CharValAt() is only called from the Draw{Horz,Vert}Line() functions, and so
# we know that lnum will never be out of the range [-1, len(charlists)].

def CharValAt(charlists: list<list<string>>, lnum: number, col: number, mask: bool): number
  # Since mask values are used as bitmaps, we return 0; but since 0 is a valid
  # value of a key-type, we return -1 in that case.
  const errorVal = mask ? 0 : -1
  const line = lnum == -1 ? charlineabove :
               lnum == len(charlists) ? charlinebelow :
               charlists[lnum]
  if col < 0 || col >= len(line)
    return errorVal
  else
    return mask ? charMaskMaps[curboxtype]->get(line[col], errorVal)
                : charKeyMaps[curboxtype]->get(line[col], errorVal)
  endif
enddef

# Note that for the below functions, lnum and col are 1-indexed, as in Vim

def DrawChar(charlists: list<list<string>>, c: string, lnum: number, col: number)
  charlists[lnum - 1][col - 1] = CombineChars(c, charlists[lnum - 1][col - 1])
enddef

def DrawHorzLine(charlists: list<list<string>>, boxchars: dict<string>,
                 lnum_: number, col1_: number, col2_: number, checkends: bool = false)
  const lnum = lnum_ - 1   # change vars to 0-index
  var [col1, col2] = [col1_ - 1, col2_ - 1]
  if checkends
    # There are special cases for combining a horizontal segment with a
    # vertical segment at the ends of the line.
    if CharValAt(charlists, lnum, col1, false) == VERT
      var ctype: number
      var cabovemask = CharValAt(charlists, lnum - 1, col1, true)
      var cbelowmask = CharValAt(charlists, lnum + 1, col1, true)
      if and(cabovemask, BOTTOM_MASK) == BOTTOM_MASK && and(cbelowmask, TOP_MASK) == 0
        ctype = maskKeyMap[TOP_MASK + RIGHT_MASK]
      elseif and(cabovemask, BOTTOM_MASK) == 0 && and(cbelowmask, TOP_MASK) == TOP_MASK
        ctype = maskKeyMap[BOTTOM_MASK + RIGHT_MASK]
      else
        ctype = maskKeyMap[TOP_MASK + BOTTOM_MASK + RIGHT_MASK]
      endif
      charlists[lnum][col1] = keyCharMaps[curboxtype][ctype]
      col1 += 1
    endif
    if CharValAt(charlists, lnum, col2, false) == VERT
      var ctype: number
      var cabovemask = CharValAt(charlists, lnum - 1, col2, true)
      var cbelowmask = CharValAt(charlists, lnum + 1, col2, true)
      if and(cabovemask, BOTTOM_MASK) == BOTTOM_MASK && and(cbelowmask, TOP_MASK) == 0
        ctype = maskKeyMap[TOP_MASK + LEFT_MASK]
      elseif and(cabovemask, BOTTOM_MASK) == 0 && and(cbelowmask, TOP_MASK) == TOP_MASK
        ctype = maskKeyMap[BOTTOM_MASK + LEFT_MASK]
      else
        ctype = maskKeyMap[TOP_MASK + BOTTOM_MASK + LEFT_MASK]
      endif
      charlists[lnum][col2] = keyCharMaps[curboxtype][ctype]
      col2 -= 1
    endif
  endif
  var col = col1
  while col <= col2
    charlists[lnum][col] = CombineChars(boxchars[HORZ], charlists[lnum][col])
    col += 1
  endwhile
enddef

def DrawVertLine(charlists: list<list<string>>, boxchars: dict<string>,
                 col_: number, lnum1_: number, lnum2_: number, checkends: bool = false)
  const col = col_ - 1   # change vars to 0-index
  var [lnum1, lnum2] = [lnum1_ - 1, lnum2_ - 1]
  if checkends
    # And here are the special cases for combining a vertical segment with a
    # horizontal segment at the ends of the line.
    if CharValAt(charlists, lnum1, col, false) == HORZ
      var ctype: number
      var cleftmask = CharValAt(charlists, lnum1, col - 1, true)
      var crightmask = CharValAt(charlists, lnum1, col + 1, true)
      if and(cleftmask, RIGHT_MASK) == RIGHT_MASK && and(crightmask, LEFT_MASK) == 0
        ctype = maskKeyMap[LEFT_MASK + BOTTOM_MASK]
      elseif and(cleftmask, RIGHT_MASK) == 0 && and(crightmask, LEFT_MASK) == LEFT_MASK
        ctype = maskKeyMap[RIGHT_MASK + BOTTOM_MASK]
      else
        ctype = maskKeyMap[LEFT_MASK + RIGHT_MASK + BOTTOM_MASK]
      endif
      charlists[lnum1][col] = keyCharMaps[curboxtype][ctype]
      lnum1 += 1
    endif
    if CharValAt(charlists, lnum2, col, false) == HORZ
      var ctype: number
      var cleftmask = CharValAt(charlists, lnum2, col - 1, true)
      var crightmask = CharValAt(charlists, lnum2, col + 1, true)
      if and(cleftmask, RIGHT_MASK) == RIGHT_MASK && and(crightmask, LEFT_MASK) == 0
        ctype = maskKeyMap[LEFT_MASK + TOP_MASK]
      elseif and(cleftmask, RIGHT_MASK) == 0 && and(crightmask, LEFT_MASK) == LEFT_MASK
        ctype = maskKeyMap[RIGHT_MASK + TOP_MASK]
      else
        ctype = maskKeyMap[LEFT_MASK + RIGHT_MASK + TOP_MASK]
      endif
      charlists[lnum2][col] = keyCharMaps[curboxtype][ctype]
      lnum2 -= 1
    endif
  endif
  var lnum = lnum1
  while lnum <= lnum2
    charlists[lnum][col] = CombineChars(boxchars[VERT], charlists[lnum][col])
    lnum += 1
  endwhile
enddef

# The type is one of the values in the boxtypes dict ('single', 'rounded', etc.)
#   or 'IBID' to keep the current box type, or 'SELECTBOX' to invoke SelectBox(),
#   or 'DIAGONAL_FORWARD' or 'DIAGONAL_BACKWARD' to draw a diagonal line.
# If force_ is '1' or 'true', we don't combine characters - just draw the box
# If empty_ is '1' or 'true', we clear out the inside of the box with spaces

export def BoxDraw(type: string = '', force_: string = '', empty_: string = '')
  if type == 'SELECTBOX'
    SelectBox()
    return
  elseif type == 'DIAGONAL_FORWARD'
    DrawDiagonal(true)
    return
  elseif type == 'DIAGONAL_BACKWARD'
    DrawDiagonal(false)
    return
  endif
  var prevboxtype = curboxtype
  if !type->empty() && type != 'IBID'
    const bt = boxtypes->get(type, -1)
    if bt == -1
      echo $"I don't know the box type '{type}'"
      return
    endif
    curboxtype = bt
  endif
  if visualmode() != "\<C-V>" && visualmode() != "v"
    echo "You must invoke this command from character-wise or block-wise Visual mode"
    return
  endif
  force = force_ == '1' || force_ == 'true'
  const emptyBox = empty_ == '1' || empty_ == 'true'
  const cursorpos = getcursorcharpos()
  const [_bufnum1, _lnum1, _col1, _off1] = getcharpos("'<")
  const [_bufnum2, _lnum2, _col2, _off2] = getcharpos("'>")
  var lnum1: number
  var lnum2: number
  var col1: number
  var col2: number
  if _lnum1 < _lnum2
    lnum1 = _lnum1
    lnum2 = _lnum2
  else
    lnum1 = _lnum2
    lnum2 = _lnum1
  endif
  if _col1 + _off1 < _col2 + _off2
    col1 = _col1 + _off1
    col2 = _col2 + _off2
  else
    col1 = _col2 + _off2
    col2 = _col1 + _off1
  endif
  final lines = getline(lnum1, lnum2)
  const numlines = len(lines)
  # Ensure that all the lines are long enough to hold the box
  for i in range(numlines)
    if strcharlen(lines[i]) < col2
      lines[i] ..= repeat(' ', col2 - strcharlen(lines[i]))
    endif
  endfor

  # Now we'll draw the box like...a champ!

  # Acquire the characters:
  final boxchars: dict<string> = {}
  for key in range(LR + 1)
    boxchars[key] = keyCharMaps[curboxtype][key]
  endfor

  # Convert the text lines into lists of characters
  final charlists: list<list<string>> = []
  for line in lines
    charlists->add(split(line, '\zs'))
  endfor
  # And our special charlists
  charlineabove = split(getline(lnum1 - 1), '\zs')
  charlinebelow = split(getline(lnum1 + 1), '\zs')

  # Draw the lines as needed
  if lnum1 == lnum2
    DrawHorzLine(charlists, boxchars, 1, col1, col2, !force)
  elseif col1 == col2
    DrawVertLine(charlists, boxchars, col1, 1, numlines, !force)
  else
    DrawChar(charlists, boxchars[UL], 1, col1)
    DrawChar(charlists, boxchars[UR], 1, col2)
    DrawChar(charlists, boxchars[LL], numlines, col1)
    DrawChar(charlists, boxchars[LR], numlines, col2)
    DrawHorzLine(charlists, boxchars, 1, col1 + 1, col2 - 1)
    DrawHorzLine(charlists, boxchars, numlines, col1 + 1, col2 - 1)
    DrawVertLine(charlists, boxchars, col1, 2, numlines - 1)
    DrawVertLine(charlists, boxchars, col2, 2, numlines - 1)
    if emptyBox
      for line in range(1, numlines - 2)
        for col in range(col1 + 1, col2 - 1)
          charlists[line][col - 1] = ' '
        endfor
      endfor
    endif
  endif

  # Now we'll join the lists back into strings and modify the buffer
  for i in range(numlines)
    setline(lnum1 + i, charlists[i]->join(''))
  endfor
  # Any virtualedit offsets have become real columns
  setcharpos('.', [cursorpos[0], cursorpos[1], cursorpos[2] + cursorpos[3], 0, cursorpos[4]])
  setcharpos("'<", [_bufnum1, _lnum1, _col1 + _off1, 0])
  setcharpos("'>", [_bufnum2, _lnum2, _col2 + _off2, 0])
  # Don't remember 'clear' as the current box type
  if type == 'clear'
    curboxtype = prevboxtype
  endif
enddef

def SelectBox()
  var saved_wrapscan = &wrapscan
  try
    set nowrapscan
    SelectBoxImpl()
  catch
    if mode() == "\<C-v>" | exe "normal! \<Esc>" | endif
    echo "I couldn't find a clear box at the cursor position."
  finally
    &wrapscan = saved_wrapscan
  endtry
enddef

def SelectBoxImpl()
  var saved_wrapscan = &wrapscan
  var curchar = getline('.')[charcol('.') - 1]
  if HORZ_CHARS->stridx(curchar) != -1
    exe $"normal! ?\\V\\[{CORNER_CHARS}]\<CR>"
    curchar = getline('.')[charcol('.') - 1]
  elseif VERT_CHARS->stridx(curchar) != -1
    exe $"normal! ?\\V\\%.v\\[{CORNER_CHARS}]\<CR>"
    curchar = getline('.')[charcol('.') - 1]
  endif
  var boxtype: number = -1
  var charkey: number = -1
  for boxnum in range(len(boxes))
    for key in [UL, UR, LL, LR]
      if keyCharMaps[boxnum][key] == curchar
        charkey = key
        boxtype = boxnum
        break
      endif
    endfor
  endfor
  if boxtype == -1
    echo $"I didn't recognize '{curchar}' as one of the corners or straight beams of any boxtype"
    return
  endif
  const charMap = keyCharMaps[boxtype]
  exe "normal! \<C-V>"
  if charkey == UL
    exe $"normal! f{charMap[UR]}"
    exe $"keepjumps normal /\\%.v{charMap[LR]}\<CR>"
  elseif charkey == UR
    exe $"normal! F{charMap[UL]}"
    exe $"keepjumps normal /\\%.v{charMap[LL]}\<CR>"
  elseif charkey == LL
    exe $"normal! f{charMap[LR]}"
    exe $"keepjumps normal ?\\%.v{charMap[UR]}\<CR>"
  elseif charkey == LR
    exe $"normal! F{charMap[LL]}"
    exe $"keepjumps normal ?\\%.v{charMap[UL]}\<CR>"
  endif
  normal! o
enddef

def DrawDiagonal(forward: bool)
  if visualmode() != "\<C-V>"
    echo "You must invoke this command from block-wise Visual mode"
    return
  endif
  # Now I know about getregion() so this is much simpler than in BoxDraw()...
  const [pos1, pos2] = [getpos("'<"), getpos("'>")]
  const region = getregion(pos1, pos2, { type: "\<C-V>" })
  const numlines = len(region)
  if numlines == 0 | return | endif
  const numcols = strcharlen(region[0])
  const numchars = min([numlines, numcols])

  final charlists: list<list<string>> = []
  for line in region
    charlists->add(split(line, '\zs'))
  endfor

  var col = 0
  var line = forward ? numlines - 1 : 0
  var i = 0
  while i < numchars
    charlists[line][col] = forward ? '╱' : '╲'
    col += 1
    line += forward ? -1 : 1
    i += 1
  endwhile

  const savedreg = getreg('d')
  setreg('d', charlists->mapnew((_, v) => v->join('')), "b")
  normal gv"dp
  setreg('d', savedreg)
enddef

if exists("g:module_export")
  defcompile
  g:module_export->extend({
    BoxDraw: BoxDraw,
  })
endif

# vim: set tw=85 :
