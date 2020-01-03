### modified from AndreiRegiani/INim
import times, os, strformat, osproc, strutils
let
    uniquePrefix = epochTime().int
    bufferSource = getTempDir() & "nimREPL_" & $uniquePrefix & ".nim"

proc compileCode*(): auto =
    # PENDING https://github.com/nim-lang/Nim/issues/8312, remove redundant `--hint[source]=off`
    let compileCmd = fmt"nim compile --run --verbosity=0 --hints=off --hint[source]=off --path=./ {bufferSource}"
    result = execCmdEx(compileCmd)

proc getNimVersion*(): string =
    let (output, status) = execCmdEx("nim --version")
    doAssert status == 0, "make sure nim is in PATH"
    result = output.splitLines()[0]

proc getNimPath*(): string =
    # TODO: use `which` PENDING https://github.com/nim-lang/Nim/issues/8311
    when defined(Windows):
        let which_cmd = "where nim"
    else:
        let which_cmd = "which nim"
    let (output, status) = execCmdEx(which_cmd)
    if status == 0:
        return " at " & output
    return "\n"
