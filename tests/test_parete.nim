import std/unittest
import std/strutils
import ../src/cadero, ../models/parete

let p = rilievo()
let m = parete(p)

proc near(a, b: float): bool = abs(a - b) < 0.06

suite "parete di riferimento":
  test "la catena del fronte riproduce le quote della tavola":
    check p.catenaFronte == @[0.0, 6, 101, 131, 253, 265, 308, 316]
    check p.altezza == 316

  test "colonna destra e campata":
    check near(p.xColonna, 198.2)
    let cx = p.colonneX
    check near(cx[3] + p.colonneBasse[3], p.larghezza - p.margineLato)

  test "vista laterale: piano letto 104, testata 55, libreria fino al soffitto":
    check near(p.baseLibreria - p.pianoLetto, 55)     # testata (= comodino)
    check near(p.cimaLibreria, p.soffittoNicchia)     # libreria fino al soffitto
    check abs(p.vanoUtile - 32) < 0.5                 # 3 vani da circa 32
    check near(p.soffittoNicchia, 260)
    check near(p.margineBasso + p.zonaBassa + p.fascia - p.pianoLetto, 27)

  test "il pannello frontale ha la nicchia e i gradini come aperture":
    check m.find("fronte").holes.len == 1 + p.nGradini

  test "tutto sta dentro l'ingombro (tranne il cassetto aperto)":
    for q in m.parts:
      if q.gruppo != "" and q.pos.y < 0: continue   # aperto
      if q.kind == kSoft: continue      # il materasso lo verificano i controlli
      if q.name == "muro (carta da parati)": continue   # il muro dietro, fuori dal mobile
      check q.pos.x >= -0.01 and q.x1 <= p.larghezza + 0.01
      check q.pos.z >= -0.01 and q.z1 <= p.altezza + 0.01
      check q.pos.y >= -0.01 and q.y1 <= p.profondita + 0.01

  test "il materasso sta sotto il bordo della fascia":
    let mat = m.find("materasso")
    check mat.z1 < p.catenaFronte[3]

  test "distinta":
    var cassetti = 0
    for r in bom(m):
      if r.name == "frontale cassetto": cassetti += r.count
    check cassetti == p.nCassettiBassi

  test "variante: cambiando la nicchia cambia l'altezza":
    var p2 = rilievo()
    p2.nicchia = 112
    check p2.altezza == 306
    check near(p2.soffittoNicchia, 250)
    check p2.cimaLibreria <= p2.soffittoNicchia   # la libreria ci sta ancora

  test "i ripiani stanno dentro la libreria":
    for h in p.ripiani:
      check h > 0 and p.baseLibreria + h < p.cimaLibreria

  test "formato delle quote":
    check fmtNum(198.2) == "198.2"
    check fmtNum(316.0) == "316"

  test "risega: colonna profonda 73 e pannellino sul bordo sottile":
    check near(p.profColonna, 73)
    let r = m.find("risega (muro)")
    check r.kind == kWall and near(r.y1, p.profondita)
    let pan = m.find("pannellino risega")
    check near(pan.pos.y, p.profColonna) and near(pan.y1, p.profondita)
    check near(pan.size.z, p.altezza - 2 * p.spessore)   # per tutta l'altezza
    # rivestimento a L senza fessure: lo schienale della colonna parte dallo
    # stesso piano del pannellino e del divisorio
    let sc = m.find("schienale colonna")
    check near(sc.pos.x, pan.pos.x) and near(sc.y1, pan.pos.y)
    check near(m.find("divisorio").y1, sc.pos.y)
    # niente fondo e niente schienale: dietro c'è il muro
    check not m.has("schienale") and not m.has("fondo")
    check near(m.find("piano letto").y1, p.profondita)
    for row in bom(m): check row.kind != kWall           # il muro non va in distinta

  test "una scatola dietro ogni gradino, profonda 30":
    var n = 0
    for q in m.parts:
      if q.name == "schiena gradino":
        inc n
        check near(q.pos.y, p.spessore + p.profGradini)
    check n == p.nGradini

  test "comodino a filo della risega, scaffali meno profondi":
    check abs(m.find("piano testata (comodino)").size.x - p.risegaLarga) < 0.2
    check near(m.find("ripiano libreria").size.x, 26)

  test "controlli: niente da segnalare, ma il materasso da 80 non entra":
    check p.controlli.len == 0
    var p3 = rilievo()
    p3.materasso[1] = 80
    check p3.controlli.len == 1 and "materasso largo 80" in p3.controlli[0]

  test "variante con tavolino":
    let pt = rilievo().conTavolino
    let mt = parete(pt)
    # il fronte ha un'apertura sola al posto dei primi 3 gradini
    check mt.find("fronte").holes.len == 1 + (pt.nGradini - pt.gradiniTavolino) + 1
    let fr = mt.find("frontale tavolino")
    check fr.holes.len == pt.gradiniTavolino and fr.gruppo == "tavolino"
    # estratto del tutto: il retro arriva al fronte del mobile
    var yMax = -Inf
    for q in mt.parts:
      if q.gruppo == "tavolino": yMax = max(yMax, q.y1)
    check near(yMax, 0)
    # il piano è un'altezza da tavolino per bambini e sta sotto il quarto gradino
    let piano = mt.find("piano tavolino")
    check piano.z1 > 55 and piano.z1 < 66
    # davanti poggia sui fianchi, da terra al piano; dietro su due gambe a pannello
    var gambe, fianchi = 0
    for q in mt.parts:
      if q.name == "gamba tavolino":
        inc gambe
        check near(q.pos.z, 0) and near(q.z1, piano.pos.z) and near(q.y1, piano.y1)
      if q.name == "fianco tavolino":
        inc fianchi
        check near(q.pos.z, 0) and near(q.z1, piano.pos.z)
    check gambe == 2 and fianchi == 2
    # un ripiano sotto ogni gradino e il fondo dei cassetti a profGradini dal frontale
    var ripiani = 0
    for q in mt.parts:
      if q.name == "ripiano gradino": inc ripiani
    check ripiani == pt.gradiniTavolino
    check near(mt.find("fondo cassetti").pos.y, fr.y1 + pt.profCassettiTavolino)
    # frontale e apertura a spigoli dritti: tondi solo i vani
    check fr.r == 0
    check pt.controlli.len == 0
    # chiuso, tutto sta dentro il mobile
    for q in parete(rilievo().conTavolino(aperto = false)).parts:
      if q.gruppo == "tavolino": check q.pos.y >= 0 and q.y1 <= pt.profondita

