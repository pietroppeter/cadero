## Il modello dei falegnami (-> docs/modello_falegnami.html): le loro tavole
## ridisegnate da codice, il confronto con la nostra parete, i calcoli della
## nicchia, i mobili uno per uno e le cose da chiedere.
import nimib, tema
import std/[os, strutils]
import falegnami, falegnami_tavole

nbInit(theme = useTema)
nb.title = "Il modello dei falegnami"

nbText: """
# Il modello dei falegnami

**Due versioni.** La **v2** (16 novembre, il PDF "mobile letto") è quella di
riferimento e viene per prima; la **v1** (le prime tavole del 3 novembre) resta
in fondo, segnata v1, non più aggiornata.

È la stessa stanza e la stessa idea della [nostra parete](parete_nicchia.html),
ma divisa nei mobili che i falegnami costruiranno davvero, con molto dettaglio in più.
Qui è ridisegnata da codice in `models/falegnami.nim` (`falegnamiV2()` e
`falegnami()`), accanto alla nostra, che resta com'è. Nel [visore 3D](visore3d.html)
è il modello di default, con il pulsante **Versione** (v1 / v2); la nostra idea ha il
suo [Visore 3D - Idea](visore3d_idea.html).

Le loro misure sono in mm, qui in cm. Quelle scritte sulle tavole sono riportate
così come sono; quelle che mancano le ho misurate in scala sul prospetto
(rilevate) o ipotizzate: sono elencate nelle letture e ipotesi di ogni versione.
"""

nbText: """
## v2 · Il progetto aggiornato (16 novembre)

Il progetto aggiornato del 16 novembre, un PDF di sette tavole ("mobile letto").
**Questa è la versione di riferimento.** Contiene quasi tutte le decisioni prese
dopo la v1: il fronte in tre pezzi
orizzontali, la nicchia più aperta (15 da sinistra, 52 da destra), la testata alta,
niente pannellino tra i gradini, niente cornice nel fronte. Il pannello a L invece
no: sono due pannelli (vedi sotto). Le
misure nuove sono qui sotto; la [versione 1](#v1) (le prime tavole, 3 novembre, con
le nostre modifiche) resta in fondo, non più aggiornata. Nel [visore 3D](visore3d.html)
il pulsante **Versione** passa da una all'altra (si parte dalla v2).
"""

let tavoleV2 = [
  ("Il fronte, chiuso e aperto", "in prospettiva: a sinistra ante, cassetti e ribalte, a destra senza (si vedono i vani)"),
  ("Il prospetto", "il fronte di faccia, con tutte le misure: 2348 × 3176, tre pezzi da 1180, 978 e 1018"),
  ("Il cassone del letto", "visto da dietro: dentro 1934 × 1557, profondo 775; sopra, il listello sotto i vani alti"),
  ("I mobili senza il fronte", "vani alti, cassone con la libreria, mobili bassi"),
  ("La libreria", "verso il letto il frontale del gavone (580) e la striscia sulla colonna (158), larghi insieme 775, due scaffali a passo 307, il taglio per i cavi"),
  ("I mobili bassi", "A con due ripiani (753), B con i gradini (336), C dei cassetti (500), D con l'appenderia (429)"),
  ("I tre vani alti", "scatole 674 × 444, dentro 636 × 406")]
let cartellaV2 = $nb.doc.homeDir / "falegnami" / "v2"
createDir(cartellaV2)
var schedeV2 = ""
for i, (titolo, nota) in tavoleV2:
  let f = "tavola-" & $(i + 1) & ".jpg"
  copyFile(currentSourcePath().parentDir / "falegnami" / "v2" / f, cartellaV2 / f)
  schedeV2.add "<figure><a href=\"falegnami/v2/" & f & "\" target=\"_blank\" draggable=\"false\"><img src=\"falegnami/v2/" & f &
    "\" alt=\"" & titolo & "\" loading=\"lazy\" draggable=\"false\"></a><figcaption><b>" & $(i + 1) & ". " &
    titolo & "</b><span>" & nota & "</span></figcaption></figure>\n"

nbText: """
### Le tavole della v2

Si scorrono di lato (dito, rotella, frecce); toccandone una si apre a tutta grandezza.
"""

# la galleria prende stile e comportamento dal blocco della v1, più sotto
nbRawHtml: """
<div class="galleria">
  <div class="striscia" tabindex="0" aria-label="Le sette tavole della versione 2">
""" & schedeV2 & """
  </div>
  <button class="freccia indietro" type="button" aria-label="Tavola precedente">‹</button>
  <button class="freccia avanti" type="button" aria-label="Tavola successiva">›</button>
</div>
"""

nbCode:
  import cadero, falegnami
  let v2 = falegnamiV2()
  let m2 = modello(v2)
  echo m2.parts.len, " parti, ", fmtNum(v2.larghezza), " × ", fmtNum(v2.altezza), " × ", fmtNum(v2.profondita), " cm"

