## I parametri della parete (-> docs/parametri.html): cosa sono, come dipendono
## l'uno dall'altro, cosa non torna e cosa si potrebbe cambiare. In mezzo, il
## banco: il visore 3D con un cursore per ogni parametro, che ricalcola il
## modello nel browser (codice in `docsrc/banco_parametri.nim`).
import std/[base64, os, strutils]
import nimib, tema
import markdown
import ../src/cadero, ../models/[parete, parete_parametri]

nbInit(theme = useTema)
nb.title = "I parametri della parete"

let p = rilievo()

# stile del banco: visore e cursori affiancati su schermo largo, uno sotto
# l'altro (con il visore che resta in alto) sul telefono
nbRawHtml: """<style>
.banco { margin: 18px calc(50% - min(620px, 50vw - 20px)); display: grid; gap: 14px; }
@media (min-width: 960px) { .banco { grid-template-columns: minmax(0, 1.55fr) minmax(320px, 1fr); align-items: start; }
  .banco .vista { position: sticky; top: 10px; } .banco .pannello { max-height: calc(100vh - 20px); overflow-y: auto; } }
@media (max-width: 959px) { section.banco .vista { display: contents; } .banco .stage { position: sticky; top: 0; z-index: 2; height: 44vh; min-height: 260px; } }
.banco .vista { display: grid; gap: 10px; min-width: 0; }
.stage { position: relative; width: 100%; height: min(68vh, 640px); min-height: 320px; background: var(--stage);
  border: 1px solid var(--line); border-radius: 6px; overflow: hidden; touch-action: none; }
.stage canvas { display: block; width: 100%; height: 100%; }
.status { position: absolute; left: 12px; bottom: 10px; font-family: var(--mono); font-size: 12px; color: var(--muted); pointer-events: none; }
.bar { display: flex; flex-wrap: wrap; gap: 8px 18px; align-items: center; }
.bar .group[hidden] { display: none; }
.bar .group { display: flex; flex-wrap: wrap; gap: 6px; align-items: center; }
.bar .label { font-family: var(--display); font-size: 13px; letter-spacing: 0.08em; text-transform: uppercase; color: var(--muted); margin-right: 2px; }
button[aria-pressed="true"] { border-color: var(--accent); color: var(--accent); }
.riassunto { font-family: var(--mono); font-size: 13px; color: var(--muted); font-variant-numeric: tabular-nums; }
.riassunto b { color: var(--accent); font-weight: 400; } .riassunto .allarme b { color: #c0392b; }
.pannello { display: grid; gap: 10px; align-content: start; min-width: 0; }
.pannello .testa { display: flex; justify-content: space-between; align-items: center; gap: 8px; font-size: 13.5px; color: var(--muted); }
.pannello .testa { flex-wrap: wrap; }
.cambiati { font-size: 13.5px; display: grid; gap: 8px; } .incolla[hidden], .pannello .testa a[hidden] { display: none; }
.cambiati .testa { display: flex; justify-content: space-between; align-items: center; gap: 8px; flex-wrap: wrap; color: var(--muted); }
.cambiati .testa .azioni, .pannello .testa .azioni { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.cambiati table { border-collapse: collapse; width: 100%; margin-top: 4px; }
.cambiati td { padding: 2px 6px 2px 0; border-bottom: 1px solid var(--line); vertical-align: top; }
.cambiati td.num { font-family: var(--mono, monospace); white-space: nowrap; text-align: right; }
.cambiati code { font-size: 12px; color: var(--muted); }
.incolla { display: grid; gap: 6px; } .incolla textarea { width: 100%; box-sizing: border-box; font-family: var(--mono, monospace); font-size: 12.5px; }
.avvisi { background: #fbeee9; border: 1px solid #e8b9a8; border-radius: 6px; padding: 8px 12px; font-size: 13.5px; color: #7a2d17; }
.avvisi ul { margin: 0; padding-left: 18px; } .avvisi p { margin: 0; }
.avvisi.vuoto { background: var(--paper); border-color: var(--line); color: var(--muted); }
:root[data-theme="dark"] .avvisi:not(.vuoto) { background: #3a2420; border-color: #6b3a2e; color: #f0c4b4; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) .avvisi:not(.vuoto) { background: #3a2420; border-color: #6b3a2e; color: #f0c4b4; } }
details.gruppo { background: var(--paper); border: 1px solid var(--line); border-radius: 6px; padding: 6px 12px; }
details.gruppo summary { font-family: var(--display); font-weight: 600; font-size: 19px; cursor: pointer; padding: 2px 0; }
details.gruppo .spiega { font-size: 13px; color: var(--muted); margin: 2px 0 8px; }
.riga { display: grid; gap: 2px; padding: 6px 0; border-top: 1px solid var(--line); font-size: 14px; }
.riga label { display: flex; gap: 6px; align-items: baseline; flex-wrap: wrap; }
.riga small { color: var(--muted); font-size: 12px; line-height: 1.35; }
.riga.cambiato label { color: var(--accent); font-weight: 500; }
.riga.bool { display: flex; align-items: center; gap: 8px; cursor: pointer; }
.cursore { display: flex; gap: 8px; align-items: center; }
.cursore input[type=range] { flex: 1; min-width: 0; accent-color: var(--accent); }
.cursore input[type=number] { width: 6.5ch; font: 13px var(--mono); padding: 3px 4px; background: var(--bg); color: var(--fg);
  border: 1px solid var(--line); border-radius: 4px; }
.orig { font-family: var(--mono); font-size: 10.5px; padding: 0 5px; border-radius: 3px; background: var(--code-bg); color: var(--muted); }
.o-ipotesi { background: #f6e3c6; color: #7a4a12; } .o-doppione { background: #f3d4cc; color: #7a2d17; }
.o-deciso { background: #d9ead9; color: #24572a; }
:root[data-theme="dark"] .o-ipotesi, :root[data-theme="dark"] .o-doppione, :root[data-theme="dark"] .o-deciso { filter: brightness(0.7) contrast(1.3); }
table.derivate td.num, table.derivate th.num, table.parametri td.num { text-align: right; font-family: var(--mono); font-variant-numeric: tabular-nums; }
table.derivate tr.allarme td { color: #c0392b; } table.derivate tr.allarme td.num { font-weight: 600; }
table.derivate td:nth-child(2), table.parametri td:last-child { color: var(--muted); font-size: 13.5px; }
.catene-box svg.catene { width: 100%; max-width: 440px; border: 0; }
svg.catene rect.f { fill: var(--paper); stroke: var(--muted); stroke-width: 0.6; }
svg.catene rect.f.caldo { fill: #f6d9b0; } svg.catene text { font: 11px var(--body); fill: var(--fg); }
svg.catene text.h { font: 600 14px var(--display); letter-spacing: 0.06em; text-transform: uppercase; fill: var(--muted); }
svg.catene line.l { stroke: var(--muted); stroke-dasharray: 3 2; } svg.catene line.l.caldo { stroke: var(--accent); stroke-width: 1.4; }
svg.catene text.t { font: 10px var(--mono); fill: var(--accent); }
:root[data-theme="dark"] svg.catene rect.f.caldo { fill: #5a4325; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) svg.catene rect.f.caldo { fill: #5a4325; } }
.tavola-box { margin: 10px calc(50% - min(620px, 50vw - 20px)); }
.tavola-box svg { width: 100%; height: auto; background: #fff; }
button.prova { margin: 0 6px 8px 0; border-style: dashed; }
button.prova::before { content: "▶ "; color: var(--accent); }
.problema { border-left: 3px solid var(--accent); padding-left: 14px; margin: 18px 0; }
.problema h3 { margin-top: 0; }
</style>"""

