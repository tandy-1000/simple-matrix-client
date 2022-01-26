import pkg/prologue

proc home*(ctx: Context) {.async.} =
  resp readFile("public/client.html")
