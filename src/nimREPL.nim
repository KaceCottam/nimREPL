import simple_parseopt, illwill
import times, os, osproc, strutils, sequtils, sugar, times, strformat

const
  nimREPL_version = "0.1.0"

proc writeWithHighlight(tb: var TerminalBuffer, text: string) =
  const syntaxHighlight =
    # procedure declarations
    [ ("proc", fgYellow)
    , ("func", fgYellow)
    , ("template", fgYellow)
    , ("macro", fgYellow)
    , ("type", fgYellow)
    # data declarations
    , ("const", fgRed)
    , ("let", fgRed)
    , ("var", fgRed)
    , ("of", fgRed)
    # scope declarations
    , ("when", fgCyan)
    , ("block", fgCyan)
    , ("do", fgRed)
    , ("if", fgRed)
    , ("for", fgRed)
    , ("while", fgRed)
    , ("in", fgRed)
    # base types
    , ("auto", fgYellow)
    , ("int", fgYellow)
    , ("int8", fgYellow)
    , ("int16", fgYellow)
    , ("int32", fgYellow)
    , ("int64", fgYellow)
    , ("bool", fgYellow)
    , ("true", fgMagenta)
    , ("false", fgMagenta)
    , ("uint", fgYellow)
    , ("uint8", fgYellow)
    , ("uint16", fgYellow)
    , ("uint32", fgYellow)
    , ("uint64", fgYellow)
    , ("float", fgYellow)
    , ("float32", fgYellow)
    , ("float64", fgYellow)
    , ("string", fgYellow)
    , ("char", fgYellow)
    , ("seq", fgYellow)
    , ("array", fgYellow)
    , ("range", fgYellow)
    , ("void", fgYellow)
    , ("RootObj", fgYellow)
    # other
    , ("echo", fgGreen)
    , ("assert", fgGreen)
    , ("and", fgCyan)
    , ("or", fgCyan)
    , ("xor", fgCyan)
    , ("is", fgCyan)
    , ("discard", fgRed)
    , ("import", fgCyan)
    ]
  if text.startsWith('"') and text.endsWith('"'):
    tb.write(styleDim, fgYellow, text, resetStyle, styleBright)
    return
  elif text.startsWith('"'):
    tb.write(styleDim, fgYellow, text)
    return
  elif text.endsWith('"'):
    tb.write(text, resetStyle, styleBright)
    return
  elif text.startsWith('\'') and text.endsWith('\''):
    tb.write(styleDim, fgYellow, text, resetStyle, styleBright)
    return
  elif text.startsWith('\''):
    tb.write(styleDim, fgYellow, text)
    return
  elif text.endsWith('\''):
    tb.write(text, resetStyle, styleBright)
    return
  for (keyword, color) in syntaxHighlight:
    if text == keyword:
      tb.write(color, text, resetStyle)
      return
  tb.write(text)

proc words*(text: string): seq[string] =
  var nextWord = ""
  var quoted = false
  for c in text:
    if c in {'"','\''}:
      nextWord.add(c)
      quoted = not quoted
    elif c in IdentChars:
      nextWord.add(c)
    elif not quoted:
      result.add(nextWord)
      result.add($c)
      nextWord = ""
  result.add(nextWord)

proc pprint(tb: var TerminalBuffer, text: string) =
  for i in text.words():
    tb.writeWithHighlight(i)

### modified from AndreiRegiani/INim
let
    uniquePrefix = epochTime().int
    bufferSource = getTempDir() & "inim_" & $uniquePrefix & ".nim"

proc compileCode(): auto =
    # PENDING https://github.com/nim-lang/Nim/issues/8312, remove redundant `--hint[source]=off`
    let compileCmd = fmt"nim compile --run --verbosity=0 --hints=off --hint[source]=off --path=./ {bufferSource}"
    result = execCmdEx(compileCmd)

proc getNimVersion*(): string =
    let (output, status) = execCmdEx("nim --version")
    doAssert status == 0, "make sure nim is in PATH"
    result = output.splitLines()[0]

proc getNimPath(): string =
    # TODO: use `which` PENDING https://github.com/nim-lang/Nim/issues/8311
    when defined(Windows):
        let which_cmd = "where nim"
    else:
        let which_cmd = "which nim"
    let (output, status) = execCmdEx(which_cmd)
    if status == 0:
        return " at " & output
    return "\n"
###

var
  maxHeight: int
  tb: TerminalBuffer
  buffer: string = ""
  nextLine: string = ""
  log: string = ""
  maxLines: int
  maxLineDigits: int
  viewingRange: int