nbText: """
### Le decisioni e la v2

Le decisioni prese dopo la v1, una per una, e come risultano nella v2.

| decisione | nella v2 | |
|---|---|---|
| sponda del letto a 131/132 da terra, mantenendo un bordo dentro | 132: mobili bassi abbassati (102.8 invece di 109), dentro restano circa 10 sotto | ✓ |
| moduli bassi quasi da terra, bordo stretto sopra e sotto e più largo ai lati | ante e primo gradino da 6 (prima 12), zoccolo 6.1; bordi 6 sotto, 6 sopra, 12 ai lati | ✓ |
| fronte in 3 pezzi orizzontali, venatura orizzontale | 3 pezzi (118, 97.8, 101.8), orizzontale; ante basse verticali, cassetti e ribalte orizzontali | ✓ |
| primo taglio appena sopra cassetti e scaletta | a 118, 17 sopra le ante | ✓ |
| secondo taglio circa a metà della nicchia | a 215.8: la metà della nicchia è a 193, quindi 22.8 più su | ✗ da verificare |
| togliere la cornice piccola contro muri e soffitto | tolta: 1.5 di luce ai lati e in alto | ✓ |
| nicchia 15 a sinistra e 52 a destra (dal fronte) | 15 e 52 | ✓ |
| da dentro: circa 13 a sinistra, 12 a destra, 10 sotto, 9 sopra | 13.2 a sinistra, 12.4 a destra, 9.4 sotto, 6.3 sopra (dal modello) | ~ sopra più stretto |
| nicchia più tonda | raggio 9 | ✓ |
| testata 58, circa 39/40 sopra un materasso da 17/18 | 58 dal fondo della libreria, che sta 1.8 sotto il piano letto: sopra il materasso da 18 restano 38.2 | ~ |
| pannello unico a L per testata e pilastro | no: due pannelli nello stesso piano, che coprono il bordo dei fianchi; la striscia sul pilastro (15.8) si sagoma sul posto | ✗ |
| libreria: 3 ripiani fissi alti circa 31, i due sopra profondi 27 | piano del comodino e due scaffali a passo 30.7, scaffali 27 | ✓ |
| sportelli in alto 68.3 × 36.6 o più alti | 67.3 × 45.6, la prima con la parte fissa da 16 | ✓ |
| appendiabiti circa 40, allineato al bordo della nicchia | 39 dentro, anta 43.1; il bordo dell'anta è 3.1 a sinistra di quello della nicchia | ~ |
| scaletta larga 30, profonda circa 17.5, gradini tutti alti uguali | 30, pedata 17, cinque gradini da 15.8 | ✓ |
| cassetti circa 50, ripiani circa 70, spazi tutti uguali | cassetti 50.2, anta dei ripiani 75.5, spazi tutti 4 | ~ ripiani 75.5 |
| scaletta tra il centro della nicchia e quello degli sportelli | centro scaletta a 106.5, tra 98.9 (nicchia) e 117.4 (sportello di mezzo) | ✓ |
| piano letto forato o doghe? | piano pieno; i fori si possono aggiungere | da decidere |
| materasso da 76.5 | il cassone dentro è profondo 77.5: entra | ✓ |
| luce nella libreria (placca) e lampada sul pannello del pilastro | punto elettrico pronto al montaggio, il foro lo fanno sul posto; la lampada si avvita sul pannello | ✓ |

**Ancora da decidere o da verificare**: cassetti in frassino sbiancato o in betulla;
fori nel piano letto; il secondo taglio a metà della nicchia; l'altezza del fronte
(317.6, la stanza è 316: con 1.5 di luce in alto dovrebbe essere circa 314.5); se
vogliamo l'anta dei ripiani più vicina a 70 e il bordo sopra la nicchia più largo.
"""

nbText: """
### Come è diviso (v2)

- **Il fronte**: 234.8 × 317.6, in tre pezzi su tutta la larghezza, alti 118, 97.8 e
  101.8 (dal basso). Ai lati e in alto resta 1.5 di luce verso i muri: le due "spalle"
  ai lati del prospetto sono i muri, non pezzi del mobile. La cornice attorno ai
  frontali in basso è di 12 per lato, simmetrica. Venatura orizzontale nel fronte, nei
  cassetti e nelle ribalte; verticale nelle due ante in basso.
- **La nicchia**: 167.8 × 122, da 15 a sinistra a 52 da destra, da 132 a 254 da terra
  (31 sopra le ante, 12 sotto le ribalte), angoli con raggio 9. Visto da dentro il
  bordo è di circa 10 sotto (sopra il materasso), 7 sopra, 11 a destra e 15 a sinistra.
- **In basso**, da 6 a 101 da terra: anta A 75.5, cinque gradini 30 × 15.8 (spazi
  4), tre cassetti 50.2 × 29, anta D 43.1 (prima 50.2). Bordo ai lati 12, spazi 4.
- **I mobili bassi**, alti 102.8 con lo zoccolo da 6.1: A 75.3 con due ripiani, B dei
  gradini 33.6 (dentro 30, gradini profondi 17), C 50 con tre cassetti, D 42.9 con
  l'appenderia.
- **Il cassone del letto**: dentro 193.4 × 155.7, profondo 77.5, appoggiato sui
  mobili bassi (piano letto a 104.6).
- **La libreria**: alta 155.7. Verso il letto niente pannello unico a L, ma due pannelli
  nello stesso piano, davanti ai bordi dei fianchi (il pannello vince sul fianco, che
  così non si vede): il frontale del gavone alto 58 (la testata, fino alla cima del
  comodino) e la striscia sulla colonna larga 15.8, alta quanto la libreria e sagomata
  sul posto contro il muro. Due scaffali a passo 30.7; il taglio per il passaggio dei
  cavi nella schiena. La presa con la placca: punto elettrico pronto al montaggio, il
  foro lo fanno sul posto; la lampada si avvita sulla striscia.
- **I vani alti**: tre scatole 67.4 × 44.4 (dentro 63.6 × 40.6) su un listello sopra il
  cassone; ribalte 67.3 × 45.6, 6 sotto la cima del fronte. Quella di sinistra ha
  ancora la parte fissa (16) per il condizionatore.
"""

block:
  let v1 = falegnami().conModifiche(false, true, false, false).conPannelloAL.nicchiaAperta
             .conTaglio(tTre).conLarghezzeBasse(larghezzeNuove)
  let righe = @[
    ("fronte: larghezza", v1.larghezza, v2.larghezza),
    ("fronte: altezza", v1.altezza, v2.altezza),
    ("pezzi del fronte: taglio basso", v1.zTaglioTre, v2.tagliTre[0]),
    ("mobili bassi: altezza", v1.hBassi, v2.hBassi),
    ("mobili bassi: zoccolo", v1.zoccolo, v2.zoccolo),
    ("ante in basso: da terra", v1.zBassi, v2.zBassi),
    ("piano letto da terra", v1.pianoLetto, v2.pianoLetto),
    ("cassone: larghezza dentro", v1.interno, v2.interno),
    ("cassone: cielo (sotto) da terra", v1.cieloNicchia, v2.cieloNicchia),
    ("nicchia: larghezza", v1.nicchiaL, v2.nicchiaL),
    ("nicchia: altezza", v1.nicchiaH, v2.nicchiaH),
    ("nicchia: bordo basso da terra", v1.nicchiaZ, v2.nicchiaZ),
    ("nicchia: sopra il materasso", v1.bordo, v2.bordo),
    ("testata sopra il materasso", v1.schienale, v2.schienale),
    ("libreria: altezza", v1.hLibreria, v2.hLibreria),
    ("anta A", v1.antaA, v2.antaA),
    ("gradini: larghezza", v1.aperturaGradini, v2.aperturaGradini),
    ("cassetti", v1.cassetti, v2.cassetti),
    ("anta D", v1.antaD, v2.antaD),
    ("vani alti: fondo da terra", v1.fondoVani, v2.fondoVani),
    ("vani alti: scatola", v1.vanoH, v2.vanoH),
    ("ribalte: larghezza", v1.ribaltaL, v2.ribaltaL),
    ("ribalte: altezza", v1.ribaltaH, v2.ribaltaH),
    ("ribalte: da terra", v1.zRibalte, v2.zRibalte)]
  var t = "### Cosa cambia dalla v1\n\nLa v1 è quella del visore di prima (3 orizzontali, " &
    "testata alta, pannello a L, nicchia, larghezze nuove in basso).\n\n" &
    "| misura | v1 | v2 |\n|---|---:|---:|\n"
  for (nome, a, b) in righe:
    let x = if abs(a - b) > 0.05: "**" & fmtNum(b) & "**" else: fmtNum(b)
    t.add "| " & nome & " | " & fmtNum(a) & " | " & x & " |\n"
  nbText(t)

