# Note per chi lavora su Caderò (persone e agenti)

## Il progetto

Mini CAD in Nim per mobili fatti di pannelli, esplorato con documenti nimib.
Il mobile è la parete con nicchia letto in `models/parete.nim` (la nostra). Accanto c'è
`models/falegnami.nim`: la stessa parete come l'hanno disegnata i falegnami (7 tavole
SketchUp del 3 novembre 2026), divisa nei mobili da costruire; i due modelli restano
separati (la nostra non si tocca per il loro) e il documento `modello_falegnami` li confronta.
Pietro è nuovo al CAD: il codice deve restare piccolo e leggibile, commentato in italiano.

## Convenzioni

- Lingua: italiano per commenti, documenti, commit e PR.
- Ogni volta che si aggiornano i commit di una PR, si aggiorna anche il suo testo
  perché descriva lo stato attuale del branch (regola del progetto).
- Unità: centimetri. Assi: `x` larghezza (da sinistra guardando il fronte),
  `y` profondità (0 sul fronte, verso il muro), `z` altezza (0 a terra).
- I parametri della parete sono divisi in gruppi, un oggetto per gruppo (revisione di
  Pietro): `p.muro` (vincoli del muro: misure della stanza, massime, da cui parte
  tutto), `p.costruzione`, `p.altezze`, `p.materasso`, `p.libreria`, `p.cornice`,
  `p.bassa`, `p.alta`, `p.frontali`, `p.prese`, `p.tavolino` e `p.disegno` (solo cosa
  disegnare aperto). Ogni misura si prende da un riferimento (muro, risega, base letto,
  soffitto della nicchia); le altre si calcolano in procedure con nome (`altezza`,
  `nicchiaH`, `bordo`, `schienale`, `gapAlti`, `vani`...). Un parametro nuovo va
  descritto anche in `models/parete_parametri.nim` (cursori e tabelle).
- I vincoli soft (schienale ≥ 40, bordo ≥ 16, spazio tra frontali ≥ spazio minimo,
  vano minimo) sono in `controlli(p)`; `fuoriMuro(p, m)` verifica che niente esca dal muro.
- Il banco del documento `parametri` copia l'elenco dei parametri cambiati come righe
  `- gruppo.campo (etichetta): prima → dopo`. Se arriva una richiesta con un elenco
  così, i valori "dopo" vanno in `rilievo()` (aggiorna test e quote che ne dipendono).
- Un mobile = oggetto di parametri + funzione che restituisce un `Model`
  (lista di `Part`, scatole allineate agli assi) + funzione delle quote.
  Le misure derivate si calcolano (es. `altezza` = somma della catena del fronte),
  non si duplicano come parametri.
- Vincoli scritti in avanti come formule, niente risolutore.
- Misure non scritte sui disegni di Pietro: rilevarle in scala o fare un'ipotesi,
  commentarla nel parametro (`rilevato:` / `ipotesi:`) ed elencarla nella sezione
  "Ipotesi da verificare" di `docsrc/parete_nicchia.nim`. Non bloccarsi a chiedere:
  si rivede tutto insieme alla fine.
- Tipi di parte (`Kind`) e come appaiono nelle viste: vedi `src/cadero/drawing.nim`.
  `kWall` è il muro (es. la risega): si disegna tratteggiato, non va in distinta.
- Le parti apribili si segnano con `apribile(gruppo, apre, corsa)`: `apre` è "tira"
  (cassetti, tavolino), "sx"/"dx" (ante, lato della cerniera), "su" (ribalte) o "alza"
  (coperchi del gavone: si sollevano e si allontanano tra loro) o "solleva" (il
  materasso, sale per far vedere sotto). Nel
  visore tutto parte chiuso e si apre toccandolo; il perno è calcolato dal visore
  sullo spigolo del gruppo. Una parte disegnata aperta (y < 0) parte aperta.
- Nel visore "Esploso" separa i pezzi a strati in profondità (muro indietro, mobili
  allargati nel piano, fronte avanti, ante e cassetti più avanti, coperchi in alto):
  le parti con lo stesso `blocco` (un mobile) o `gruppo` restano unite; un gruppo
  apribile esce dritto dal mobile che lo contiene. Le sezioni del visore sono state
  tolte (Pietro: complicano); le sezioni stanno nelle tavole.
