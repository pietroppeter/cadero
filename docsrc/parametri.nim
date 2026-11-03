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

Con il visore in Nim il modello si calcola nel browser: si possono muovere i
parametri e vedere subito il mobile cambiare. Muovendoli si vede anche che **non
sono impostati nel modo giusto**: alcuni numeri che dovrebbero seguirsi sono
indipendenti, altri sono scritti a mano due volte, e l'altezza totale è un
risultato quando invece la decide il muro.

Questa pagina è una **bozza per la revisione**. Spiega tutti i parametri di oggi,
da dove vengono e come dipendono l'uno dall'altro; poi elenca i problemi trovati e
propone come riorganizzarli, insieme alle quote da mettere in tavola. Il modello
qui sotto è ancora quello di oggi: nulla è stato cambiato.

Nel banco ogni gruppo di parametri ha i suoi cursori; i valori cambiati rispetto al
rilievo diventano arancio. Sopra i cursori compaiono gli avvisi (`controlli` del
modello). Nei problemi più sotto i pulsanti ▶ **Prova** impostano i valori che
mostrano il difetto e riportano al banco.
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
      <div class="group" hidden>
        <button id="m-base" type="button" aria-pressed="true"></button><button id="m-tavolino" type="button"></button>
        <button id="m-antina" type="button"></button><button id="m-prese" type="button"></button><button id="m-risega" type="button"></button>
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
        <button id="t-sezioni" type="button" aria-pressed="false">Sezioni</button>
      </div>
    </div>
    <div class="sezioni" id="sezioni" hidden>
      <div class="taglio" data-vista="pianta"><div class="riga2"><h2>Pianta</h2><button type="button" class="scarica">SVG</button></div>
        <label>Taglio a <input type="range" step="1"> <output></output></label><svg aria-label="Pianta"></svg></div>
      <div class="taglio" data-vista="laterale"><div class="riga2"><h2>Sezione laterale</h2><button type="button" class="scarica">SVG</button></div>
        <label>Taglio a x = <input type="range" step="1"> <output></output></label><svg aria-label="Sezione laterale"></svg></div>
      <div class="taglio" data-vista="prospetto"><div class="riga2"><h2>Sezione frontale</h2><button type="button" class="scarica">SVG</button></div>
        <label>Taglio a y = <input type="range" step="1"> <output></output></label><svg aria-label="Sezione frontale"></svg></div>
    </div>
  </div>
  <div class="pannello">
    <div class="testa"><span id="n-cambiati">valori del rilievo</span><button type="button" id="ripristina">Torna al rilievo</button></div>
    <div class="avvisi" id="avvisi"></div>
    <div id="controlli"></div>
  </div>