nbText: "### La tavola (v2)"
nbCode:
  let svgTavolaV2 = tavola(v2, m2)
nbRawHtml: svgTavolaV2

nbText: """
### Letture e ipotesi della v2

- **Larghezza**: il fronte è 234.8 (2348 scritto), con 1.5 di luce per lato verso i
  muri: torna con la parete da 237.
- **Altezza**: 1180 + 978 + 1018 = 317.6, la stanza è 316. Con 1.5 di luce in alto il
  fronte dovrebbe essere alto circa 314.5: da verificare.
- **1557 del cassone**: lo leggo dentro (dal piano letto al sotto del cielo), così il
  cielo finisce a 262.1 e sopra la nicchia restano 6.3 di bordo visto da dentro (i
  circa 7: torna). La libreria, sulla sua tavola, è alta 155.7 fuori (finisce
  a 258.5).
- **Listello sotto i vani alti**: le ribalte vanno da 266 a 311.6 (6 sotto la cima del
  fronte) e le aperture, sulla tavola di destra, da 269 a 309.6: le scatole stanno
  quindi da 267.1 a 311.5. Tra il cielo del cassone (262.1) e le scatole restano 5:
  è il listello che si vede nella tavola 3 (dedotto; in scala sembra circa 6).
- **Anta D 431** (prima 502) e mobile D 42.9: la libreria sopra appoggia ancora sul
  mobile D, e a destra restano 12 cm senza niente sotto (come prima, non è un problema).
- **Il "200" sotto i gradini** si legge male: in scala le aperture sono larghe 30, come
  il mobile B dentro (336 − 2 × 18).
- **Gradini**: pedata utile 17, con la schiena 17.8; il mobile dei
  gradini è stato allargato e l'appendiabiti stretto a 39 dentro.
- **Comodino**: con il cassone da 193.4 e il pannello sulla colonna, la libreria dentro è larga
  35.8 (sulla tavola 370 fuori).
- **Profondità**: come la v1, 77.5 i mobili, 81.1 con fronte e ante davanti; il mobile D
  e il vano alto sopra la risega 62.2 (non sono scritti nella v2: tenuti dalla v1).
- **Il taglio per i cavi** nella schiena della libreria non è disegnato nel modello.

**Da decidere**:

- i cassetti in frassino sbiancato (come visto in laboratorio) o in betulla come fuori;
- se fare dei fori nel piano letto (i materassi nuovi non chiedono aerazione
  particolare).
"""

nbText: """
### Cose che non tornano (v2)

Dai controlli del modello:
"""
nbCode:
  for c in controlli(v2, m2): echo "- ", c

nbText: """
### Distinta (v2)
"""
nbCode:
  for r in bom(m2):
    if r.kind in {kPanel, kFront, kBox}:
      echo $r.count & " × " & fmtNum(r.dims[0]) & " × " & fmtNum(r.dims[1]) & " × " &
        fmtNum(r.dims[2]) & "  " & r.name

nbRawHtml: """<h2 id="v1">v1 · Le prime tavole (3 novembre), non più aggiornata</h2>
<p><strong>Da qui in giù è la versione 1</strong>: le sette tavole SketchUp del 3 novembre,
il modello che ne abbiamo ricavato e le modifiche che avevamo chiesto. È superata dalla v2
qui sopra; resta per confronto (nel visore: pulsante <b>v1</b>).</p>
"""

nbText: """
## v1 · Le tavole dei falegnami

Le sette tavole come le hanno mandate, una accanto all'altra: si scorrono di lato
con il dito, con la rotella o trascinando, oppure con le frecce. Toccandone una si
apre a tutta grandezza.
"""

# le immagini stanno in docsrc/falegnami/ e si copiano accanto alla pagina
let tavole = [
  ("Il fronte senza ante", "le aperture nel pannello frontale, con le loro misure"),
  ("Il fronte con ante e ribalte", "in prospettiva: ante, cassetti, ribalte e il pannellino aperto"),
  ("Il prospetto", "il fronte di faccia: i quattro pannelli 1125 × 1568, la fascia e le spalle"),
  ("I mobili senza il fronte", "vani alti, cassone del letto con la libreria, mobili bassi"),
  ("La libreria", "mensole fisse, il gavone sotto, il taglio per i cavi"),
  ("I tre vani alti", "le scatole 681 × 409, profonde 775 (622 quella sopra la risega)"),
  ("I mobili bassi", "A con le mensole mobili, B con i gradini, C dei cassetti, D con l'appenderia")]
let cartella = $nb.doc.homeDir / "falegnami"
createDir(cartella)
var schede = ""
for i, (titolo, nota) in tavole:
  let f = "tavola-" & $(i + 1) & ".jpg"
  copyFile(currentSourcePath().parentDir / "falegnami" / f, cartella / f)
  schede.add "<figure><a href=\"falegnami/" & f & "\" target=\"_blank\" draggable=\"false\"><img src=\"falegnami/" & f &
    "\" alt=\"" & titolo & "\" loading=\"lazy\" draggable=\"false\"></a><figcaption><b>" & $(i + 1) & ". " &
    titolo & "</b><span>" & nota & "</span></figcaption></figure>\n"