nbText: """
# I parametri della parete

I parametri della parete sono ora divisi in **gruppi**, un oggetto Nim per gruppo,
come li ha descritti Pietro nella revisione del 3 novembre. Si parte dai **vincoli
del muro**, le misure della stanza, e tutte le altre misure si prendono da un
riferimento: il muro, la risega, la base del letto, il soffitto della nicchia.
Quello che ne viene fuori (l'altezza del mobile, la fascia, lo schienale, il bordo
davanti al materasso, lo spazio tra le ribalte...) si calcola e non si scrive più
due volte.

Nel banco qui sotto ogni gruppo ha i suoi cursori; i valori cambiati diventano
arancio e sopra i cursori compaiono gli avvisi, compresi i vincoli soft (schienale
almeno 40, bordo almeno 16, spazio tra le ribalte almeno 4). Più sotto: cosa è
cambiato nel mobile, cosa resta da decidere (con i pulsanti ▶ **Prova**) e le
quote.

In fondo alla pagina, in **Parametri cambiati**, c'è l'elenco dei parametri diversi
dal rilievo, con Copia e Incolla per chiedere di cambiare i valori di default.
"""

nbRawHtml: """<section class="banco" id="banco">
  <div class="vista">
    <div class="stage" id="stage"><div class="status" id="status">Caricamento del modello…</div></div>
    <div class="riassunto" id="riassunto"></div>
    <div class="bar">
      <div class="group" role="group" aria-label="Viste">
        <span class="label">Vista</span>
        <button id="v-iniziale" type="button">Tre quarti</button>
        <button id="v-dentro" type="button">Dentro</button>
      </div>
      <div class="group" id="g-mobile" hidden>
        <button id="m-base" type="button" aria-pressed="true"></button><button id="m-tavolino" type="button"></button>
        <button id="m-antina" type="button"></button><button id="m-prese" type="button"></button><button id="m-risega" type="button"></button>
        <button id="m-falegnami" type="button"></button>
      </div>
      <div class="group" id="g-modifiche" hidden>
        <button id="p-tavolino" type="button"></button><button id="p-testata" type="button"></button>
        <button id="p-risega" type="button"></button><button id="p-vani" type="button"></button>
      </div>
      <div class="group" id="g-taglio" hidden>
        <button id="f-croce" type="button"></button><button id="f-tre" type="button"></button><button id="f-cornice" type="button"></button>
      </div>
      <div class="group" role="group" aria-label="Multistrato">
        <button id="t-betulla" type="button" aria-pressed="true">Betulla</button>
        <button id="t-venatura" type="button" aria-pressed="false">Venatura</button>
      </div>
      <div class="group" role="group" aria-label="Apertura">
        <span class="label">Apri</span>
        <button id="t-apri" type="button">Tutto</button>
        <button id="t-chiudi" type="button">Chiudi</button>
      </div>
      <div class="group" role="group" aria-label="Nascondi">
        <span class="label">Nascondi</span>
        <button id="t-carta" type="button" aria-pressed="false" hidden>Carta</button>
        <button id="t-fronte" type="button" aria-pressed="false">Fronte</button>
      </div>
      <div class="group" role="group" aria-label="Speciale">
        <button id="t-esploso" type="button" aria-pressed="false">Esploso</button>
      </div>
    </div>
  </div>
  <div class="pannello">
    <div class="testa"><span id="n-cambiati">valori del rilievo</span><span class="azioni"><a href="#parametri-cambiati" id="vai-cambiati" hidden>quali?</a><button type="button" id="ripristina">Torna al rilievo</button></span></div>
    <div class="avvisi" id="avvisi"></div>
    <div id="controlli"></div>
  </div>
</section>
<style>
</style>"""

