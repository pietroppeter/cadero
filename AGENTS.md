# Note per chi lavora su Caderò (persone e agenti)

## Il progetto

Mini CAD in Nim per mobili fatti di pannelli, esplorato con documenti nimib.
Il primo (e per ora unico) mobile è la parete con nicchia letto in `models/parete.nim`.
Pietro è nuovo al CAD: il codice deve restare piccolo e leggibile, commentato in italiano.

## Convenzioni

- Lingua: italiano per commenti, documenti, commit e PR.
- Ogni volta che si aggiornano i commit di una PR, si aggiorna anche il suo testo
  perché descriva lo stato attuale del branch (regola del progetto).
- Unità: centimetri. Assi: `x` larghezza (da sinistra guardando il fronte),
  `y` profondità (0 sul fronte, verso il muro), `z` altezza (0 a terra).
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
- Nel visore "Esploso" allontana i pezzi dal centro; le parti con lo stesso `gruppo`
  restano unite. "Sezioni" disegna in SVG, nel browser, pianta, sezione laterale e
  sezione frontale ai tagli scelti con i cursori (codice in `src/cadero/visore.nim`).
- Il visore 3D è Nim compilato in JavaScript: `src/cadero/visore.nim` (logica),
  `src/cadero/js/three.nim` (binding minimi di three.js, solo quello che serve, con i
  nomi di three.js), `src/cadero/js/pagina.nim` (browser). La pagina è il documento
  nimib `docsrc/visore3d.nim`: un blocco `nbJsFromCode` calcola i modelli nel browser
  con `parete(...)` e chiama `avviaVisore`. Il file del blocco nimib lo compila in
  `docs/`, per questo gli import cominciano con `../`. Nei cicli che creano closure
  (pulsanti) serve `closureScope:` con una copia della variabile. Spiegazione in
  `docsrc/visore_nim.nim`. Un binding three.js nuovo va in `js/three.nim`.
- Un pannello orizzontale con un'apertura (il comodino) usa `holesPiano`: rettangoli
  nel piano x, y (nel `RRect`, `z` e `h` valgono come y e profondità). Solo il 3D li disegna.
- La carta da parati del visore è `tools/carta-da-parati.jpg` (una piastrella del motivo,
  106 × 52.6 cm, Vårklockor di Josef Frank); se manca il pulsante non compare.
- Le varianti sono funzioni sui parametri (es. `rilievo().conTavolino`); il visore 3D
  riceve un modello per variante, calcolato nel browser nel blocco `nbJsFromCode` di
  `docsrc/visore3d.nim` (tabella `varianti`).
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
models/parete_parametri.nim  gruppi dei parametri per le pagine (etichette, intervalli,
                         origine), misure derivate, schema delle catene, tavola proposta.
                         Un parametro nuovo di Parete va aggiunto anche qui.
docsrc/index.nim         indice dei documenti, home di Pages (-> docs/index.html)
docsrc/parete_nicchia.nim documento della parete (-> docs/parete_nicchia.html)
docsrc/come_funziona.nim spiegazione del codice (-> docs/come_funziona.html)
docsrc/visore3d.nim      il visore 3D (-> docs/visore3d.html), template tools/visore3d.tpl.html
docsrc/visore_nim.nim    come funziona il visore in Nim (-> docs/visore_nim.html)
docsrc/parametri.nim     i parametri della parete (-> docs/parametri.html): banco con visore
                         e cursori (docsrc/banco_parametri.nim, solo JS)
docsrc/all_docs.nim      importa tutti i documenti: un solo binario
docsrc/tema.nim          tema nimib con lo stile degli artefatti (nbInit(theme = useTema))
tests/test_parete.nim    controlli sulle quote della tavola di riferimento
tests/tavola.nim         prova veloce senza nimib: scrive tavola.svg e parete3d.html
tools/visore3d.nim       da docs/visore3d.html all'artefatto claude.ai (tools/parete-3d.html)
```

## Comandi

```sh
nimble install -y nimib
nimble test                      # nim c -r tests/test_parete.nim
nimble docs                      # nim r docsrc/all_docs.nim: tutto docs/ con una compilazione
nim r docsrc/visore3d.nim        # solo il visore: docs/visore3d.html (compila anche con nim js)
nim r tools/visore3d.nim         # dopo: tools/parete-3d.html per l'artefatto (senza doctype)
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
- Il visore 3D carica three.js 0.160.0 da `cdn.jsdelivr.net/npm` con un importmap:
  è consentito negli artefatti; un piccolo modulo lo mette in `window.THREE` e manda
  l'evento "three-pronto" per il codice Nim. Template in `tools/visore3d.tpl.html`,
  viste predefinite (anche "dentro la nicchia") in `vista(nome)` di `src/cadero/visore.nim`.
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
Per provare il 3D in Chromium headless senza CDN: `npm pack three@0.160.0` e
instradare le richieste jsdelivr ai file locali (Playwright `page.route`).
