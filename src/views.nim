import pkg/prologue

proc home*(ctx: Context) {.async.} =
  resp readFile("public/index.html")
