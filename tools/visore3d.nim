## La pagina del visore 3D come artefatto claude.ai.
##
## I visori sono documenti nimib: `docsrc/visore3d.nim` (-> docs/visore3d.html,
## il modello dei falegnami) e `docsrc/visore3d_idea.nim` (-> docs/visore3d_idea.html,
## la nostra idea). Qui si prende una di quelle pagine e la si adatta
## all'artefatto, che vuole solo il contenuto (niente doctype, niente <html>/<meta>)
## e non ha l'indice.
##
##   nim r docsrc/all_docs.nim             # prima: genera docs/
##   nim r tools/visore3d.nim              # poi:  tools/parete-3d.html
##   nim r tools/visore3d.nim visore3d_idea   #     tools/parete-3d-idea.html
import std/[os, strutils]

let dir = currentSourcePath().parentDir
let nome = if paramCount() > 0: paramStr(1) else: "visore3d"
let sorgente = dir.parentDir / "docs" / nome & ".html"
if not fileExists(sorgente):
  quit "manca " & sorgente & ": prima `nim r docsrc/" & nome & ".nim`"
var pagina = readFile(sorgente)
pagina = pagina.replace("""<nav class="back"><a href="index.html">← Indice</a></nav>""" & "\n", "")
let inizio = pagina.find("<title>")
pagina = pagina[inizio .. ^1].replace("</html>\n", "")
let dest = dir / (if nome == "visore3d": "parete-3d.html" else: "parete-3d-idea.html")
writeFile(dest, pagina)
echo "scritto ", dest
