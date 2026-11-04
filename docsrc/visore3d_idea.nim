## Il visore 3D della nostra idea di partenza (-> docs/visore3d_idea.html): la
## parete di `models/parete.nim`, con le sue varianti (tavolino, risega, prese).
## Il visore di default è `visore3d.nim`, con il modello dei falegnami.
##
##   nim r docsrc/visore3d_idea.nim   (o `nimble docs`, che genera tutti i documenti)
##
## La pagina è la stessa del visore (`pagina_visore.nim`, template
## `tools/visore3d.tpl.html`); cambiano i modelli e i testi.
import std/tables
import nimib
import ../src/cadero, ../models/parete, pagina_visore

let p0 = rilievo()
nbInit(theme = temaVuoto, renderer = renderVisore(PaginaVisore(
  titolo: "Visore 3D - Idea",
  misure: "L <b>237</b> × H <b>316</b> × P <b>80</b> cm · multistrato 18 mm",
  tavola: tavola(p0, parete(p0)),
  didascalia: "prospetto frontale, vista laterale e pianta con le quote, scala 1:25 @ A4; il cassetto centrale è disegnato aperto",
  nota: "<strong>Tocca cassetti, ante, ribalte, coperchi del gavone, materasso e tavolino per aprirli o chiuderli.</strong> " &
    "Trascina per ruotare, pizzica o usa la rotella per lo zoom, trascina con due dita (o tasto destro) per spostarti. " &
    "È la nostra idea di partenza, generata dal codice Nim di Caderò con i parametri rilevati dal disegno; " &
    "le misure non scritte sulla tavola sono ipotesi. Il modello dei falegnami è nel <a href=\"visore3d.html\">visore 3D</a>.")))

let cartaSrc = cartaDaParati()

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
          p.disegno.cassettoAperto = -1
          if tav: p = p.conTavolino(aperto = false)
          p.libreria.risegaRivestita = not scoperta
          p.tavolino.antina = antina
          p.prese.sulComodino = comodino
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

copiaThree($nb.doc.homeDir)   # three.js accanto alla pagina, in three/
nbSave
