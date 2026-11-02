## Genera la pagina del visore 3D dal modello attuale.
##   nim r tools/visore3d.nim                     ->  tools/parete-3d.html (per l'artefatto claude.ai)
##   nim r tools/visore3d.nim docs/visore3d.html  ->  pagina completa per GitHub Pages
##
## L'artefatto vuole solo il contenuto (niente doctype); per Pages la pagina
## viene completata con doctype, charset e viewport, più un link ai documenti.
import std/[json, os, strutils]
import ../src/cadero, ../models/parete

let dir = currentSourcePath().parentDir
let tpl = readFile(dir / "visore3d.tpl.html")
  .replace("__MODEL__", $toJson(parete(rilievo())))

if paramCount() == 0:
  let dest = dir / "parete-3d.html"
  writeFile(dest, tpl.replace("__BACK__\n", ""))
  echo "scritto ", dest
else:
  let dest = paramStr(1)
  createDir(dest.parentDir)
  let back = """<nav class="back"><a href="index.html">← Indice</a></nav>"""
  writeFile(dest, """<!doctype html>
<html lang="it">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
""" & tpl.replace("__BACK__", back) & "</html>\n")
  echo "scritto ", dest
