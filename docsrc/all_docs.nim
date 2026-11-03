## Tutti i documenti in un solo binario: una compilazione invece di una per
## documento, che in CI è la parte lenta. Ogni modulo importato genera il suo
## HTML in docs/ quando viene inizializzato (il visore 3D compila in più il
## suo blocco Nim in JavaScript, con `nim js`).
##
##   nim r docsrc/all_docs.nim
##
## Ogni documento nuovo in docsrc/ va aggiunto qui (e all'indice).
import index, parete_nicchia, come_funziona, visore3d, visore_nim
