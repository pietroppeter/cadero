## La pagina del visore 3D come artefatto claude.ai.
##
## Il visore è il documento nimib `docsrc/visore3d.nim` (-> docs/visore3d.html):
## qui si prende quella pagina e la si adatta all'artefatto, che vuole solo il
## contenuto (niente doctype, niente <html>/<meta>) e non ha l'indice.
##
##   nim r docsrc/visore3d.nim     # prima: genera docs/visore3d.html
##   nim r tools/visore3d.nim      # poi:  tools/parete-3d.html per l'artefatto
import std/[os, strutils]

let dir = currentSourcePath().parentDir
let sorgente = dir.parentDir / "docs" / "visore3d.html"
if not fileExists(sorgente):
  quit "manca " & sorgente & ": prima `nim r docsrc/visore3d.nim`"
var pagina = readFile(sorgente)
pagina = pagina.replace("""<nav class="back"><a href="index.html">← Indice</a></nav>""" & "\n", "")
let inizio = pagina.find("<title>")
pagina = pagina[inizio .. ^1].replace("</html>\n", "")
let dest = dir / "parete-3d.html"
writeFile(dest, pagina)
echo "scritto ", dest