nbText: """
## Le misure che ne vengono fuori

Le misure derivate, con la formula, aggiornate dal banco. In rosso quelle fuori
soglia. Accanto, le **due catene verticali**: a sinistra quella del fronte (dove
stanno i frontali), a destra quella di dentro (piano letto, materasso, schienale,
vani). In arancio le fasce del fronte che ora si calcolano (fascia e stacco) e i
tre punti dove le catene si incontrano: le ante sotto il piano letto, il bordo
sopra il materasso, le ribalte sopra il soffitto della nicchia.
"""

nbRawHtml: """<div id="derivate"></div><div class="catene-box" id="catene"></div>"""

nbText: """
## I gruppi di parametri

`Parete` in `models/parete.nim` ha un campo per gruppo (`p.muro`, `p.altezze`,
`p.libreria`...), con i valori di `rilievo()`. La colonna *origine* dice da dove
viene il numero: **stanza** (misurato nella stanza), **disegno** (scritto sulla
tavola di riferimento), **rilevato** (misurato in scala 1:25), **deciso** (da
Pietro), **ipotesi** (da verificare), **variante** (sì/no).
"""

proc tabella(g: Gruppo): string =
  result = "<h3>" & g.nome & "</h3><p>" & g.spiega & "</p><table class=\"parametri\"><thead><tr>" &
    "<th>Parametro</th><th>Campo</th><th class=\"num\">Valore</th><th>Origine</th><th>Da sapere</th></tr></thead><tbody>"
  for q in g.params:
    let v = p.valore(q.campo)
    let vs = if q.origine == oVariante: (if v > 0.5: "sì" else: "no") else: fmtNum(v)
    result.add "<tr><td>" & q.etichetta & "</td><td><code>" & q.campo & "</code></td><td class=\"num\">" & vs &
      "</td><td><span class=\"orig o-" & $q.origine & "\">" & $q.origine & "</span></td><td>" & q.nota & "</td></tr>"
  result.add "</tbody></table>"

