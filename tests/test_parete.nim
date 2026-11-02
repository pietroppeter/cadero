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

  test "vista laterale: piano letto 104, testata 55, libreria 128 in tutto":
    check near(p.baseLibreria - p.pianoLetto, 55)     # testata (= comodino)
    check near(p.cimaLibreria - p.pianoLetto, 128)    # libreria, testata compresa
    check near(p.soffittoNicchia, 260)
    check near(p.margineBasso + p.zonaBassa + p.fascia - p.pianoLetto, 27)

  test "il pannello frontale ha la nicchia e i gradini come aperture":
    check m.find("fronte").holes.len == 1 + p.nGradini

  test "tutto sta dentro l'ingombro (tranne il cassetto aperto)":
    for q in m.parts:
      if q.kind in {kBox, kKnob} and q.pos.y < 0: continue
      if q.kind == kSoft: continue      # il materasso lo verificano i controlli
      check q.pos.x >= -0.01 and q.x1 <= p.larghezza + 0.01
      check q.pos.z >= -0.01 and q.z1 <= p.altezza + 0.01
      check q.pos.y >= -0.01 and q.y1 <= p.profondita + 0.01

  test "il materasso sta sotto il bordo della fascia":
    let mat = m.find("materasso")
    check mat.z1 < p.catenaFronte[3]

  test "distinta":
    var cassetti = 0
    for r in bom(m):
      if r.kind == kBox: cassetti += r.count
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
    check near(pan.pos.y, p.profColonna) and near(pan.size.z, p.cimaLibreria - p.baseLibreria)
    for row in bom(m): check row.kind != kWall           # il muro non va in distinta

  test "una scatola dietro ogni gradino, profonda 30":
    var n = 0
    for q in m.parts:
      if q.name == "schiena gradino":
        inc n
        check near(q.pos.y, p.spessore + p.profGradini)
    check n == p.nGradini

  test "comodino a filo della risega, scaffali meno profondi":
    check near(m.find("piano testata (comodino)").size.x, 38)
    check near(m.find("ripiano libreria").size.x, 22)

  test "i controlli trovano il materasso da 80 che non entra":
    check p.controlli.len > 0
    check "materasso largo 80" in p.controlli[0]
    var p3 = rilievo()
    p3.materasso[1] = 76
    for c in p3.controlli: check "materasso largo" notin c
