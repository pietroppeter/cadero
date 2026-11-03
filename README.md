# Caderò

Mini CAD in Nim per progettare mobili fatti di pannelli, sperimentando con documenti
[nimib](https://github.com/pietroppeter/nimib).

Il primo esempio ridisegna da codice una parete attrezzata con nicchia letto:
prospetto frontale, vista laterale e pianta con le quote, vista 3D interattiva e
distinta dei pezzi.

## Documenti

Generati con nimib da `docsrc/` e pubblicati su GitHub Pages. Si parte
dall'[indice](https://pietroppeter.github.io/cadero/) (sorgente:
[`docsrc/index.nim`](docsrc/index.nim)); ogni documento ha in testa il link
"← Indice" per tornarci.

- [Parete con nicchia letto](https://pietroppeter.github.io/cadero/parete_nicchia.html): tavola con
  prospetto, laterale e pianta, vista 3D, una variante, distinta e ipotesi
  (sorgente: [`docsrc/parete_nicchia.nim`](docsrc/parete_nicchia.nim))
- [Come funziona Caderò](https://pietroppeter.github.io/cadero/come_funziona.html):
  spiegazione del codice passo passo, con esempi eseguiti
  (sorgente: [`docsrc/come_funziona.nim`](docsrc/come_funziona.nim))
- [Visore 3D](https://pietroppeter.github.io/cadero/visore3d.html): la parete a
  tutto schermo, da ruotare e zoomare, con viste predefinite anche da dentro la
  nicchia; cassetti, ante, ribalte e tavolino si aprono toccandoli; esploso e
  sezioni (pianta, laterale, frontale) con i piani di taglio scelti a mano
  (sorgente: [`docsrc/visore3d.nim`](docsrc/visore3d.nim), il visore in Nim
  compilato in JavaScript [`src/cadero/visore.nim`](src/cadero/visore.nim) e la
  pagina [`tools/visore3d.tpl.html`](tools/visore3d.tpl.html))
- [I parametri della parete](https://pietroppeter.github.io/cadero/parametri.html):
  bozza per la revisione dei parametri e delle quote, con il visore 3D e un cursore
  per ogni parametro (sorgente: [`docsrc/parametri.nim`](docsrc/parametri.nim),
  cursori in [`docsrc/banco_parametri.nim`](docsrc/banco_parametri.nim), descrizione
  dei parametri in [`models/parete_parametri.nim`](models/parete_parametri.nim))
- [Come è fatto il visore 3D](https://pietroppeter.github.io/cadero/visore_nim.html):
  come funziona il visore e come è passato da JavaScript a Nim (binding di three.js,
  blocco `nbJsFromCode`) (sorgente: [`docsrc/visore_nim.nim`](docsrc/visore_nim.nim))

I documenti hanno lo stesso tema (colori, caratteri, modo chiaro/scuro) degli
artefatti: lo stile è in [`docsrc/tema.nim`](docsrc/tema.nim).

## Come è fatto

```
src/cadero.nim            la libreria (esporta i tre moduli sotto)
src/cadero/model.nim      parti (scatole), mobile, distinta
src/cadero/drawing.nim    viste 2D e catene di quote in SVG
src/cadero/web.nim        vista 3D piccola per i documenti (JSON + three.js)
src/cadero/visore.nim     il visore 3D, in Nim compilato in JavaScript
src/cadero/js/            binding di three.js e del browser per il visore
models/parete.nim         il mobile: parametri + funzione che crea le parti + quote
models/parete_parametri.nim i parametri descritti: gruppi, origine, derivate, quote proposte
docsrc/index.nim          l'indice dei documenti
docsrc/parete_nicchia.nim il documento della parete
docsrc/come_funziona.nim  la spiegazione del codice
docsrc/visore3d.nim       la pagina del visore 3D (blocco nbJsFromCode)
docsrc/visore_nim.nim     come funziona il visore in Nim
docsrc/parametri.nim      i parametri della parete, con il banco (visore + cursori)
docsrc/all_docs.nim       tutti i documenti in un solo binario (va aggiornato con i nuovi)
docsrc/tema.nim           il tema dei documenti (stesso stile degli artefatti)
tools/visore3d.tpl.html   stile e pulsanti del visore
tools/visore3d.nim        dalla pagina del visore all'artefatto claude.ai
tests/test_parete.nim     controlli sulle misure
```

L'idea di fondo: un mobile è una funzione dei suoi parametri. `parete(rilievo())`
restituisce una lista di parti; viste, quote, 3D e distinta leggono quella lista.
Cambi un parametro, rigeneri, e tutto si aggiorna insieme.

Assi, in cm: `x` larghezza (da sinistra, guardando il mobile), `y` profondità
(0 sul fronte), `z` altezza (0 sul pavimento).

## Uso

```sh
nimble install -y nimib
nimble test        # controlli sulle misure
nimble docs        # genera docs/: indice, documenti e visore3d.html
```

Per una prova senza nimib: `nim c -r tests/tavola.nim` scrive `tavola.svg` e
`parete3d.html` nella cartella `tests/`.
