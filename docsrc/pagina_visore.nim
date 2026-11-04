## La pagina del visore 3D, condivisa dai due visori (`visore3d.nim`, il modello
## dei falegnami, e `visore3d_idea.nim`, la nostra idea di partenza): un
## renderer nimib che mette il documento intero nel template
## `tools/visore3d.tpl.html`, con titolo, misure, tavola e note della pagina.
import std/[base64, os, strutils, tables]
import nimib

const pagina = staticRead("../tools/visore3d.tpl.html")

type PaginaVisore* = object
  titolo*: string     ## il <title> e il titolo in alto
  misure*: string     ## la riga delle misure accanto al titolo (HTML)
  tavola*: string     ## l'SVG della tavola sotto il visore
  didascalia*: string ## sotto la tavola
  nota*: string       ## in fondo alla pagina (HTML)

proc renderVisore*(p: PaginaVisore): NbRender =
  ## Un renderer tutto suo (una copia di quello di nimib): il documento intero
  ## è il template del visore, con lo script dei blocchi al posto di __SCRIPT__.
  result = NbRender(funcs: nbToHtml.funcs, partials: nbToHtml.partials)
  result.funcs["NbDoc"] = proc (blk: NbBlock; nb: Nb): string =
    let back = """<nav class="back"><a href="index.html">← Indice</a></nav>"""
    "<!doctype html>\n<html lang=\"it\">\n<meta charset=\"utf-8\">\n" &
      "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n" &
      pagina.replace("__TITOLO__", p.titolo)
            .replace("__MISURE__", p.misure)
            .replace("__BACK__", back)
            .replace("__TAVOLA__", p.tavola)
            .replace("__DIDASCALIA__", p.didascalia)
            .replace("__NOTA__", p.nota)
            .replace("__SCRIPT__", nbContainerToHtml(blk, nb)) &
      "</html>\n"

proc temaVuoto*(nb: var Nb) = discard
  ## il visore non usa il tema dei documenti: ha il suo aspetto da banco di lavoro

proc cartaDaParati*(): string =
  ## La carta da parati (facoltativa): una piastrella del motivo, che si ripete
  ## sul muro; se il file manca il pulsante non compare. Misure assunte: due teli
  ## da 53 cm affiancati (motivo a mezza caduta), rapporto 52.6.
  let f = currentSourcePath().parentDir.parentDir / "tools" / "carta-da-parati.jpg"
  if fileExists(f): "data:image/jpeg;base64," & encode(readFile(f)) else: ""