var tabelle = ""
for g in gruppi(): tabelle.add tabella(g)
nbRawHtml: tabelle

var stato = "<h3>Disegno</h3><p>Un gruppo a parte che non descrive il mobile: dice solo cosa " &
  "la tavola disegna aperto; nel visore non serve (lì si apre toccando).</p><table class=\"parametri\"><tbody>"
for (campo, cosa) in statoDisegno(): stato.add "<tr><td><code>" & campo & "</code></td><td>" & cosa & "</td></tr>"
stato.add "</tbody></table>"
nbRawHtml: stato

nbText: """
## Cosa è cambiato nel mobile

Confrontato pezzo per pezzo con il modello di prima, il mobile è quasi uguale.
Cambia questo:

- **i gradini si spostano di 1 cm a sinistra**: lo spazio ai loro lati è uno solo,
  6.5 (prima 7.5 a sinistra e 5.5 a destra). Cassetti e anta stretta restano dove
  erano, e lo spazio tra loro, calcolato, è ancora 8.5;
- **le ribalte sono larghe 68** (prima 68.17, calcolate) e lo spazio tra loro è 4
  (prima 3.75, sotto la soglia di 4);
- **la risega è larga 38.8** come la colonna (prima 38) e il **divisorio è a filo
  della risega**: va da 196.4 a 198.2 (prima era centrato su 198.2). Comodino e
  coperchi del gavone sono larghi 38.8, la campata della nicchia scende a 194.6;
- **il materasso è centrato** anche in profondità: 2.3 cm di gioco per lato in
  lunghezza, 0.1 in larghezza.

L'altezza resta 316, la catena del fronte resta 6 / 95 / 30 / 122 / 12 / 43 / 8 e i
vani della libreria restano 32.5.
"""

proc problema(titolo, testo: string; prove: openArray[(string, string)] = []) =
  var h = "<div class=\"problema\"><h3>" & titolo & "</h3>"
  h.add markdown(testo)
  for (etichetta, valori) in prove:
    h.add "<button type=\"button\" class=\"prova\" data-prova=\"" & valori & "\">" & etichetta & "</button>"
  h.add "</div>"
  nbRawHtml: h

nbText: """
## Da decidere

Con i gruppi nuovi i problemi della prima bozza sono quasi tutti risolti per
costruzione (la tabella alla fine). Restano queste cose, in ordine di importanza.
"""

