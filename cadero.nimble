# Package

version       = "0.1.0"
author        = "Pietro Peterlongo"
description   = "Caderò: mini CAD in Nim per mobili fatti di pannelli"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.6.0"
requires "nimib >= 0.3.0"   # solo per i documenti in docsrc/

task test, "esegue i test":
  exec "nim c -r tests/test_parete.nim"

task docs, "genera i documenti nimib in docs/":
  exec "nim r docsrc/index.nim"
  exec "nim r docsrc/parete_nicchia.nim"
  exec "nim r docsrc/come_funziona.nim"
  exec "nim r tools/visore3d.nim docs/visore3d.html"
