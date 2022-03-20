# Package

version       = "0.1.0"
author        = "tandy"
description   = "A simple Matrix.org client"
license       = "AGPL-3.0-or-later"
bin           = @["simple_matrix_client/server"]
installExt    = @["nim"]

# Dependencies

requires "nim >= 1.7.1"
requires "https://github.com/tandy-1000/matrix-nim-sdk#head"
requires "https://github.com/juancarlospaco/nodejs/#head"
requires "prologue"
requires "karax"

task sass, "Generate css":
  exec "mkdir -p public/css"
  exec "sass --style=compressed --no-source-map simple_matrix_client/sass/simple_matrix_client/index.sass public/css/style.css"

task buildjs, "compile templates":
  exec "mkdir -p public public/js"
  exec "nim -o:public/js/simple_matrix_client.js js simple_matrix_client/simple_matrix_client.nim"