nbRawHtml: """
<style>
.galleria { position: relative; margin: 1em 0 1.5em; }
.galleria .striscia { display: flex; gap: 14px; overflow-x: auto; scroll-snap-type: x mandatory;
  overscroll-behavior-x: contain; padding-bottom: 10px; cursor: grab; scrollbar-width: thin; }
.galleria .striscia.trascina { cursor: grabbing; scroll-snap-type: none; }
.galleria figure { flex: 0 0 min(86%, 560px); margin: 0; scroll-snap-align: start;
  background: #fff; border: 1px solid var(--line, #ccc); border-radius: 8px; overflow: hidden; }
.galleria img { display: block; width: 100%; height: 420px; object-fit: contain; background: #fff;
  user-select: none; -webkit-user-drag: none; }
.galleria figcaption { padding: 8px 12px 10px; font-size: 14px; background: var(--panel, #f6f6f6);
  border-top: 1px solid var(--line, #ccc); color: var(--fg, #222); }
.galleria figcaption b { display: block; }
.galleria figcaption span { color: var(--muted, #666); }
.galleria .freccia { position: absolute; top: 190px; width: 40px; height: 40px; border-radius: 50%;
  border: 1px solid var(--line, #ccc); background: var(--panel, #fff); color: var(--fg, #222);
  font-size: 20px; line-height: 1; cursor: pointer; opacity: 0.92; }
.galleria .indietro { left: 6px; } .galleria .avanti { right: 6px; }
.galleria .freccia[hidden] { display: none; }
@media (max-width: 600px) { .galleria img { height: 300px; }
  .galleria .freccia { top: 135px; width: 32px; height: 32px; font-size: 17px; opacity: 0.8; } }
</style>
<div class="galleria">
  <div class="striscia" tabindex="0" aria-label="Le sette tavole dei falegnami">
""" & schede & """
  </div>
  <button class="freccia indietro" type="button" aria-label="Tavola precedente">‹</button>
  <button class="freccia avanti" type="button" aria-label="Tavola successiva">›</button>
</div>
<script>
// la galleria: frecce, rotella verticale che scorre di lato, trascinamento con il mouse
// (con il dito scorre da sola); un trascinamento non apre l'immagine
window.attivaGalleria = g => {
  const s = g.querySelector('.striscia');
  const passo = () => s.querySelector('figure').offsetWidth + 14;
  g.querySelector('.indietro').onclick = () => s.scrollBy({left: -passo(), behavior: 'smooth'});
  g.querySelector('.avanti').onclick = () => s.scrollBy({left: passo(), behavior: 'smooth'});
  s.addEventListener('wheel', e => {
    if (Math.abs(e.deltaY) > Math.abs(e.deltaX) && s.scrollWidth > s.clientWidth) {
      const fine = s.scrollLeft + s.clientWidth >= s.scrollWidth - 2;
      if ((e.deltaY > 0 && !fine) || (e.deltaY < 0 && s.scrollLeft > 0)) {
        e.preventDefault(); s.scrollLeft += e.deltaY;
      }
    }
  }, {passive: false});
  let x0 = 0, l0 = 0, giu = false, mosso = false;
  s.addEventListener('pointerdown', e => {
    if (e.pointerType !== 'mouse') return;
    giu = true; mosso = false; x0 = e.clientX; l0 = s.scrollLeft;
  });
  window.addEventListener('pointermove', e => {
    if (!giu) return;
    if (Math.abs(e.clientX - x0) > 5) { mosso = true; s.classList.add('trascina'); }
    if (mosso) s.scrollLeft = l0 - (e.clientX - x0);
  });
  window.addEventListener('pointerup', () => {
    if (!giu) return;
    giu = false; s.classList.remove('trascina');
  });
  s.addEventListener('dragstart', e => e.preventDefault());
  s.addEventListener('click', e => { if (mosso) { e.preventDefault(); mosso = false; } }, true);
  const frecce = () => {   // la freccia non serve all'inizio e alla fine
    g.querySelector('.indietro').hidden = s.scrollLeft < 4;
    g.querySelector('.avanti').hidden = s.scrollLeft + s.clientWidth >= s.scrollWidth - 4;
  };
  s.addEventListener('scroll', frecce, {passive: true});
  frecce();
  s.addEventListener('keydown', e => {
    if (e.key === 'ArrowRight') { s.scrollBy({left: passo(), behavior: 'smooth'}); e.preventDefault(); }
    if (e.key === 'ArrowLeft') { s.scrollBy({left: -passo(), behavior: 'smooth'}); e.preventDefault(); }
  });
};
document.querySelectorAll('.galleria').forEach(attivaGalleria);
</script>
"""

nbText: """
## v1 · Le tavole rifatte dal nostro modello

Le stesse sette tavole, disegnate dal modello qui sotto, in proiezione e con le
stesse quote: servono a vedere se ci siamo persi dei pezzi e se le misure tornano.
Ogni misura è confrontata con quella scritta sulla loro tavola:
<span style="color:#1a1a1a">**nera**</span> se torna,
<span style="color:#d0312d">**rossa**</span> se è diversa (tra parentesi la loro),
<span style="color:#1f6fd1">**blu**</span> se sulla loro tavola non c'è e l'abbiamo
dedotta (per esempio la larghezza del pannello che copre la risega). Toccandone una si
apre a tutta pagina.
"""

var rifatte = ""
for i, t in tavoleRifatte(falegnami()):
  rifatte.add "<figure><div class=\"disegno\" role=\"button\" tabindex=\"0\">" & t.svg &
    "</div><figcaption><b>" & $(i + 1) & ". " & t.nome & "</b><span>" & t.nota & "</span></figcaption></figure>\n"

nbRawHtml: """
<style>
.galleria .disegno { height: 420px; background: #fff; cursor: zoom-in; overflow: hidden; }
.galleria .disegno svg { width: 100% !important; height: 100% !important; max-width: none !important; display: block; }
@media (max-width: 600px) { .galleria .disegno { height: 300px; } }
.ingrandita { position: fixed; inset: 0; z-index: 50; background: #fff; overflow: auto; cursor: zoom-out; }
.ingrandita svg { width: max(100%, 1100px); height: auto !important; max-width: none !important; display: block; }
</style>
<div class="galleria">
  <div class="striscia" tabindex="0" aria-label="Le sette tavole rifatte dal modello">
""" & rifatte & """
  </div>
  <button class="freccia indietro" type="button" aria-label="Tavola precedente">‹</button>
  <button class="freccia avanti" type="button" aria-label="Tavola successiva">›</button>
</div>
<script>
// la seconda galleria: stesso comportamento; toccando un disegno lo si vede a tutta pagina
(() => {
  const g = document.querySelectorAll('.galleria');
  const ultima = g[g.length - 1];
  attivaGalleria(ultima);
  ultima.querySelectorAll('.disegno').forEach(d => d.addEventListener('click', () => {
    if (ultima.querySelector('.striscia').classList.contains('trascina')) return;
    const o = document.createElement('div');
    o.className = 'ingrandita';
    o.innerHTML = d.innerHTML;
    o.addEventListener('click', () => o.remove());
    document.body.appendChild(o);
  }));
})();
</script>
"""

nbCode:
  import cadero, parete, falegnami
  let f = falegnami()
  let m = modello(f)
  let p = rilievo()
  echo m.parts.len, " parti, ", fmtNum(f.larghezza), " × ", fmtNum(f.altezza), " × ", fmtNum(f.profondita), " cm"