problema("1. Il bordo davanti al materasso è di 10 cm", """
È la cornice bassa (27) meno il materasso (17). Il controllo soft chiede almeno 16:
servirebbe la cornice bassa a 33, con l'apertura della nicchia che scende a 116, o
un materasso più basso. Oggi è l'unico avviso che scatta.
""", [("Prova: cornice bassa 33", "cornice.bassa=33"), ("Prova: materasso 11", "materasso.altezza=11")])

problema("2. In alto due catene si incontrano", """
Le ribalte si misurano dal soffitto della stanza (margine alto 8, ribalte 43), il
soffitto della nicchia da terra (base letto 104 + nicchia 159.2 + spessore). Oggi
tutti e due fanno 265, ma se cambia uno dei due la ribalta scende sul soffitto
della nicchia, o resta una striscia di fronte tra i due. C'è un controllo. Si
può anche decidere che una delle due misure si calcoli: per esempio le ribalte
partono dalla cima del soffitto della nicchia e il margine alto prende il resto.
""", [("Prova: nicchia 165", "altezze.nicchia=165"), ("Prova: margine alto 4", "alta.margineAlto=4")])

problema("3. Con il gioco di montaggio il materasso da 78 non entra", """
Mezzo centimetro di gioco per lato basta: tra il frontale e il muro restano 77.7.
Le ribalte scendono di 0.5 sul soffitto della nicchia, perché sono misurate dal
soffitto della stanza, e tra di loro restano 3.5 cm. Il gioco di montaggio va
deciso, perché tocca tre misure.
""", [("Prova: gioco 0.5", "costruzione.gioco=0.5")])

problema("4. Il condizionatore non c'è ancora", """
Sul muro di sinistra, sopra la porta: limita l'apertura della ribalta in alto a
sinistra. Aspetto la soluzione e le sue misure: altezza da terra, sporgenza dal
muro e distanza dalla parete del mobile.
""")

problema("5. Numeri ancora nascosti nel codice", """
Dentro `parete(p)` restano una ventina di misure senza nome: margini
dell'apertura del gavone (4, 6, 12), ripiani dell'anta a un terzo e due terzi,
bastone 7 cm sotto il piano, fori maniglia a 10 e 12 dal bordo, giochi delle casse
dei cassetti (1 e 3) e dell'antina (0.5 e 1), le tre ribalte. Potrebbero andare nei
vincoli di costruzione.
""")

problema("6. L'ultimo gradino", """
Il passo tra i gradini è 20.1; dall'ultimo gradino (86.4) al bordo della nicchia
(131) ci sono 44.6 cm. Non è cambiato: da tenere presente quando si decide il bordo
(con la cornice bassa a 33 diventa 50.6).
""", [("Prova: 6 gradini", "bassa.nGradini=6")])

nbText: """
### Ipotesi che ho fatto

- **Spazio ai lati dei gradini 6.5**: la media di 7.5 e 5.5, così cassetti e anta
  stretta restano dove erano.
- **Ribalte larghe 68**: lo spazio tra loro è esattamente la soglia di 4.
- **Il divisorio a filo della risega** (lato nicchia): così il rivestimento della
  risega e il divisorio stanno sullo stesso piano e il comodino è lungo quanto la
  risega. Prima il divisorio era centrato sulla divisione del disegno.
- **Gioco di montaggio 0** per ora (vedi il punto 3).
- **Lo spazio minimo di 4** vale per le ribalte e anche tra cassetti e anta stretta.
- **Cornice destra misurata dalla risega**: 16.7, quasi come la sinistra (16).
- Tolto lo spazio sotto il materasso (`rete`, era 0): il materasso poggia sulla base.
- I vani si misurano dal comodino al sotto del soffitto della nicchia: 32.5 ciascuno.

### I problemi della prima bozza

| | Problema | Ora |
| --- | --- | --- |
| 1 | il piano letto non segue il fronte | la fascia si calcola dalla base letto e dalla cornice; le ante si misurano da terra, con un controllo |
| 2 | bordo di 10 cm | controllo soft ≥ 16, scatta: punto 1 qui sopra |
| 3 | l'altezza è un risultato | risolto: è quella della stanza |
| 4 | la larghezza muove solo la colonna | ribalte e spazio cassetti–anta stretta prendono il resto; la nicchia è misurata dai muri |
| 5 | testata scritta a mano | risolto: testata dalla base letto, schienale calcolato (≥ 40) |
| 6 | comodino a filo della risega per caso | risolto: per costruzione |
| 7 | doppioni | risolti (corsa del tavolino, colonna = risega); restano i numeri nascosti, punto 5 |
| 8 | ultimo gradino | invariato, punto 6 |
| 9 | anta stretta non sotto la colonna | invariato, come deciso |
| 10 | valori che rompono il modello | nuovi controlli; nel banco i valori impossibili sono tenuti nei limiti |
| 11 | stato del disegno nei parametri | risolto: gruppo `disegno` |
"""