</section>
<style>
.sezioni { display: grid; gap: 10px; } .sezioni[hidden] { display: none; }
.taglio { background: var(--paper); border: 1px solid var(--line); border-radius: 6px; padding: 8px 10px; display: grid; gap: 6px; }
.taglio h2 { margin: 0; padding: 0; border: 0; font-size: 18px; cursor: pointer; } .taglio .riga2 { display: flex; justify-content: space-between; align-items: center; }
.taglio label { display: flex; gap: 8px; align-items: center; font-size: 13px; color: var(--muted); }
.taglio input[type=range] { flex: 1; accent-color: var(--accent); }
.taglio svg { width: 100%; height: auto; max-height: 60vh; background: #fff; margin: 0; }
.taglio.scelta { border-color: #e04a2f; }
</style>"""

nbText: """
## Le misure che ne vengono fuori

Le misure derivate si calcolano dai parametri: qui con la formula, aggiornate dal
banco. In rosso quelle che segnalano qualcosa che non va (la soglia è scritta nel
problema corrispondente). Accanto, le **due catene verticali**: a sinistra quella
del fronte, che decide dove stanno i frontali; a destra quella di dentro (piano
letto, materasso, schienale, vani della libreria). Oggi le due catene si toccano
solo per caso: in arancio i punti dove dovrebbero essere legate.
"""

nbRawHtml: """<div id="derivate"></div><div class="catene-box" id="catene"></div>"""

nbText: """
## I parametri di oggi

Sono i campi dell'oggetto `Parete` in `models/parete.nim`, con i valori di
`rilievo()`. La colonna *origine* dice da dove viene il numero:
**disegno** (scritto sulla tavola di riferimento), **rilevato** (misurato in scala
1:25, dove un millimetro di carta sono 2.5 cm), **deciso** (da Pietro),
**ipotesi** (inventato, da verificare), **variante** (sì/no) e **doppione**
(scritto a mano ma si potrebbe calcolare).
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

var stato = "<h3>Non sono parametri del mobile</h3><p>Tre campi di <code>Parete</code> dicono solo come " &
  "disegnare la tavola; nel visore non servono (lì si apre toccando).</p><table class=\"parametri\"><tbody>"
for (campo, cosa) in statoDisegno(): stato.add "<tr><td><code>" & campo & "</code></td><td>" & cosa & "</td></tr>"
stato.add "</tbody></table>"
nbRawHtml: stato

nbText: """
## Problemi

Ordinati per importanza. Ogni problema ha uno o più pulsanti per vederlo nel banco.
"""

proc problema(titolo, testo: string; prove: openArray[(string, string)] = []) =
  var h = "<div class=\"problema\"><h3>" & titolo & "</h3>"
  h.add markdown(testo)
  for (etichetta, valori) in prove:
    h.add "<button type=\"button\" class=\"prova\" data-prova=\"" & valori & "\">" & etichetta & "</button>"
  h.add "</div>"
  nbRawHtml: h

let c = p.catenaFronte

problema("1. Il piano letto non segue il fronte", """
`pianoLetto` (104) è un parametro libero, mentre la base della nicchia (131) è la
somma di zoccolo, zona bassa e fascia. Le due cose devono stare insieme: sotto il
piano letto finiscono i frontali della zona bassa (oggi c'è 1.2 cm di aria tra i
frontali e il piano), sopra il piano c'è il materasso e il bordo della fascia.
Se alzi la zona bassa i frontali entrano nel piano letto; se alzi il piano letto
il materasso esce sopra il bordo.
""", [("Prova: zona bassa 110", "zonaBassa=110"), ("Prova: piano letto 115", "pianoLetto=115")])

problema("2. Il bordo sopra il materasso è di soli " & fmtNum(c[3] - p.sopraMaterasso) & " cm", """
La fascia arriva a 131; il materasso (17) sul piano letto (104) arriva a 121.
Restano 10 cm di bordo davanti a chi dorme, a 1.3 m da terra. Per i letti a
castello la norma europea (EN 747) chiede una sponda di almeno 16 cm sopra il
materasso: non è un letto a castello, ma è un buon riferimento. Con il materasso
di prima, più spesso, il bordo era ancora più basso. Oggi il bordo non è un
parametro: è il risultato di quattro numeri indipendenti.
""", [("Prova: materasso 22", "materasso.2=22"), ("Prova: fascia 36 (bordo 16)", "fascia=36")])

problema("3. L'altezza è un risultato, ma la decide il muro", """
Il mobile va da muro a muro e da pavimento a soffitto, quindi altezza, larghezza e
profondità sono il **rilievo del vano**: si misurano, non si scelgono. Oggi
l'altezza è la somma delle sette fasce del fronte: se allunghi la fascia per avere
un bordo più alto, il mobile diventa più alto del soffitto. Una catena chiusa ha
bisogno di una fascia che prende il resto (per esempio il margine in alto o le
ribalte alte).
""", [("Prova: fascia 36 → altezza 322", "fascia=36")])

problema("4. La larghezza muove solo la colonna destra", """
Le ribalte alte si dividono la larghezza, ma le quattro colonne basse e la nicchia
hanno larghezze proprie: la loro somma (con margini e spazi) fa 237 per come sono
stati rilevati i numeri, non perché sia scritto da qualche parte. Cambiando la
larghezza, l'ultima colonna bassa non arriva più al margine e la nicchia non resta
centrata nella sua campata. Servirebbe una colonna che prende il resto (per esempio
l'anta sinistra) e la nicchia centrata con un margine.
""", [("Prova: larghezza 250", "larghezza=250"), ("Prova: colonna destra 45", "colonnaDx=45")])

problema("5. Testata 58: la decisione era 41 sopra il materasso", """
Si è deciso che lo schienale sporga 41 cm sopra il materasso. Nel codice però c'è
`testata = 58`, cioè 17 + 41 fatto a mano, e un controllo che avvisa se lo
schienale esce da 40–42. Cambiando il materasso lo schienale cambia. Il parametro
giusto è lo schienale; la testata (e quindi comodino e libreria) si calcola.
""", [("Prova: materasso 20", "materasso.2=20")])

problema("6. Comodino a filo della risega per coincidenza", """
La profondità del comodino è `colonnaDx − s/2` = 37.9, la risega è larga 38: sono
a filo perché i due numeri vengono da fonti diverse (il disegno e le note) e per
caso quasi coincidono. Cambiando lo spessore o la colonna non lo sono più, e
c'è solo un avviso. Una delle due misure dovrebbe comandare l'altra: per esempio
la colonna larga quanto la risega più mezzo spessore.
""", [("Prova: risega larga 45", "risegaLarga=45"), ("Prova: spessore 2.5", "spessore=2.5")])

problema("7. Numeri scritti due volte, e numeri nascosti nel codice", """
- `corsaTavolino` (78.6) è `profTavolino + spessore`, scritto a mano; `profTavolino`
  (76.8) è la profondità meno lo spessore e 1.4 di gioco, anche lui a mano.
- `corsa` dei cassetti (60) non segue `profCassetti` (75); e `profCassetti` vale
  anche per la scatola dell'anta sinistra, che non è un cassetto.
- Dentro `parete(p)` ci sono una ventina di numeri senza nome: i margini
  dell'apertura del gavone (4, 6, 12), i ripiani dell'anta a un terzo e due terzi,
  il bastone 7 cm sotto il piano, i fori maniglia a 10 e 12 dal bordo, i giochi
  delle casse (1 e 3), dell'antina (0.5 e 1), le tre ribalte, la corsa dei coperchi (14)
  e del materasso. Muovendo i parametri questi restano fermi.
- `hGradino`, `hC` (altezza dei cassetti) e `wAlto` (ribalte) sono calcolati dentro
  `parete(p)`: per mostrarli qui ho dovuto riscrivere le formule.
""", [("Prova: profondità 70", "profondita=70")])

problema("8. Dall'ultimo gradino al bordo ci sono " & fmtNum(c[3] - (c[1] + float(p.nGradini - 1) * (p.hGradino + p.passoGradini))) & " cm", """
Il passo tra i gradini è 20.1 cm (14.6 di foro più 5.5), comodo. Ma l'ultimo
gradino ha il piede a 86.4 e il bordo della nicchia è a 131: l'ultimo salto è più
del doppio degli altri, e sopra c'è anche il bordo da scavalcare. Il passo vero non
è un parametro (lo è lo spazio tra i fori): con un parametro "passo" si potrebbe
chiedere che i gradini arrivino fino alla fascia, o vedere subito quanto manca.
""", [("Prova: 6 gradini", "nGradini=6")])

problema("9. L'anta stretta non sta sotto la colonna", """
La colonna destra comincia a 198.2, l'anta stretta sotto va da 186 a 224.5: le
colonne basse sono disegnate sul fronte, la colonna sopra sulla struttura. Sotto il
piano letto non c'è il divisorio, quindi si costruisce lo stesso, ma vanno decise:
è voluto (proporzioni del fronte) o l'anta va allineata alla colonna?
""")

problema("10. Valori che rompono il modello", """
Con un solo vano in libreria `parete(p)` si ferma (cerca il primo ripiano che non
c'è); con i gradini del tavolino pari ai gradini, o zero cassetti, i conti escono
sbagliati. Qui i cursori hanno limiti e `sicuro(p)` tiene i valori dentro, ma il
modello dovrebbe controllarli da solo e dirlo negli avvisi.
""")

problema("11. Stato del disegno mescolato ai parametri", """
`cassettoAperto`, `tavolinoAperto` e `antinaAperta` stanno in `Parete` ma
descrivono la tavola, non il mobile. Starebbero meglio come opzioni della tavola.
""")

nbText: """
## Proposte

### Cinque famiglie di parametri

1. **Rilievo del vano**: larghezza, altezza, profondità, risega (sporgenza e
   larghezza). Si misurano nella stanza; tutto il resto si adatta.
2. **Scelte di progetto**: le misure che contano per chi usa il mobile, scritte
   come le si dice: piano letto da terra, materasso, **bordo sopra il materasso**,
   **schienale sopra il materasso**, apertura della nicchia, ribalte alte, numero
   di vani, gradini e cassetti, spessore.
3. **Derivate**: quello che si calcola. Ogni catena ha una fascia "resto" che la
   chiude: per esempio `zonaBassa = pianoLetto − s − zoccolo − gioco`,
   `fascia = pianoLetto + rete + materasso + bordo − (zoccolo + zonaBassa)`,
   `margineAlto = altezza − tutto il resto`, `testata = rete + materasso + schienale`,
   `corsaTavolino = profTavolino + s`, l'anta sinistra = la larghezza che avanza.
   Diventano procedure con nome (`hGradino`, `wRibalta`...), usate sia dal modello
   sia dalle tavole.
4. **Giochi e dettagli costruttivi**: i numeri oggi nascosti in `parete(p)`, con
   nome e valore di default, in un oggetto a parte (si toccano di rado).
5. **Opzioni**: tavolino, antina, risega scoperta, prese sul comodino. Più, fuori
   dai parametri, lo stato del disegno (cosa è aperto nella tavola).

### Altre cose

- `controlli(p)` diventa anche la validazione: segnala i valori che non si possono
  costruire invece di far cadere il modello.
- Per i numeri rilevati in scala (12.5, 3.75, 165.5, 7.5/5.5/8.5...) decidere
  quali sono intenzioni (spazi uguali? nicchia centrata?) e scriverli così.
- Nel banco: ricordare i valori nel link, per mandare una variante a qualcuno.

### Da decidere insieme

- Chi comanda in basso: **l'altezza del piano letto** (e la zona bassa si adatta) o
  la zona bassa (e il letto si adatta)? Io proporrei il piano letto.
- Il **bordo sopra il materasso**: 16 cm (norma dei letti a castello) o altro?
- Quale fascia prende il resto in alto: margine alto o ribalte?
- L'altezza 316 del disegno è misurata nella stanza?
- L'anta stretta: allineata alla colonna o no?
"""

nbText: """
## Le quote

La tavola di oggi ripete quelle del disegno di riferimento, più le nuove della
libreria. Funzionano per controllare il disegno, ma mancano alcune misure che
servono davvero:

- nel prospetto c'è solo la catena verticale e la larghezza totale: mancano le
  **catene orizzontali** dei frontali (colonne basse, nicchia e colonna, ribalte);
- la vista laterale è tagliata nella colonna, quindi le misure di chi dorme
  (**bordo sopra il materasso**, **altezza libera**) non si vedono; la quota 131 è
  presa dal fronte e messa nella sezione;
- lo **schienale di 41**, la decisione, non è quotato: c'è 162 da terra;
- la **risega** (7 × 38) e la profondità della colonna (73) non sono quotate.

Proposta: tre gruppi di quote. *Ingombro* (L, H, P, risega) per confrontarle con la
stanza; *uso* (piano letto, materasso, bordo, altezza libera, schienale, vani,
gradini) per chi decide; *costruzione* (catene dei frontali, profondità delle
scatole) per chi taglia i pannelli, magari in una tavola a parte con la distinta.
Le due tavole qui sotto seguono il banco.
"""

nbRawHtml: """<h3>La tavola di oggi</h3>
<section class="tavola tavola-box"><button type="button" id="scarica-tavola" hidden></button><div id="tavola-attuale"></div></section>
<h3>La tavola proposta</h3>
<p>Prospetto con le catene orizzontali (colonne basse sotto; nicchia, colonna e
ribalte sopra); una sezione <b>nella nicchia</b> con piano letto, materasso, bordo,
altezza libera e soffitto; una sezione <b>nella colonna</b> con materasso,
schienale 41 e vani; in pianta anche risega, larghezza del materasso e scaffali.</p>
<div class="tavola-box" id="tavola-proposta"></div>"""

# la carta da parati del visore (vedi visore3d.nim)
let cartaFile = currentSourcePath().parentDir.parentDir / "tools" / "carta-da-parati.jpg"
let cartaSrc = if fileExists(cartaFile): "data:image/jpeg;base64," & encode(readFile(cartaFile)) else: ""

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