nbText: """
## v1 · Come è diviso

- **Il fronte**: quattro pannelli da 112.5 × 156.8, una fascia alta 6 in cima e due
  spalle larghe 5.9 contro i muri. La nicchia e il vano alto di mezzo passano da
  un pannello all'altro: nei pezzi diventano tacche del bordo, non fori.
- **Tre vani alti** 68.1 × 40.9, scatole aperte davanti con la ribalta. Quella di
  sinistra è tagliata a 15 cm: il pezzo a sinistra resta fisso, si apre solo la
  parte destra, così la ribalta non sbatte contro il condizionatore.
- **Il cassone del letto**: piano, cielo e un fianco a sinistra, dentro 193, alto 150 fuori come la libreria (146.4 dentro),
  profondo 77.5. Piano e cielo non passano sotto e sopra la libreria (non è
  chiaro dalle tavole: l'ho assunto).
- **La libreria** in testa al letto, un mobile a sé: 63.5 di profondità, alta 150,
  aperta verso il letto, con il gavone sotto (frontale 32), il piano del comodino
  profondo 38 con l'apertura e i due coperchi, tre scaffali profondi 27. Alla sua
  sinistra, guardandola dal letto, il pannello che copre la risega: alto 150, in
  piano con l'apertura della libreria, largo dal fianco dietro fino al muro (15.8,
  dedotto: sulla tavola non c'è la misura). Riempie anche lo spazio tra cassone e
  libreria, dove avanzano solo 0.2 cm.
- **Quattro mobili bassi** alti 109: A con due ripiani mobili (75.3), B con i
  gradini in multistrato (28.6, profondo 30), C con tre cassetti (50), D con l'appenderia (50,
  profondo solo 62.2 per stare davanti alla risega).

Dietro i vani alti e i mobili bassi c'è una schiena sottile (0.8, ipotesi: non è
segnata sulle tavole), grigia; quella dei gradini è color legno e si apre all'altezza
della fessura, perché il pannellino chiuso passi dietro.

Le scatole grigie dei disegni le leggo come melaminico da 19 mm (500 fuori, 462
dentro), le parti color legno come multistrato da 18 (la libreria: 635 fuori,
599 dentro). Nel visore il melaminico è grigio.
"""

nbText: "## v1 · La tavola"
nbCode:
  let svgTavola = tavola(f, m)
nbRawHtml: svgTavola

nbText: """
Prospetto, sezione laterale a x = 150 (dentro la nicchia, si vedono i cassetti di
C) e pianta a 130 cm da terra, sopra il piano letto. Senza il pannellino il
prospetto dei gradini cambia così: niente fessura, lo spazio tra i gradini diventa
4.75 invece di 4.
"""

nbCode:
  let senza = falegnami().senzaPannello
  var foglio = initSheet()
  let fronte = View(kind: vFront)
  foglio.draw(fronte, modello(senza))
  for q in quote(senza):
    if q.view == vFront: foglio.draw(fronte, q)
nbRawHtml: foglio.render()

nbText: """
## v1 · L'altezza della nicchia, dalla base del letto

Sulle tavole non c'è una quota della nicchia misurata dal letto: va calcolata
sommando le altezze dei mobili. I mobili bassi sono alti 109, il piano del
cassone (18 mm) ci sta sopra, dentro il cassone ci sono 150 cm, poi il cielo.
"""

nbCode:
  let righe = @[
    ("cima dei mobili bassi", f.hBassi),
    ("piano letto (cima del piano del cassone)", f.pianoLetto),
    ("cima del materasso (" & fmtNum(f.materasso.altezza) & ")", f.pianoLetto + f.materasso.altezza),
    ("piano del comodino (gavone 32 + 1.8)", f.pianoComodino),
    ("bordo basso dell'apertura (dedotto: alto a filo del cielo)", f.nicchiaZ),
    ("bordo alto dell'apertura (+ 121.9)", f.nicchiaZ + f.nicchiaH),
    ("sotto del cielo del cassone (cassone alto 150 fuori, come la libreria)", f.cieloNicchia),
    ("fondo dei vani alti (sul cielo del cassone)", f.fondoVani),
    ("cima del fronte (2 × 156.8 + 6)", f.altezza)]
  for (nome, z) in righe:
    echo fmtNum(z).align(6), "  ", nome
  echo ""
  echo "dal piano letto: apertura da ", fmtNum(f.nicchiaZ - f.pianoLetto), " a ",
    fmtNum(f.nicchiaZ + f.nicchiaH - f.pianoLetto), ", cielo a ", fmtNum(f.hNicchia)
  echo "sopra il materasso: fronte ", fmtNum(f.bordo), ", testata ", fmtNum(f.schienale)

nbText: """
Lo stesso conto disegnato, con solo il frontale, il cassone del letto, il
materasso e la libreria (prospetto e sezione laterale a x = 100; in blu le misure
dedotte, in nero le loro). Partendo dal basso:

- mobili bassi 109, sopra il piano del cassone da 1.8: la base del letto è a 110.8;
- materasso 17, e sopra resta un bordo di 7.5 fino all'apertura;
- l'apertura della nicchia è alta 121.9 e arriva fino al sotto del cielo del
  cassone (257.2);
- il cielo è da 1.8: il cassone è alto 146.4 dentro e 150 fuori, come la libreria.

Il bordo alto dell'apertura coincide quindi con il sotto del cielo. È quello che
viene prendendo il 150 come misura esterna e il 121.9 dalle loro tavole. Se il 150
fosse interno, l'apertura partirebbe da 137, ma il cassone finirebbe 3.6 più in
alto della libreria. Il frontale porta ancora i fori dei vani e delle ante, per
questo si vedono anche quelli.

Nel prospetto la libreria, che sta dietro al frontale, è tratteggiata, insieme al
pannello da 1.8 che copre la risega alla sua sinistra. La catena in alto dà la
distanza fra il bordo destro della nicchia e la libreria.
"""

nbCode:
  let svgNicchia = disegnoNicchia(f)
nbRawHtml: "<div class=\"disegno-nicchia\">" & svgNicchia & "</div>"

nbText: """
## v1 · Confronto con la nostra parete

Le stesse misure nei due modelli (la nostra con i parametri di oggi).
"""

