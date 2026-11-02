import std/unittest
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

  test "vista laterale: 130, 130, 56 e 104, 27":
    check near(p.baseLibreria, 130)
    check near(p.soffittoNicchia, 260)
    check near(p.margineBasso + p.zonaBassa + p.fascia - p.pianoLetto, 27)

  test "il pannello frontale ha la nicchia e i gradini come aperture":
    check m.find("fronte").holes.len == 1 + p.nGradini

  test "tutto sta dentro l'ingombro (tranne il cassetto aperto)":
    for q in m.parts:
      if q.kind in {kBox, kKnob} and q.pos.y < 0: continue
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

  test "formato delle quote":
    check fmtNum(198.2) == "198.2"
    check fmtNum(316.0) == "316"
