## Genera la pagina del visore 3D dal modello attuale.
##   nim r tools/visore3d.nim                     ->  tools/parete-3d.html (per l'artefatto claude.ai)
##   nim r tools/visore3d.nim docs/visore3d.html  ->  pagina completa per GitHub Pages
##
## L'artefatto vuole solo il contenuto (niente doctype); per Pages la pagina
## viene completata con doctype, charset e viewport, più un link ai documenti.
import std/[base64, json, os, strutils]
import ../src/cadero, ../models/parete

let dir = currentSourcePath().parentDir

# nel visore tutto parte chiuso: cassetti, ante, ribalte e tavolino si aprono toccandoli
var base = rilievo()
base.cassettoAperto = -1
let tavolino = base.conTavolino(aperto = false)
var scoperta = base
scoperta.risegaScoperta = true
let tavolinoScoperta = scoperta.conTavolino(aperto = false)

# la carta da parati (facoltativa): una piastrella del motivo, che si ripete
# sul muro; se il file manca il pulsante non compare.
# Misure assunte: due teli da 53 cm affiancati (motivo a mezza caduta), rapporto 52.6.
let cartaFile = dir / "carta-da-parati.jpg"
let carta = if fileExists(cartaFile):
    "{\"src\": \"data:image/jpeg;base64," & encode(readFile(cartaFile)) & "\", \"w\": 106, \"h\": 52.6}"
  else: "null"

proc paginaVisore(): string =
  readFile(dir / "visore3d.tpl.html")
    .replace("__MODEL_TAVOLINO_SCOPERTA__", $toJson(parete(tavolinoScoperta)))
    .replace("__MODEL_TAVOLINO__", $toJson(parete(tavolino)))
    .replace("__MODEL_SCOPERTA__", $toJson(parete(scoperta)))
    .replace("__MODEL__", $toJson(parete(base)))
    .replace("__CARTA__", carta)

proc scriviArtefatto*() =
  ## tools/parete-3d.html: solo il contenuto, per l'artefatto claude.ai.
  let dest = dir / "parete-3d.html"
  writeFile(dest, paginaVisore().replace("__BACK__\n", ""))
  echo "scritto ", dest

proc scriviPagina*(dest: string) =
  ## La pagina completa per Pages, con doctype, charset, viewport e il link all'indice.
  createDir(dest.parentDir)
  let back = """<nav class="back"><a href="index.html">← Indice</a></nav>"""
  writeFile(dest, """<!doctype html>
<html lang="it">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
""" & paginaVisore().replace("__BACK__", back) & "</html>\n")
  echo "scritto ", dest

proc paginaDocs*(): string =
  ## Dove va la pagina del visore su Pages: docs/visore3d.html.
  dir.parentDir / "docs" / "visore3d.html"

when isMainModule:
  if paramCount() == 0: scriviArtefatto()
  else: scriviPagina(paramStr(1))