nbCode:
  let confronto = @[
    ("altezza del mobile", p.altezza, f.altezza),
    ("profondità (ante comprese)", p.profondita, f.profondita),
    ("piano letto da terra", p.pianoLetto, f.pianoLetto),
    ("nicchia dentro, dal piano letto", p.altezze.nicchia, f.hNicchia),
    ("apertura: bordo basso da terra", p.nicchiaZ, f.nicchiaZ),
    ("apertura: altezza", p.nicchiaH, f.nicchiaH),
    ("apertura: larghezza", p.nicchiaL, f.nicchiaL),
    ("fronte sopra il materasso (bordo)", p.bordo, f.bordo),
    ("testata sopra il piano letto", p.altezze.testata, f.pianoComodino - f.pianoLetto),
    ("testata sopra il materasso", p.schienale, f.schienale),
    ("profondità del comodino", p.profComodino, f.comodino),
    ("profondità degli scaffali", p.libreria.profScaffali, f.scaffali),
    ("ribalte: altezza", p.alta.altezzaRibalta, f.ribaltaH),
    ("ribalte: larghezza", p.alta.larghezzaRibalta, f.ribaltaL),
    ("ante in basso: da terra", p.bassa.zoccolo, f.zBassi),
    ("ante in basso: altezza", p.bassa.altezzaAnte, f.altezzaAnte),
    ("anta grande (A)", p.bassa.antaGrande, f.antaA),
    ("gradini: larghezza", p.bassa.gradini, f.aperturaGradini),
    ("cassetti: larghezza", p.bassa.cassetti, f.cassetti),
    ("anta stretta (D)", p.bassa.antaStretta, f.antaD)]
  echo "misura".alignLeft(36), "nostra".align(8), "loro".align(8)
  for (nome, a, b) in confronto:
    let segno = if abs(a - b) > 0.5: "  ←" else: ""
    echo nome.alignLeft(36), fmtNum(a).align(8), fmtNum(b).align(8), segno

nbText: """
Le differenze grandi: la testata (loro 32 sopra il piano letto, noi avevamo
deciso 58), il fronte più alto della stanza, le ribalte più basse e le ante in
basso più larghe e su uno zoccolo più alto. La nicchia dentro è più bassa (150
contro 159), ma l'apertura è quasi uguale.

## v1 · Cose che non tornano

Dai controlli del modello:
"""

nbCode:
  for c in controlli(f, m): echo "- ", c

nbText: """
## v1 · Letture e ipotesi da verificare

- **Altezza**: 60 + 1568 + 1568 fa 319.6, la stanza è 316. Forse hanno rimisurato;
  da chiedere.
- <strong>Profondità</strong>: con le ante davanti al fronte (le ante 755 coprono aperture da 715)
  e i mobili da 775 dietro, si arriva a 81.1. Se invece le ante stanno a filo nel
  fronte, si arriva a 79.3 e torna con gli 80: da chiedere.
  Nel visore e nelle tavole il muro è disegnato a 81.1, dietro i mobili, perché si
  vedano le schiene.
- **622**: lo leggo come la profondità dei mobili davanti alla risega (il vano alto
  di destra e il mobile D); 775 per gli altri.
- **300** sul mobile dei gradini è la sua profondità (Pietro): il mobile B è profondo
  30. Il pannellino lungo 67 chiuso rientra nello spazio libero dietro, sotto il
  cassone: lì serve una guida che lo regga.
- **Il triangolo** fuori dalla libreria, a 277 da uno scaffale, e il taglio per il
  passaggio dei cavi: non li ho disegnati. La scatola delle prese non c'è nelle tavole.
- **Vani alti e ribalte.** Le ribalte stanno dove le mette il fronte, le scatole
  dove le mettono i mobili, e le due catene di misure non tornano tra loro. Le
  scatole (Pietro: solo scatole, appoggiate sul cassone) stanno sopra mobili bassi e
  cassone: 109 + 150 = 259, più 40.9, quindi da 259 a 299.9. Sul prospetto le
  ribalte si leggono da 270 a 306.6, cioè 11 cm più in alto delle scatole e 6.7 sopra
  la loro cima. Pietro: la cima della ribalta deve essere più o meno a filo di quella
  della scatola, quindi le ribalte ora partono da 263.3 (dedotto). Restano due cose:
  il dentro della scatola sta 4.4 sotto il bordo dell'apertura (vedi i controlli) e
  sopra le ribalte, fino alla fascia, resta una striscia di fronte di 13.7 (sul
  prospetto sembra più bassa). Il motivo è che il fronte è alto 319.6 mentre i
  mobili impilati arrivano a 299.9: da chiedere ai falegnami.
- **Libreria**: appoggia sui mobili bassi; a destra del mobile D restano 12 cm
  senza niente sotto.
- **Cassone alto 150 fuori**, come la libreria (Pietro: mobili bassi tutti a 109,
  libreria e nicchia alte uguali): dentro resta 146.4, e la cima del cielo è a filo
  della libreria (259). Perché l'apertura da 121.9 non salga oltre il cielo, il suo
  bordo basso è a 135.3 (dedotto; in scala sul prospetto si legge circa 137).
  Materasso largo 77 (Pietro).
- **Rilevate in scala**: spazio tra i frontali (4, torna con tutte le larghezze), zoccolo dei
  mobili (11.8), raggi (nicchia 5, aperture 3, frontali 2), fori maniglia (3) a 6
  cm dagli spigoli.

## v1 · Distinta
"""

nbCode:
  for r in bom(m):
    if r.kind in {kPanel, kFront, kBox}:
      echo $r.count & " × " & fmtNum(r.dims[0]) & " × " & fmtNum(r.dims[1]) & " × " &
        fmtNum(r.dims[2]) & "  " & r.name

nbText: """
## v1 · Le modifiche che vorremmo

Rispetto al loro disegno torna più o meno tutto, ma alcune cose le vorremmo fatte
in modo diverso. La prima è già decisa: non vogliamo il pannellino estraibile.
Poi ci sono tre richieste (Pietro, 4 novembre):

1. **Testata più alta**: il gavone sotto il comodino passa da 32 a 58 dal piano
   letto (la nostra testata), con uno scaffale in meno.
2. **Pannello della risega più stretto**: da quasi 16 a 10. La risega è profonda
   7; nella tavola 5 forse serve un listello, ma a 10 dovremmo arrivare.
3. **Aperture dei vani alti più alte**: con 32.6 potrebbe non starci una scatola
   IKEA da mettere e togliere.

Sono modifiche indipendenti, come il pannellino: in `falegnami.nim` sono
`testataAlta`, `risegaStretta` e `vaniAlti`, e `conModifiche` le accende una per una.
Nel [visore](visore3d.html) ci sono i pulsanti *Tavolino* (il pannellino estraibile),
*Testata alta* e *Vani alti*; la risega stretta l'abbiamo scartata (7 novembre: la
risega resta 15.8), quindi il suo pulsante non c'è più.
Qui sotto il **modello rivisto** è quello con le prime due accese e senza pannellino
(`rivisto`); la terza si aggiunge sopra.
"""

