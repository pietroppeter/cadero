## Il visore 3D (-> docs/visore3d.html): il modello dei falegnami
## (`models/falegnami.nim`), con e senza il pannello estraibile, e il modello
## rivisto con le nostre modifiche (con e senza la proposta per i vani alti). Una pagina
## nimib con un solo blocco di codice Nim compilato in JavaScript (`nbJsFromCode`).
##
## Si parte senza il pannello estraibile (Pietro); la tavola sotto il visore
## cambia con il pulsante.
##
##   nim r docsrc/visore3d.nim      (o `nimble docs`, che genera tutti i documenti)
##
## La pagina non usa il tema dei documenti: ha il suo aspetto da banco di lavoro,
## scritto in `tools/visore3d.tpl.html` (stile, pulsanti, posto per la tavola e
## per lo script) e riempito da `pagina_visore.nim`. Il codice del visore è in
## `src/cadero/visore.nim`, i binding di three.js in `src/cadero/js/three.nim`.
## Come funziona tutto insieme è spiegato in `docsrc/visore_nim.nim`. La nostra
## idea di partenza ha il suo visore: `visore3d_idea.nim`.
import std/[strformat, tables]
import nimib
import ../src/cadero, ../models/falegnami, pagina_visore

let f0 = falegnami()

proc tavolaVariante(f: Falegnami; chiave: string; nascosta: bool): string =
  ## una tavola per variante: il visore mostra quella del modello scelto
  "<div data-chiave=\"" & chiave & "\"" & (if nascosta: " hidden" else: "") & ">" &
    tavola(f, modello(f)) & "</div>"
nbInit(theme = temaVuoto, renderer = renderVisore(PaginaVisore(
  titolo: "Visore 3D",
  misure: &"L <b>{f0.larghezza:g}</b> × H <b>{f0.altezza:g}</b> × P <b>{f0.profondita:g}</b> cm · melaminico 19 mm, multistrato 18 mm",
  tavola: tavolaVariante(f0.senzaPannello, "falegnamiSenzaPannello", false) &
          tavolaVariante(f0, "falegnami", true) &
          tavolaVariante(f0.rivisto, "rivisto", true) &
          tavolaVariante(f0.rivisto.vaniAlti, "rivistoVani", true),
  didascalia: &"prospetto frontale, sezione laterale nella libreria (x = {f0.xSezione:g}) e pianta sopra il piano letto (z = 130), con le quote; cambia con il modello scelto",
  nota: "<strong>Tocca cassetti, ante, ribalte e le altre parti mobili per aprirle o chiuderle.</strong> " &
    "Trascina per ruotare, pizzica o usa la rotella per lo zoom, trascina con due dita (o tasto destro) per spostarti. " &
    "Il modello è generato dal codice Nim di Caderò a partire dalle tavole dei falegnami; misure rilevate e ipotesi " &
    "sono nel <a href=\"modello_falegnami.html\">documento del modello</a>. La nostra idea di partenza: " &
    "<a href=\"visore3d_idea.html\">Visore 3D - Idea</a>.")))

let cartaSrc = cartaDaParati()

# Il blocco qui sotto non gira qui: nimib lo compila con `nim js` e lo mette
# nella pagina come <script>. `cartaSrc` passa dal programma alla pagina come
# JSON (è una variabile "catturata"). Il file da compilare nimib lo scrive nella
# cartella dei documenti (docs/), per questo gli import partono da `../`.
nbJsFromCode(cartaSrc):
  import ../src/cadero/visore, ../models/falegnami

  # nel visore tutto parte chiuso: cassetti, ante e ribalte si aprono toccandoli.
  # Le due varianti, con la chiave che usa il visore: con il pannellino
  # estraibile tra i gradini ("falegnami") e senza ("falegnamiSenzaPannello").
  # I modelli si calcolano qui, nel browser, con lo stesso codice Nim delle tavole.
  var varianti: Table[string, Model]
  varianti["falegnami"] = modello(falegnami())
  varianti["falegnamiSenzaPannello"] = modello(falegnami().senzaPannello)
  # il modello rivisto (testata 58, pannello della risega 10, senza pannellino) e,
  # sopra, la proposta per i vani alti più alti
  varianti["rivisto"] = modello(falegnami().rivisto)
  varianti["rivistoVani"] = modello(falegnami().rivisto.vaniAlti)
  let carta = Carta(src: cartaSrc, w: 106, h: 52.6)
  quandoThreePronto(proc () = avviaVisore(varianti, carta))

copiaThree($nb.doc.homeDir)   # three.js accanto alla pagina, in three/
nbSave
