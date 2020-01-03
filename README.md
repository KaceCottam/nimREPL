The Plan
===

The plan is to split the terminal into two halves. One half holds the current
buffer, while the other half holds the message and output log.

```nim
+------------------------- nimREPL version 0.1.0 -----------------------------+
|34 >for i in range[0..3]:                                                    |
|35 >  echo "hello"                                                           |
|36 >let b = 3                                                                |
|37 >proc doSomethingWith[U](b: int, fn: int->U): U =                         |
|38 >  if b == high(T):                                                       |
|39 >    echo $b, " is high(int)."                                            |
|40 >    try:                                                                 |
|41 >      return b.fn()                                                      |
|42 >    catch:                                                               |
|43 >      echo "Something unexpected happened!"                              |
|44 >      throw # pass on the error                                          |
|>>>>  else:                                                                  |
+------------------------- sourceFile: /dev/someFile.nim ---------------------+
|> hello                                                                      |
|> hello                                                                      |
|> hello                                                                      |
|> b: int = 3                                                                 |
|> doSomethingWith: proc[U](int, int -> U): U                                 |
|                                                                             |
+-----------------------------------------------------------------------------+
```

Typing something into the `>>>>` prompt adds it to the buffer. If there is no
indentation and no assignment for a noSideEffect declared function,
instead of being discarded: it is evaluated and outputted to the log.

The sourceFile is loaded into the top of the buffer.

Commands start with `:`, there is syntax highlighting based on if a command
exists. Some commands include:
+ :quit, :q     -> quit nimRepl
+ :help, :h, :? -> see commands
+ :load, :l     -> load a source file into the buffer

There is syntax highlighting made based on a reserved keywords list, numbers,
and primitive types.
