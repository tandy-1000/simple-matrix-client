import pkg/prologue

proc home*(ctx: Context) {.async.} =
  resp readFile("public/html/home.html")

proc client*(ctx: Context) {.async.} =
  resp readFile("public/html/client.html")