nbText: """
## Le quote

La tavola di oggi è quella di prima, con le stesse quote. La tavola proposta quota
proprio i parametri nuovi: in alto la cornice della nicchia (16 dal muro, 16.7 dalla
risega) e la risega (38.8); nella sezione della nicchia base letto (104), altezza
della nicchia (159.2) e la cornice bassa divisa in materasso e bordo (17 + 10); nella
sezione della colonna la testata (58) con lo schienale (41) e i vani. Le due tavole
seguono il banco.
"""

nbRawHtml: """<h3>La tavola di oggi</h3>
<section class="tavola tavola-box"><button type="button" id="scarica-tavola" hidden></button><div id="tavola-attuale"></div></section>
<h3>La tavola proposta</h3>
<p>Prospetto con le catene orizzontali (colonne basse sotto; cornice della nicchia,
risega e ribalte sopra); una sezione <b>nella nicchia</b> con base letto, materasso,
bordo, apertura e altezza della nicchia; una sezione <b>nella colonna</b> con testata,
schienale e vani; in pianta risega, materasso con il suo gioco e scaffali.</p>
<div class="tavola-box" id="tavola-proposta"></div>"""

# la carta da parati del visore (vedi visore3d.nim)
let cartaFile = currentSourcePath().parentDir.parentDir / "tools" / "carta-da-parati.jpg"
let cartaSrc = if fileExists(cartaFile): "data:image/jpeg;base64," & encode(readFile(cartaFile)) else: ""

nbText: """
## Parametri cambiati

I parametri del banco diversi dal rilievo. **Copia** mette negli appunti una riga per
parametro (`- gruppo.campo (etichetta): prima → dopo`): incollata in una richiesta
basta a fare la PR che cambia i valori di default (`rilievo()`). **Incolla** fa il
contrario: riparte dal rilievo e applica le righe incollate (vanno bene anche righe
`campo = valore`).
"""

nbRawHtml: """<section class="cambiati" id="parametri-cambiati">
  <div class="testa"><span id="n-cambiati-fondo">valori del rilievo</span><span class="azioni"><button type="button" id="copia">Copia</button><button type="button" id="incolla">Incolla</button><a href="#banco">↑ al banco</a></span></div>
  <div id="elenco-cambiati"></div>
  <div class="incolla" id="box-incolla" hidden><textarea id="testo-incolla" rows="5" placeholder="Incolla qui l'elenco copiato (righe campo: prima → dopo, oppure campo = valore)"></textarea><div><button type="button" id="applica">Applica</button> <button type="button" id="annulla-incolla">Annulla</button> <small id="esito-incolla"></small></div></div>
</section>"""

nbRawHtml: """<script type="importmap">
{"imports": {"three": "./three/build/three.module.min.js",
  "three/addons/": "./three/examples/jsm/"}}
</script>
<script type="module">
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
window.THREE = { ...THREE, OrbitControls };
window.dispatchEvent(new Event('three-pronto'));
</script>"""

nbJsFromCode(cartaSrc):
  import ../src/cadero/visore, ../docsrc/banco_parametri
  avviaBanco(Carta(src: cartaSrc, w: 106, h: 52.6))

nbSave