proc exitProc(ec: int8 = 0) {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(ec)

proc ctrlCProc() {.noconv.} = exitProc(1)

proc cmdQuitProc() = exitProc()
proc cmdHelpProc() = discard
proc cmdLoadProc() = discard
proc cmdCatProc() =
    for (lineNbr, line) in buffer.splitLines()[viewingRange ..< maxLines].pairs():
      tb.setCursorPos(1, 4 + lineNbr)
      tb.write(fgWhite, styleDim, ($(lineNbr + 1 + viewingRange)).alignLeft(maxLineDigits, '`') & ">", styleBright)
      tb.pprint(line)

const
  cmdQuit = @[":quit", ":q"] ## exit repl
  cmdHelp = @[":help", ":h", ":?"] ## show help
  cmdLoad = @[":load", ":l"] ## add source file at top of buffer
  cmdCat  = @[":cat", ":c"] ## see current source buffer
  cmds = concat(cmdQuit, cmdHelp, cmdLoad, cmdCat)

proc main() =
  illwillInit(fullscreen=false)
  setControlCHook(ctrlCProc)
  hideCursor()

  maxHeight = terminalHeight() - 4 - 3
  tb = newTerminalBuffer(terminalWidth(), terminalHeight())
  while true:
    let key = getKey()
    case key:
      of None:
        discard
      of Enter:
        if log.len != 0:
          log = ""
        if nextLine.startsWith(':'):
          if nextLine in cmds:
            if nextLine in cmdQuit: cmdQuitProc()
            elif nextLine in cmdHelp: cmdHelpProc()
            elif nextLine in cmdLoad: cmdLoadProc()
          else:
            log.add(fmt"Invalid command '{nextLine}'! Please type ':?' to see help.")
        else:
          if buffer.len != 0:
            buffer = [buffer, nextLine].join("\n")
          else:
            buffer = nextLine
        nextLine = ""
      of Up:
        discard
      of Down:
        discard
      of Space:
        nextLine.add ' '
      of A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W,
         X, Y, Z:
        nextLine.add ('a'.int - ord(A) + ord(key)).char
      of ShiftA, ShiftB, ShiftC, ShiftD, ShiftE, ShiftF, ShiftG, ShiftH,
         ShiftI, ShiftJ, ShiftK, ShiftL, ShiftM, ShiftN, ShiftO, ShiftP,
         ShiftQ, ShiftR, ShiftS, ShiftT, ShiftU, ShiftV, ShiftW, ShiftX,
         ShiftY, ShiftZ:
        nextLine.add ('A'.int - ord(ShiftA) + ord(key)).char
      of One, Two, Three, Four, Five, Six, Seven, Eight, Nine, Zero:
        nextLine.add ('0'.int - ord(Zero) + ord(key)).char
      of BackSpace:
        nextLine = if nextLine.len == 0: nextLine
                   else: nextLine[0 ..< pred nextLine.len]
      of DoubleQuote:
        nextLine.add '"'
      of SingleQuote:
        nextLine.add '\''
      of Colon:
        nextLine.add ':'
      of Equals:
        nextLine.add '='
      of LeftParen:
        nextLine.add '('
      of RightParen:
        nextLine.add ')'
      of LeftBracket:
        nextLine.add '['
      of RightBracket:
        nextLine.add ']'
      of LeftBrace:
        nextLine.add '{'
      of RightBrace:
        nextLine.add '}'
      of Dot:
        nextLine.add '.'
      of Tab:
        nextLine.add "  "
      of Comma:
        nextLine.add ','
      of ExclamationMark:
        nextLine.add '!'
      of QuestionMark:
        nextLine.add '?'
      of Tilde:
        nextLine.add '~'
      of Minus:
        nextLine.add '-'
      of Plus:
        nextLine.add '+'
      of Dollar:
        nextLine.add '$'
      of Ampersand:
        nextLine.add '&'
      of GreaterThan:
        nextLine.add '>'
      of LessThan:
        nextLine.add '<'
      of Semicolon:
        nextLine.add ';'
      else:
        nextLine.add $key

    maxLines = buffer.splitLines().len
    maxLineDigits = ($maxLines).len + 1
    viewingRange = clamp(maxLines - maxHeight, 0, high(int))

    tb.write(resetStyle, fgBlack, styleBright)
    tb.clear(" ")
    tb.write(1,1, fgYellow, "nimREPL version " & nimREPL_version)
    tb.write(1,2, fgCyan, getNimVersion() & getNimPath())
    tb.write(1,3, fgWhite, styleDim, '`'.repeat(terminalWidth()), styleBright)

    if log.len != 0:
      tb.setCursorPos(1, terminalHeight() - 1)
      tb.write(fgRed, log, resetStyle, styleBright, fgWhite)

    tb.setCursorPos(1, terminalHeight() - 3)
    tb.write(fgWhite, styleDim, $(maxLines + 1) & ">>", resetStyle, fgWhite, styleBright)
    if nextLine.startsWith(':'):
      if nextLine in cmds:
        tb.write(fgGreen, nextLine)
      else:
        tb.write(fgRed, nextLine)
    else: tb.pprint(nextLine)

    tb.write(bgWhite, " ", resetStyle, bgNone, fgWhite, styleBright)
    tb.display()

  exitProc()

when isMainModule:
  main()
