# Package

version       = "0.1.0"
author        = "tandy"
description   = "A simple Matrix.org client"
license       = "AGPL-3.0-or-later"
srcDir        = "src"
bin           = @["server"]


# Dependencies

requires "nim >= 1.7.1"
requires "https://github.com/tandy-1000/matrix-nim-sdk#head"
requires "https://github.com/tandy-1000/nodejs/#head"
requires "karax"

task buildjs, "compile templates":
  exec "mkdir -p public public/js"
  exec "nim -d:nimExperimentalAsyncjsThen -o:public/js/client.js js src/client.nim"
