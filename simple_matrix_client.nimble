# Package

version       = "0.1.0"
author        = "tandy"
description   = "A simple Matrix.org client"
license       = "AGPL-3.0-or-later"
srcDir        = "src"
bin           = @["client"]


# Dependencies

requires "nim >= 1.7.1"
requires "matrix"

task buildjs, "compile templates":
  exec "mkdir -p public"
  exec "nim js src/client.nim"
  exec "mv src/client.js public/"