nbCode:
  let fr = f.rivisto
  let fv = fr.vaniAlti
  let cambi = @[
    ("pannellino estraibile", (if f.pannello: "sì" else: "no"), "no", "no"),
    ("testata: piano comodino dal piano letto", fmtNum(f.pianoComodino - f.pianoLetto),
      fmtNum(fr.pianoComodino - fr.pianoLetto), fmtNum(fv.pianoComodino - fv.pianoLetto)),
    ("testata sopra il materasso", fmtNum(f.schienale), fmtNum(fr.schienale), fmtNum(fv.schienale)),
    ("scaffali", $f.nScaffali, $fr.nScaffali, $fv.nScaffali),
    ("vano tra due scaffali (netto)", fmtNum(f.zScaffali[0] - f.pianoComodino),
      fmtNum(fr.zScaffali[0] - fr.pianoComodino), fmtNum(fv.zScaffali[0] - fv.pianoComodino)),
    ("profondità della libreria", fmtNum(f.profLibreria), fmtNum(fr.profLibreria), fmtNum(fv.profLibreria)),
    ("pannello della risega", fmtNum(f.pannelloRisega), fmtNum(fr.pannelloRisega), fmtNum(fv.pannelloRisega)),
    ("dietro della libreria / risega", fmtNum(f.yMobili + f.profLibreria) & " / " & fmtNum(f.yMuro - f.muro.risegaProf),
      fmtNum(fr.yMobili + fr.profLibreria) & " / " & fmtNum(fr.yMuro - fr.muro.risegaProf),
      fmtNum(fv.yMobili + fv.profLibreria) & " / " & fmtNum(fv.yMuro - fv.muro.risegaProf)),
    ("pannelli del fronte (alti)", fmtNum(f.pannelloH), fmtNum(fr.pannelloH), fmtNum(fv.pannelloH)),
    ("altezza del fronte", fmtNum(f.altezza), fmtNum(fr.altezza), fmtNum(fv.altezza)),
    ("vani alti: scatole alte", fmtNum(f.vanoH), fmtNum(fr.vanoH), fmtNum(fv.vanoH)),
    ("ribalte alte", fmtNum(f.ribaltaH), fmtNum(fr.ribaltaH), fmtNum(fv.ribaltaH)),
    ("apertura dei vani alti", fmtNum(f.ribaltaH - 2 * f.sormonto), fmtNum(fr.ribaltaH - 2 * fr.sormonto),
      fmtNum(fv.ribaltaH - 2 * fv.sormonto))]
  echo "".alignLeft(42), "loro".align(14), "rivisto".align(14), "+ vani alti".align(14)
  for (nome, a, b, c) in cambi:
    echo nome.alignLeft(42), a.align(14), b.align(14), c.align(14)

nbText: """
### v1 · 1 e 2: testata e pannello della risega

- **Testata**: il frontale del gavone, verso il letto, sale a 58 e il piano del
  comodino va a 168.8 da terra (41 sopra il materasso, come nella nostra parete).
  Con due scaffali al posto di tre, fra un piano e l'altro restano 28.3 netti
  (passo 30.1): meno dei 31 che ci aspettavamo, perché sopra il comodino ci sono
  88.4 cm (fino al sotto del cielo della libreria) e due scaffali da 1.8. Il gavone
  diventa molto più alto (56 dentro): da vedere se serve un ripiano anche lì.
- **Pannello della risega**: va dal fianco dietro della libreria al dietro del
  mobile, quindi per farlo largo 10 la libreria diventa più profonda (da 63.5 a
  69.3). Il suo dietro arriva a 72.9 e la risega comincia a 74.1 (con il muro
  disegnato a 81.1, dove arrivano i loro mobili): restano 1.2 cm. Con il muro vero a
  80 la risega comincia a 73 e il margine scende a 0.1, quindi 10 è circa il minimo
  senza toccare la risega. Il listello della tavola 5, se serve, va fra la
  libreria e la risega. Gli scaffali restano profondi 27; il piano del comodino e
  l'apertura del gavone diventano più profondi con la libreria.

La tavola del modello rivisto:
"""

nbCode:
  let svgRivisto = tavola(fr, modello(fr))
nbRawHtml: svgRivisto

nbText: """
### v1 · 3: aprire di più i vani alti

Oggi l'apertura è alta 32.6: la ribalta è alta 36.6 e copre l'apertura di 2 cm sopra
e 2 sotto. Una scatola IKEA DRÖNA, quella dei Kallax, è larga 33, profonda 38 e
alta 33 (verificato sul sito IKEA), quindi oggi non passerebbe. Per la proposta teniamo il loro fronte da
319.6 come giusto e prendiamo un'apertura di **41.7** (Pietro), la misura che lascia
margine anche se il soffitto fosse davvero a 316.

Cosa ci limita:

- **Sotto**: le scatole dei vani appoggiano sul cielo del cassone, a 259. Il cassone è
  alto 150 come la libreria e l'apertura della nicchia arriva fino al suo cielo. Per
  abbassare i vani bisognerebbe abbassare cassone e libreria, cioè la nicchia o la
  base del letto: non serve.
- **Sopra**: il fronte arriva a 313.6 sotto la fascia, e le ribalte di oggi finiscono a
  299.9. Sopra c'è posto: tenendo 3 cm di fronte sotto la fascia, l'apertura potrebbe
  arrivare fino a 45.3.

La proposta: le ribalte partono da dove partono oggi (263.3) e crescono verso l'alto.

- **Ribalta** alta 45.7 invece di 36.6, quindi +9.1; l'anta resta 4 cm più alta
  dell'apertura, come oggi.
- **Scatole** alte 50 invece di 40.9, con la cima sempre a filo della ribalta (309):
  restano 7 cm sotto il soffitto da 316 che abbiamo misurato, per montarle.
- **Apertura** 41.7 (+9.1): una DRÖNA da 33 passa con quasi 9 cm di gioco. In
  larghezza ne entra una per vano (dentro 64.3, due farebbero 66); in profondità due
  una dietro l'altra (76 su 76.7) nei due vani a sinistra, una sola nel vano sopra la
  risega (62.2).
- **Sotto non cambia niente**: nicchia, cassone, libreria e mobili bassi restano dove
  sono. Nel fronte cambiano solo i tre fori alti, e la striscia di fronte sopra le
  ribalte scende da 13.7 a 4.6 (più la fascia da 6).

Cosa andrebbe verificato:

- **Il limite**: tenendo 3 cm di fronte sotto la fascia si arriverebbe a 45.3; 41.7
  lascia margine sul soffitto.
- **Lo scalino dentro (il fondo della scatola è 4.4 sotto il bordo dell'apertura) va
  scavalcato sollevando la scatola.
- **Ribalte più grandi**: 45.7 × 68.3 pesano di più (compassi o pistoni più forti) e
  aperte sporgono 45.7 in avanti.
- **Il condizionatore**: la prima ribalta, più alta di 9.1, quando si apre sporge di
  più: va controllato con la posizione vera.
- **Un'alternativa che non tocca le scatole**: far crescere l'apertura verso il basso
  invece che verso l'alto. Le scatole di oggi dentro hanno 37.1: l'apertura arriverebbe
  al massimo a 37.1 (meno di 41.7) e lo scalino sparirebbe. Però la ribalta partirebbe da
  258.9, e fra la nicchia e le ribalte resterebbero 1.7 cm di fronte invece di 6.1.

Prima la zona alta di oggi (nel modello rivisto, che lì non cambia), poi la proposta.
Prospetto e sezione nel vano di mezzo, con la ribalta chiusa di fianco:
"""

