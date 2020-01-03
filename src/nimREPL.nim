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
    tb.write(1, 3, fgWhite, styleDim, '>'.repeat(terminalWidth()), resetStyle)

  proc render(tb: var TerminalBuffer, text: string) =


  proc exitProc() {.noconv.} =
    illwillDeinit()
    assert execShellCmd("clear") == 0
    quit()

  proc cmdQuitProc() = exitProc()
  proc cmdHelpProc() = discard
  proc cmdLoadProc() = discard
  proc cmdCatProc() = discard

  const
    cmdQuit = @[":quit", ":q"] ## exit repl
    cmdHelp = @[":help", ":h", ":?"] ## show help
    cmdLoad = @[":load", ":l"] ## add source file at top of buffer
    cmdCat  = @[":cat", ":c"] ## see current source buffer
    cmds = concat(cmdQuit, cmdHelp, cmdLoad, cmdCat)

  proc main() =
    illwillInit(fullscreen=false)
    setControlCHook(exitProc)

    var tb = newTerminalBuffer(terminalWidth(), terminalHeight())
    tb.displaySetup()
    tb.display()

    var buffer = ""

  main()
