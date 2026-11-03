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
  (sorgente: [`tools/visore3d.tpl.html`](tools/visore3d.tpl.html) e
  [`tools/visore3d.nim`](tools/visore3d.nim))

I documenti hanno lo stesso tema (colori, caratteri, modo chiaro/scuro) degli
artefatti: lo stile è in [`docsrc/tema.nim`](docsrc/tema.nim).

## Come è fatto

```
src/cadero.nim            la libreria (esporta i tre moduli sotto)
src/cadero/model.nim      parti (scatole), mobile, distinta
src/cadero/drawing.nim    viste 2D e catene di quote in SVG
src/cadero/web.nim        vista 3D con three.js
models/parete.nim         il mobile: parametri + funzione che crea le parti + quote
docsrc/index.nim          l'indice dei documenti
docsrc/parete_nicchia.nim il documento della parete
docsrc/come_funziona.nim  la spiegazione del codice
docsrc/all_docs.nim       tutti i documenti in un solo binario (va aggiornato con i nuovi)
docsrc/tema.nim           il tema dei documenti (stesso stile degli artefatti)
tools/visore3d.nim        genera la pagina del visore 3D
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