nbCode:
  let svgVaniOggi = disegnoVaniAlti(fr)
  let svgVaniProposta = disegnoVaniAlti(fv)
nbRawHtml: "<p><b>Oggi</b>: apertura 32.6</p>" & svgVaniOggi
nbRawHtml: "<p><b>Proposta</b>: apertura 41.7</p>" & svgVaniProposta

nbText: "I controlli del modello con la proposta:"
nbCode:
  for r in controlli(fv, modello(fv)): echo "- ", r

nbText: """
## v1 · Il pannello a L, in testa al letto

Una proposta da fare ai falegnami: il frontale del gavone (la testata, verso il letto)
e il pannello che copre la risega diventano **un solo pannello a L**, dove oggi c'è il
pannello della risega. Il braccio basso arriva fino alla cima del piano del comodino, così ne copre il bordo, e va dal davanti al muro;
quello alto, alto quanto la libreria, dal fianco dietro al muro. La L passa davanti ai
bordi dei due fianchi della libreria, che restano come sono, sta a 0.2 dal cassone come
il pannello della risega di oggi e non tocca la risega. Il fondo del gavone arriva fino
alla L. Nel visore: pulsante *Pannello a L*.

Il pezzo a L va tagliato da una lastra intera (le misure sotto).
"""

nbCode:
  let fl = f.conPannelloAL
  for p in modello(fl).parts:
    if p.name in ["pannello a L", "fianco libreria"]:
      echo p.name, ": ", p.size.x.fmtNum, " × ", p.size.y.fmtNum, " × ", p.size.z.fmtNum
  for r in controlli(fl, modello(fl)): echo "- ", r

nbText: """
## v1 · La nicchia, con le misure decise

Con i falegnami abbiamo deciso una nicchia più larga, e che vista da dietro il fronte
sporga un po' su tutti i lati. L'apertura comincia 15 dal muro di sinistra e finisce 50
prima di quello di destra; il bordo alto sta 10 sotto il cielo del cassone, quello basso
10 sopra il materasso, che diventa alto 18 (invece di 17). Nel visore: pulsante *Nicchia*.
"""

nbCode:
  let fn = f.nicchiaAperta
  echo "apertura: ", fmtNum(fn.nicchiaL), " × ", fmtNum(fn.nicchiaH), " (prima ",
    fmtNum(f.nicchiaL), " × ", fmtNum(f.nicchiaH), "), da ", fmtNum(fn.nicchiaZ), " a ",
    fmtNum(fn.nicchiaZ + fn.nicchiaH), " da terra"

nbText: """
## v1 · La presa dietro la libreria

Abbiamo deciso di portare la corrente dietro la libreria: una traccia e una scatola nel
muro (3 moduli), e la presa che esce dalla schiena della libreria. Guardando il comodino
sta in basso a destra: la placca (12 × 8.2) è 5 sopra il piano del comodino e 5 dal
fianco davanti. Si sposta con la testata e con la libreria. Nel visore, con *Misurare*,
toccare la presa dà le misure dal centro della placca alla risega e al pavimento;
*Senza presa* la toglie.
"""

nbCode:
  for (nome, g) in [("oggi", f), ("testata alta", f.testataAlta), ("rivisto", f.rivisto)]:
    echo nome, ": centro della presa a ", fmtNum(g.presaDallaRisega), " dalla risega e ",
      fmtNum(g.centroPresa.z), " da terra"

nbText: """
## v1 · Il taglio del pannello frontale, in multistrato di betulla

Il pannello frontale è largo 236.8 e alto 319.6: non sta in una lastra di
multistrato (300 × 150, ipotesi: il formato grande più comune), va diviso. Due modi,
da scegliere nel visore con i pulsanti *Taglio*:

- **A croce**, come i falegnami: quattro pannelli alti 156.8 e una fascia alta 6 in
  cima. Venatura verticale.
- **In 3 orizzontali** (richiesta sulla PR): tre pezzi su tutta la larghezza. Il
  taglio basso è a 109, poco sopra i gradini e le ante (107), alla cima dei mobili
  bassi; sopra, due pezzi alti uguali (taglio a 214.3, attraversa la nicchia).
  Venatura orizzontale.

**La cornice** (le due spalle ai lati, 5.9 × 319.6, come nel disegno dei falegnami)
è un pulsante a parte, *Cornice*: nel visore di base non c'è, e i pezzi del fronte
vanno da muro a muro. Le spalle non stanno in una lastra da 300. Nel disegno ogni
pezzo ha le righe della sua venatura; verde se sta in una lastra, rosso se no:
"""

nbCode:
  let svgTagli = disegnoTagli(f)
  let svgTagliCornice = disegnoTagli(f, [("", f.conTaglio(tCroce)), ("", f.conTaglio(tTre))])
nbRawHtml: svgTagli
nbText: "Con la cornice:"
nbRawHtml: svgTagliCornice

nbText: """
**La venatura.** Ogni pannello in multistrato ha la sua venatura, orizzontale o
verticale (`Part.venatura`). Di base: i pezzi del fronte verticali a croce e
orizzontali in 3, le spalle verticali, le ante basse verticali, i cassetti e le
ribalte dei vani alti orizzontali; le altre parti lungo il lato più lungo. Per
sceglierla nel modello si scrive il nome del pannello in `f.venature`, per esempio
`@[("fronte sopra", venVerticale)]`. Nel visore il pulsante *Betulla* mostra il
multistrato (la faccia con la venatura, il bordo con gli strati) e *Gira venatura*,
premuto, gira la venatura del pannello che si tocca: serve per provare. Il
melaminico delle scatole resta grigio.
"""

nbSave
