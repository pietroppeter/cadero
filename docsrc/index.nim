## Indice dei documenti di Caderò (-> docs/index.html, la home di Pages).
import nimib, tema

nbInit(theme = useTema)
nb.title = "Caderò"

nbText: """
# Caderò

Un mini CAD in Nim per progettare mobili fatti di pannelli. Ogni mobile è una
funzione dei suoi parametri: dagli stessi numeri escono disegni quotati, vista 3D
e distinta dei pezzi. Il primo esempio è una parete attrezzata con nicchia letto.
"""

nbRawHtml: """
<div class="schede">
  <a class="scheda" href="parete_nicchia.html">
    <b>Parete con nicchia letto</b>
    <span>La tavola ridisegnata da codice: prospetto frontale, vista laterale e
    pianta con le quote, vista 3D, una variante con misure diverse, distinta dei
    pezzi ed elenco delle ipotesi da verificare.</span>
  </a>
  <a class="scheda" href="visore3d.html">
    <b>Visore 3D</b>
    <span>La parete a tutto schermo da ruotare e zoomare, con viste predefinite
    (anche da dentro la nicchia), cassetto aperto e fronte nascosto.</span>
  </a>
  <a class="scheda" href="parametri.html">
    <b>I parametri della parete</b>
    <span>Bozza per la revisione: tutti i parametri, come dipendono l'uno
    dall'altro, i problemi trovati, le proposte e le quote, con il visore 3D che
    cambia muovendo i cursori.</span>
  </a>
  <a class="scheda" href="visore_nim.html">
    <b>Come è fatto il visore 3D</b>
    <span>Come funziona il visore e come è passato da JavaScript a Nim compilato
    in JavaScript: binding di three.js, il blocco nbJsFromCode, la verifica.</span>
  </a>
  <a class="scheda" href="come_funziona.html">
    <b>Come funziona Caderò</b>
    <span>Il codice spiegato passo passo con un comodino d'esempio: parti,
    proiezioni, quote, parametri, la parete vera, distinta e 3D.</span>
  </a>
</div>
"""

nbText: """
Il codice è su [GitHub](https://github.com/pietroppeter/cadero).
"""

nbSave
