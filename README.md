# Caderò

Mini CAD in Nim per progettare mobili fatti di pannelli, sperimentando con documenti
[nimib](https://github.com/pietroppeter/nimib).

Il primo esempio ridisegna da codice una parete attrezzata con nicchia letto:
prospetto frontale, vista laterale e pianta con le quote, vista 3D interattiva e
distinta dei pezzi. Il documento pubblicato è su
<https://pietroppeter.github.io/cadero/>.

## Come è fatto

```
src/cadero.nim            la libreria (esporta i tre moduli sotto)
src/cadero/model.nim      parti (scatole), mobile, distinta
src/cadero/drawing.nim    viste 2D e catene di quote in SVG
src/cadero/web.nim        vista 3D con three.js
models/parete.nim         il mobile: parametri + funzione che crea le parti + quote
docsrc/index.nim          il documento nimib
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
nimble docs        # genera docs/index.html
```

Per una prova senza nimib: `nim c -r tests/tavola.nim` scrive `tavola.svg` e
`parete3d.html` nella cartella `tests/`.