- Il visore 3D è Nim compilato in JavaScript: `src/cadero/visore.nim` (logica),
  `src/cadero/js/three.nim` (binding minimi di three.js, solo quello che serve, con i
  nomi di three.js), `src/cadero/js/pagina.nim` (browser). La pagina è il documento
  nimib `docsrc/visore3d.nim` (il modello dei falegnami, il default) o
  `docsrc/visore3d_idea.nim` (la nostra idea, "Visore 3D - Idea"), entrambe con il
  template riempito da `docsrc/pagina_visore.nim`: un blocco `nbJsFromCode` calcola i
  modelli nel browser e chiama `avviaVisore`, che parte da "base" se c'è, se no da
  "falegnami", e nasconde i pulsanti dei modelli che la pagina non ha. Il file del blocco nimib lo compila in
  `docs/`, per questo gli import cominciano con `../`. Nei cicli che creano closure
  (pulsanti) serve `closureScope:` con una copia della variabile. Spiegazione in
  `docsrc/visore_nim.nim`. Un binding three.js nuovo va in `js/three.nim`.
- Un pannello frontale diviso in pezzi (i quattro pannelli dei falegnami) si fa con
  `pannelloForato`: le aperture tutte dentro un pezzo sono fori, quelle che passano da un
  pezzo all'altro diventano tacche del contorno (`Part.contorno`, poligono nel piano x, z).
  Viste 2D, 3D e sezioni del visore usano il contorno; `pieni` dà i tratti pieni lungo un
  taglio. I pezzi del fronte si chiamano "fronte ..." (il pulsante "Pannello frontale" li
  nasconde tutti); solo la parte chiamata esattamente "fronte" riceve come fori le sagome
  dei frontali (`foriVisti`), perché nella nostra parete ante e cassetti stanno a filo.
- `Part.materiale = "melaminico"`: le scatole grigie dei falegnami (grigie nel visore).
- Un pannello orizzontale con un'apertura (il comodino) usa `holesPiano`: rettangoli
  nel piano x, y (nel `RRect`, `z` e `h` valgono come y e profondità). Solo il 3D li disegna.
- La carta da parati del visore è `tools/carta-da-parati.jpg` (una piastrella del motivo,
  106 × 52.6 cm, Vårklockor di Josef Frank); se manca il pulsante non compare.
- Le varianti sono funzioni sui parametri (es. `rilievo().conTavolino`); il visore 3D
  riceve un modello per variante, calcolato nel browser nel blocco `nbJsFromCode` di
  `docsrc/visore3d_idea.nim` / `docsrc/visore3d.nim` (tabella `varianti`).
- Le cose che non tornano (misure che non ci stanno, decisioni in conflitto) vanno in
  `controlli(p)` di `models/parete.nim`, mostrati nel documento: non si correggono
  i numeri di nascosto.
  Un nuovo tipo va gestito in `drawFront`/`drawSide`/`drawPlan`, in `web.nim` e in
  `visore.nim` (materiale three.js) e, se serve, nella distinta.

## Struttura

```
src/cadero/model.nim     parti, mobile, distinta
src/cadero/drawing.nim   proiezioni, catene di quote, foglio SVG (in cm)
src/cadero/web.nim       JSON + frammento HTML three.js per nimib (vista 3D piccola)
src/cadero/visore.nim    il visore 3D (solo backend JS)
src/cadero/js/           binding three.js (three.nim) e browser (pagina.nim)
models/parete.nim        parametri rilievo(), parete(p), quote(p), tavola(p, m)
models/falegnami.nim     il modello dei falegnami: falegnami(), modello(f), controlli, quote, tavola
models/parete_parametri.nim  gruppi dei parametri per le pagine (etichette, intervalli,
                         origine), misure derivate, schema delle catene, tavola proposta.
                         Un parametro nuovo di Parete va aggiunto anche qui.
docsrc/index.nim         indice dei documenti, home di Pages (-> docs/index.html)
docsrc/parete_nicchia.nim documento della parete (-> docs/parete_nicchia.html)
docsrc/come_funziona.nim spiegazione del codice (-> docs/come_funziona.html)
docsrc/visore3d.nim      il visore 3D dei falegnami (-> docs/visore3d.html), template tools/visore3d.tpl.html
docsrc/visore3d_idea.nim il visore della nostra idea (-> docs/visore3d_idea.html)
docsrc/pagina_visore.nim il renderer comune dei due visori (titolo, misure, tavola, note)
docsrc/visore_nim.nim    come funziona il visore in Nim (-> docs/visore_nim.html)
docsrc/parametri.nim     i parametri della parete (-> docs/parametri.html): banco con visore
                         e cursori (docsrc/banco_parametri.nim, solo JS)
docsrc/modello_falegnami.nim il modello dei falegnami (-> docs/modello_falegnami.html)
docsrc/all_docs.nim      importa tutti i documenti: un solo binario
docsrc/tema.nim          tema nimib con lo stile degli artefatti (nbInit(theme = useTema))
tests/test_parete.nim    controlli sulle quote della tavola di riferimento
tests/tavola.nim         prova veloce senza nimib: scrive tavola.svg e parete3d.html
tools/visore3d.nim       da docs/visore3d.html all'artefatto claude.ai (tools/parete-3d.html;
                         con argomento visore3d_idea: tools/parete-3d-idea.html)
```

