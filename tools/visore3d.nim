## Genera la pagina del visore 3D (per l'artefatto claude.ai) dal modello attuale.
##   nim r tools/visore3d.nim  ->  tools/parete-3d.html
import std/[json, os, strutils]
import ../src/cadero, ../models/parete

let dir = currentSourcePath().parentDir
let tpl = readFile(dir / "visore3d.tpl.html")
writeFile(dir / "parete-3d.html", tpl.replace("__MODEL__", $toJson(parete(rilievo()))))
echo "scritto ", dir / "parete-3d.html"
