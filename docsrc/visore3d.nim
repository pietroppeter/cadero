## Il visore 3D (-> docs/visore3d.html): una pagina nimib con un solo blocco
## di codice Nim compilato in JavaScript (`nbJsFromCode`).
##
##   nim r docsrc/visore3d.nim      (o `nimble docs`, che genera tutti i documenti)
##
## La pagina non usa il tema dei documenti: ha il suo aspetto da banco di lavoro,
## scritto in `tools/visore3d.tpl.html` (stile, pulsanti, posto per la tavola e
## per lo script). Il codice del visore è in `src/cadero/visore.nim`, i binding
## di three.js in `src/cadero/js/three.nim`. Come funziona tutto insieme è
## spiegato in `docsrc/visore_nim.nim`.
import std/[base64, os, strutils, tables]
import nimib
import ../src/cadero, ../models/parete

const pagina = staticRead("../tools/visore3d.tpl.html")

proc renderVisore(): NbRender =
  ## Un renderer tutto suo (una copia di quello di nimib): il documento intero
  ## è il template del visore, con lo script dei blocchi al posto di __SCRIPT__.
  result = NbRender(funcs: nbToHtml.funcs, partials: nbToHtml.partials)
  result.funcs["NbDoc"] = proc (blk: NbBlock; nb: Nb): string =
    let p = rilievo()
    let back = """<nav class="back"><a href="index.html">← Indice</a></nav>"""
    "<!doctype html>\n<html lang=\"it\">\n<meta charset=\"utf-8\">\n" &
      "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n" &
      pagina.replace("__BACK__", back)
            .replace("__TAVOLA__", tavola(p, parete(p)))
            .replace("__SCRIPT__", nbContainerToHtml(blk, nb)) &
      "</html>\n"

nbInit(theme = (proc (nb: var Nb) = discard), renderer = renderVisore())

# la carta da parati (facoltativa): una piastrella del motivo, che si ripete
# sul muro; se il file manca il pulsante non compare. Misure assunte: due teli
# da 53 cm affiancati (motivo a mezza caduta), rapporto 52.6.
let cartaFile = currentSourcePath().parentDir.parentDir / "tools" / "carta-da-parati.jpg"
let cartaSrc = if fileExists(cartaFile): "data:image/jpeg;base64," & encode(readFile(cartaFile)) else: ""

# Il blocco qui sotto non gira qui: nimib lo compila con `nim js` e lo mette
# nella pagina come <script>. `cartaSrc` passa dal programma alla pagina come
# JSON (è una variabile "catturata"). Il file da compilare nimib lo scrive nella
# cartella dei documenti (docs/), per questo gli import partono da `../`.
nbJsFromCode(cartaSrc):
  import ../src/cadero/visore, ../models/parete

  # nel visore tutto parte chiuso: cassetti, ante, ribalte e tavolino si aprono
  # toccandoli. Tutte le combinazioni delle opzioni, con la chiave che usa il
  # visore: "base" o "tavolino", poi "Scoperta" (risega), "Antina" (solo con il
  # tavolino), "Comodino" (prese sul comodino); es. "tavolinoScopertaComodino".
  # I modelli si calcolano qui, nel browser, con lo stesso codice Nim delle tavole.
  var varianti: Table[string, Model]
  for tav in [false, true]:
    for scoperta in [false, true]:
      for antina in (if tav: @[false, true] else: @[false]):
        for comodino in [false, true]:
          var p = rilievo()
          p.cassettoAperto = -1
          if tav: p = p.conTavolino(aperto = false)
          p.risegaScoperta = scoperta
          p.antinaTavolino = antina
          p.preseSulComodino = comodino
          # (la chiave si scrive a pezzi: nimib ricopia il blocco come testo e
          # un `(if ...) & (if ...)` su più righe non sopravvive alla copia)
          var chiave = "base"
          if tav: chiave = "tavolino"
          if scoperta: chiave.add "Scoperta"
          if antina: chiave.add "Antina"
          if comodino: chiave.add "Comodino"
          varianti[chiave] = parete(p)
  let carta = Carta(src: cartaSrc, w: 106, h: 52.6)
  quandoThreePronto(proc () = avviaVisore(varianti, carta))

nbSave