## Comandi

```sh
nimble install -y nimib
nimble test                      # nim c -r tests/test_parete.nim
nimble docs                      # nim r docsrc/all_docs.nim: tutto docs/ con una compilazione
nim r docsrc/visore3d.nim        # solo il visore: docs/visore3d.html (compila anche con nim js)
nim r tools/visore3d.nim         # dopo: tools/parete-3d.html per l'artefatto (senza doctype)
nim r tools/visore3d.nim visore3d_idea   # idem per l'idea: tools/parete-3d-idea.html
```

`config.nims` aggiunge `src` e `models` al path; `nimib.toml` manda l'output in `docs/`
(ignorata da git: la pubblica la CI).

## CI e Pages

- `.github/workflows/docs.yml`: test, generazione dei documenti, deploy su Pages da `main`.
- Velocità: cache di `~/.nimble` (chiave: il `.nimble`) e di `~/.cache/nim`, `apt-get`
  solo se manca `libpcre3`, `nimble install` solo se manca nimib, tutti i documenti
  compilati in un solo binario (`docsrc/all_docs.nim`), niente CI per modifiche ai soli `.md`.
- Il job gira su `ubuntu-24.04`: nimib usa `std/re`, che richiede `libpcre3`,
  non più disponibile da Ubuntu 26.04.
- Pages va abilitato con sorgente "GitHub Actions".

## Artefatti claude.ai

- La pagina HTML di nimib non va pubblicata così com'è come artefatto: i CSS da CDN
  sono bloccati. Si prende il contenuto di `<main>`, si aggiunge un `<style>` proprio
  con i token chiaro/scuro (il codice è già colorato da nimib con classi `hljs-*`).
- three.js 0.160.0 è nel repository (`vendor/three/`, stessa struttura del pacchetto
  npm, solo `three.module.min.js` e `OrbitControls.js`): `copiaThree` lo copia in
  `docs/three/` e le pagine lo caricano da `./three/` con un importmap, senza CDN.
  Un piccolo modulo lo mette in `window.THREE` e manda l'evento "three-pronto" per
  il codice Nim. Pubblicando il visore come artefatto vanno passati anche i due file
  (`files` con `three/build/three.module.min.js` e
  `three/examples/jsm/controls/OrbitControls.js`). Template in `tools/visore3d.tpl.html`,
  viste predefinite in `vista(nome)` di `src/cadero/visore.nim`.
- Documenti e artefatti condividono lo stesso stile: token chiaro/scuro, Barlow
  Condensed / IBM Plex Sans / IBM Plex Mono. Se si cambia un colore, va cambiato in
  `docsrc/tema.nim` e in `tools/visore3d.tpl.html`. Il tema non carica CSS da CDN e
  disattiva highlight.js: il codice lo colora già nimib.
- Navigazione: `docs/index.html` è l'indice con una scheda per documento; il tema mette
  "← Indice" in testa a ogni documento, il visore ha lo stesso link. Un nuovo documento
  va aggiunto all'indice, a `docsrc/all_docs.nim` e al README. Non chiamare un
  documento come un modulo che importa (es. `parete.nim`): si importerebbe da solo.
- Pietro legge spesso da telefono: i disegni vanno mostrati come immagini o pagine,
  non come file SVG grezzi.

## Ambiente senza rete completa

Se `nimble`/nim-lang.org sono bloccati: Nim da apt, e nimib con le dipendenze
(fusion, nim-markdown, parsetoml, jsony) clonate da GitHub e passate con `--path`.
Per provare il 3D in Chromium headless: servire `docs/` con `python3 -m http.server`
(i moduli ES non si caricano da `file://`).
