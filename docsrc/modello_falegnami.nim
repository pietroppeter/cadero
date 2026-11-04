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

I falegnami hanno mandato sette tavole SketchUp della parete. È la stessa stanza
e la stessa idea della [nostra parete](parete_nicchia.html), ma divisa nei mobili
che costruiranno davvero, con molto dettaglio in più. Qui è ridisegnata da codice
in `models/falegnami.nim`, accanto alla nostra, che resta com'è. Nel
[visore 3D](visore3d.html) è il modello di default (la nostra idea ha il suo
[Visore 3D - Idea](visore3d_idea.html)); il pulsante **Pannello estraibile**
toglie il pannellino tra i gradini (senza, i gradini si ridistribuiscono).

Le loro misure sono in mm, qui in cm. Quelle scritte sulle tavole sono riportate
così come sono; quelle che mancano le ho misurate in scala sul prospetto
(rilevate) o ipotizzate: sono elencate in fondo.
"""

nbText: """
## Le tavole dei falegnami

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
## Le tavole rifatte dal nostro modello

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
## Come è diviso

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

nbText: "## La tavola"
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
## L'altezza della nicchia, dalla base del letto

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
"""

nbCode:
  let svgNicchia = disegnoNicchia(f)
nbRawHtml: "<div class=\"disegno-nicchia\">" & svgNicchia & "</div>"

nbText: """
## Confronto con la nostra parete

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

## Cose che non tornano

Dai controlli del modello:
"""

nbCode:
  for c in controlli(f, m): echo "- ", c

nbText: """
## Letture e ipotesi da verificare

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

## Distinta
"""

nbCode:
  for r in bom(m):
    if r.kind in {kPanel, kFront, kBox}:
      echo $r.count & " × " & fmtNum(r.dims[0]) & " × " & fmtNum(r.dims[1]) & " × " &
        fmtNum(r.dims[2]) & "  " & r.name

nbSave
