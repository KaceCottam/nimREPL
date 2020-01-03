import util/borrowed

import strutils

proc syntax*(text: string): seq[string] =
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

when isMainModule:
  import illWill

  import sequtils, os

  const nimREPL_version = "0.1.0"
  proc displaySetup(tb: var TerminalBuffer) =
    tb.write(1, 1, fgCyan, "nimREPL version " & nimREPL_version)
    tb.write(1, 2, fgYellow, getNimVersion() & getNimPath())
    tb.write(1, 3, fgWhite, styleDim, '='.repeat(terminalWidth()), resetStyle)

  proc exitProc() {.noconv.} =
    illwillDeinit()
    showCursor()
    quit(0)

  import tables

  proc cmdQuitProc() = exitProc()
  proc cmdHelpProc() = discard

  const cmdList = { ":quit": cmdQuitProc
                  , ":q"   : cmdQuitProc
                  , ":help": cmdHelpProc
                  , ":h"   : cmdHelpProc
                  , ":?"   : cmdHelpProc
                  }.toTable

  import util/syntaxHighlightDefs
  import tables
  proc render(tb: var TerminalBuffer, text: string) =
    proc splitSyntax(text: string): seq[string] =
      var nextWord = ""
      for c in text:
        if c in IdentChars:
          nextWord.add(c)
        else:
          result.add(nextWord)
          result.add($c)
          nextWord = ""
      result.add(nextWord)

    proc renderSyntax(tb: var TerminalBuffer, text: string) =
      if text.allCharsInSet(Digits):
        tb.write(fgMagenta, text, resetStyle)
        return
      try:
        tb.write(syntaxHighlight[text], text, resetStyle)
      except KeyError:
        tb.write(text)

    for token in text.splitSyntax():
      tb.renderSyntax(token)

  proc main() =
    illwillInit(fullscreen=true)
    setControlCHook(exitProc)
    hideCursor()

    var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

    var buffer = ""
    var log = ""
    var line = ""
    var replaceMode = false

    while true:
      let key: Key = getKey()
      case key
      of {A..Z}: line.add char 'a'.int - Key.A.int + key.int
      of {ShiftA..ShiftZ}: line.add char 'A'.int - Key.ShiftA.int + key.int
      of {Zero..Nine}: line.add char '0'.int - Key.Zero.int + key.int
      of Space: line.add ' '
      of Tab: line.add "  "
      of LeftParen: line.add '('
      of RightParen: line.add ')'
      of LeftBrace: line.add '{'
      of RightBrace: line.add '}'
      of LeftBracket: line.add '['
      of RightBracket: line.add ']'
      of Colon: line.add ':'
      of ExclamationMark: line.add '!'
      of QuestionMark: line.add '?'
      of DoubleQuote: line.add '"'
      of SingleQuote: line.add '\''
      of Hash: line.add '#'
      of Dollar: line.add '$'
      of Percent: line.add '%'
      of Caret: line.add '^'
      of Ampersand: line.add '&'
      of Asterisk: line.add '*'
      of Plus: line.add '+'
      of Equals: line.add '='
      of Minus: line.add '-'
      of Comma: line.add ','
      of Dot: line.add '.'
      of Slash: line.add '/'
      of BackSlash: line.add '\\'
      of At: line.add '@'
      of Semicolon: line.add ';'
      of GreaterThan: line.add '>'
      of LessThan: line.add '<'
      of Underscore: line.add '_'
      of GraveAccent: line.add '`'
      of Pipe: line.add '|'
      of Tilde: line.add '~'
      # functional keys
      of Enter:
        if log.len != 0:
          log = ""
        if line.startsWith ':':
          try:
            cmdList[line]()
          except KeyError:
            log.add "Invalid Command! Try ':?'"
        else:
          if buffer.len != 0: buffer.add "\n"
          buffer.add line
        line = ""
      of Up: discard
      of Down: discard
      of Left: discard
      of Right: discard
      of Home: discard
      of End: discard
      of Insert: replaceMode = not replaceMode
      of Delete: discard
      of PageUp: discard
      of PageDown: discard
      of BackSpace:
        if line.len >= 1: line.delete(line.len - 1, line.len - 1)
      else: discard

      tb.clear(" ")
      tb.displaySetup()

      let bufferSplitLines = buffer.splitLines()
      for (lineNbr, line) in bufferSplitLines.pairs():
        let numberStmt = alignLeft($(lineNbr + 1), len $($bufferSplitLines.len),
                                   '`') & "`>"
        tb.setCursorPos(1, 4 + lineNbr)
        tb.write(styleDim, numberStmt, resetStyle)
        tb.render(line)


      tb.setCursorPos(1, 4 + buffer.splitLines().len)
      tb.write(fgWhite, styleDim, ">>>", resetStyle)
      if line.startsWith ':':
        if line in cmdList: tb.write(fgGreen, line, resetStyle)
        else: tb.write(fgRed, line, resetStyle)
      else: tb.render(line)
      tb.write(bgWhite, " ")
      tb.display()
      tb.resetAttributes()

  main()
