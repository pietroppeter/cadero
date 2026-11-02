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
  "Ipotesi da verificare" di `docsrc/index.nim`. Non bloccarsi a chiedere:
  si rivede tutto insieme alla fine.
- Tipi di parte (`Kind`) e come appaiono nelle viste: vedi `src/cadero/drawing.nim`.
  Un nuovo tipo va gestito in `drawFront`/`drawSide`/`drawPlan`, in `web.nim`
  (materiale three.js) e, se serve, nella distinta.

## Struttura

```
src/cadero/model.nim     parti, mobile, distinta
src/cadero/drawing.nim   proiezioni, catene di quote, foglio SVG (in cm)
src/cadero/web.nim       JSON + frammento HTML three.js per nimib
models/parete.nim        parametri rilievo(), parete(p), quote(p), tavola(p, m)
docsrc/index.nim         documento della parete (-> docs/index.html)
docsrc/come_funziona.nim spiegazione del codice (-> docs/come_funziona.html)
docsrc/tema.nim          tema nimib con lo stile degli artefatti (nbInit(theme = useTema))
tests/test_parete.nim    controlli sulle quote della tavola di riferimento
tests/tavola.nim         prova veloce senza nimib: scrive tavola.svg e parete3d.html
tools/visore3d.nim       pagina del visore 3D: artefatto claude.ai o docs/visore3d.html
```

## Comandi

```sh
nimble install -y nimib
nimble test                      # nim c -r tests/test_parete.nim
nimble docs                      # genera docs/ (index, come_funziona, visore3d)
nim r tools/visore3d.nim         # tools/parete-3d.html per l'artefatto (senza doctype)
nim r tools/visore3d.nim docs/visore3d.html   # pagina completa per Pages
```

`config.nims` aggiunge `src` e `models` al path; `nimib.toml` manda l'output in `docs/`
(ignorata da git: la pubblica la CI).

## CI e Pages

- `.github/workflows/docs.yml`: test, generazione dei documenti, deploy su Pages da `main`.
- Il job gira su `ubuntu-24.04`: nimib usa `std/re`, che richiede `libpcre3`,
  non più disponibile da Ubuntu 26.04.
- Pages va abilitato con sorgente "GitHub Actions".

## Artefatti claude.ai

- La pagina HTML di nimib non va pubblicata così com'è come artefatto: i CSS da CDN
  sono bloccati. Si prende il contenuto di `<main>`, si aggiunge un `<style>` proprio
  con i token chiaro/scuro (il codice è già colorato da nimib con classi `hljs-*`).
- Il visore 3D carica three.js 0.160.0 da `cdn.jsdelivr.net/npm` con un importmap:
  è consentito negli artefatti. Template in `tools/visore3d.tpl.html`, viste
  predefinite (anche "dentro la nicchia") nell'oggetto `views`.
- Documenti e artefatti condividono lo stesso stile: token chiaro/scuro, Barlow
  Condensed / IBM Plex Sans / IBM Plex Mono. Se si cambia un colore, va cambiato in
  `docsrc/tema.nim` e in `tools/visore3d.tpl.html`. Il tema non carica CSS da CDN e
  disattiva highlight.js: il codice lo colora già nimib.
- Pietro legge spesso da telefono: i disegni vanno mostrati come immagini o pagine,
  non come file SVG grezzi.

## Ambiente senza rete completa

Se `nimble`/nim-lang.org sono bloccati: Nim da apt, e nimib con le dipendenze
(fusion, nim-markdown, parsetoml, jsony) clonate da GitHub e passate con `--path`.
Per provare il 3D in Chromium headless senza CDN: `npm pack three@0.160.0` e
instradare le richieste jsdelivr ai file locali (Playwright `page.route`).
