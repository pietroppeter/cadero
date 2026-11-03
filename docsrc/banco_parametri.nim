## Il banco dei parametri (gira nel browser, compilato in JavaScript dal
## documento `parametri.nim`): un cursore per ogni parametro della parete,
## raggruppati come in `models/parete_parametri.nim`. A ogni modifica si
## ricalcola il modello con lo stesso `parete(p)` delle tavole e si aggiornano
## visore 3D, misure derivate, schema delle catene, avvisi e tavole.

import std/[strutils, tables]
import ../src/cadero/visore, ../src/cadero/drawing, ../src/cadero/js/pagina
import ../models/[parete, parete_parametri]

proc impostaHtml(e: Element; s: cstring) {.importjs: "#.innerHTML = #".}
proc html(e: Element; s: string) = e.impostaHtml(cstring(s))
proc dato(e: Element; k: cstring): cstring {.importjs: "(#.dataset[#] || '')".}
proc spunta(e: Element): bool {.importjs: "#.checked".}
proc `spunta=`(e: Element; v: bool) {.importjs: "#.checked = #".}
proc tipoInput(e: Element): cstring {.importjs: "#.type".}
proc mostraInVista(e: Element) {.importjs: "#.scrollIntoView({behavior: 'smooth', block: 'start'})".}
proc tutti(sel: cstring): seq[Element] {.importjs: "Array.from(document.querySelectorAll(#))".}
proc testo(e: Element): cstring {.importjs: "#.value".}
proc `testo=`(e: Element; s: cstring) {.importjs: "#.value = #".}
proc focus(e: Element) {.importjs: "#.focus()".}
{.emit: """
function caderoCopia(t, fatto) {
  if (navigator.clipboard && navigator.clipboard.writeText)
    navigator.clipboard.writeText(t).then(() => fatto(true), () => fatto(false));
  else fatto(false);
}
function caderoLeggi(fatto) {
  if (navigator.clipboard && navigator.clipboard.readText)
    navigator.clipboard.readText().then((t) => fatto(t), () => fatto(''));
  else fatto('');
}
""".}
proc copiaNegliAppunti(s: cstring; fatto: proc (ok: bool)) {.importjs: "caderoCopia(#, #)".}
proc leggiAppunti(fatto: proc (s: cstring)) {.importjs: "caderoLeggi(#)".}

var
  p: Parete
  inAttesa = false
  visoreAvviato = false

proc iniziale(): Parete =
  result = rilievo()
  result.disegno.cassettoAperto = -1   # nel visore tutto parte chiuso: si apre toccando

proc controlliHtml(): string =
  ## I cursori, un gruppo per riquadro (`<details>`).
  let base = iniziale()
  for i, g in gruppi():
    result.add "<details class=\"gruppo\"" & (if i < 2: " open" else: "") & "><summary>" & g.nome &
      "</summary><p class=\"spiega\">" & g.spiega & "</p>"
    for q in g.params:
      let id = "c-" & q.campo
      let v = base.valore(q.campo)
      let orig = "<span class=\"orig o-" & $q.origine & "\">" & $q.origine & "</span>"
      if q.origine == oVariante:
        result.add "<label class=\"riga bool\"><input type=\"checkbox\" data-campo=\"" & q.campo & "\"" &
          (if v > 0.5: " checked" else: "") & "> " & q.etichetta & "</label>"
      else:
        result.add "<div class=\"riga\" data-riga=\"" & q.campo & "\"><label for=\"" & id & "\">" & q.etichetta &
          " " & orig & "</label><div class=\"cursore\"><input type=\"range\" id=\"" & id &
          "\" data-campo=\"" & q.campo & "\" min=\"" & $q.min & "\" max=\"" & $q.max &
          "\" step=\"" & $q.passo & "\" value=\"" & $v & "\"><input type=\"number\" data-campo=\"" &
          q.campo & "\" min=\"" & $q.min & "\" max=\"" & $q.max & "\" step=\"" & $q.passo &
          "\" value=\"" & $v & "\" aria-label=\"" & q.etichetta & "\"></div>"
        if q.nota.len > 0: result.add "<small>" & q.nota & "</small>"
        if q.campo.startsWith("libreria.vani."): result.add "<small class=\"vano\"></small>"
        result.add "</div>"
    result.add "</details>"

proc testoValore(q: Param; v: float): string =
  if q.origine == oVariante: (if v > 0.5: "sì" else: "no") else: fmtNum(v)

proc cambiati(): seq[(Param, float, float)] =
  ## I parametri diversi dal rilievo: (parametro, valore del rilievo, valore ora).
  let base = iniziale()
  for g in gruppi():
    for q in g.params:
      let (a, b) = (base.valore(q.campo), p.valore(q.campo))
      if abs(a - b) > 1e-6: result.add (q, a, b)

proc testoDaCopiare(): string =
  ## Si incolla così com'è in una richiesta ("cambia i valori di default così")
  ## o di nuovo nel banco con Incolla.
  let c = cambiati()
  result = "Parametri della parete cambiati rispetto al rilievo (" & $c.len & "):\n"
  for (q, a, b) in c:
    result.add "- " & q.campo & " (" & q.etichetta & "): " & q.testoValore(a) & " → " & q.testoValore(b) & "\n"

proc leggiTesto(t: string): (int, seq[string]) =
  ## Applica le righe `campo: vecchio → nuovo` o `campo = valore`: conta l'ultimo
  ## numero (o sì/no) della riga. Torna quanti ne ha applicati e le righe non capite.
  var noti: Table[string, Param]
  for g in gruppi():
    for q in g.params: noti[q.campo] = q
  var nuovo = iniziale()
  var n = 0
  var scarti: seq[string]
  for riga0 in t.splitLines:
    var riga = riga0.strip
    if riga.startsWith("-") or riga.startsWith("*"): riga = riga[1..^1].strip
    if riga.len == 0 or riga.endsWith(":"): continue   # vuote e intestazioni
    var campo = ""
    for ch in riga:
      if ch in {'a'..'z', 'A'..'Z', '0'..'9', '.', '_'}: campo.add ch
      else: break
    if campo notin noti:
      if ':' in riga or '=' in riga: scarti.add riga0.strip
      continue
    let parole = riga.multiReplace(("=", " "), (":", " "), ("→", " "), ("(", " "), (")", " ")).splitWhitespace
    var trovato = false
    for i in countdown(parole.high, 1):
      let w = parole[i].toLowerAscii
      if w in ["sì", "si", "true", "vero"]: nuovo.imposta(campo, 1.0); trovato = true
      elif w in ["no", "false", "falso"]: nuovo.imposta(campo, 0.0); trovato = true
      else:
        try:
          nuovo.imposta(campo, parseFloat(w.replace(",", "."))); trovato = true
        except ValueError: discard
      if trovato: break
    if trovato: inc n else: scarti.add riga0.strip
  if n > 0: p = nuovo
  (n, scarti)

proc elencoCambiati(): string =
  let c = cambiati()
  if c.len == 0: return ""
  result = "<table>"
  for (q, a, b) in c:
    result.add "<tr><td>" & q.etichetta & "<br><code>" & q.campo & "</code></td><td class=\"num\">" &
      q.testoValore(a) & " → <b>" & q.testoValore(b) & "</b></td></tr>"
  result.add "</table>"

proc allinea() =
  ## Gli input mostrano i valori di `p`; quelli cambiati rispetto al rilievo si vedono.
  let base = iniziale()
  var cambiati = 0
  for e in tutti("[data-campo]"):
    let campo = $e.dato("campo")
    let v = p.valore(campo)
    if e.tipoInput == "checkbox": e.spunta = v > 0.5
    else: e.valore = v
  for g in gruppi():
    for q in g.params:
      let diverso = abs(p.valore(q.campo) - base.valore(q.campo)) > 1e-6
      if diverso: inc cambiati
      let r = document.querySelector(cstring("[data-riga=\"" & q.campo & "\"]"))
      if r != nil: r.toggleClass("cambiato", diverso)
  # i vani: se ne vedono n + 1; accanto, quanto vale ciascuno (fissato o libero)
  let q = sicuro(p)
  let v = q.vani
  for i in 0 ..< maxVani:
    let r = document.querySelector(cstring("[data-riga=\"libreria.vani." & $i & "\"]"))
    if r == nil: continue
    r.nascosto(i > q.libreria.scaffali)
    if i < v.len:
      let fissato = i < q.libreria.vani.len and q.libreria.vani[i] > 0
      r.querySelector(".vano").textContent = cstring((if fissato: "fissato: " else: "libero: ") & fmtNum(v[i]) & " cm")
  el("n-cambiati").textContent = cstring(if cambiati == 0: "valori del rilievo"
                                         elif cambiati == 1: "1 parametro cambiato"
                                         else: $cambiati & " parametri cambiati")
  el("cambiati").nascosto(cambiati == 0)
  el("copia").nascosto(cambiati == 0)
  el("elenco-cambiati").html(elencoCambiati())

proc aggiorna() =
  inAttesa = false
  let q = sicuro(p)
  var avvisi: seq[string]
  try:
    let m = parete(q)
    if visoreAvviato: mostra(m)
    avvisi = q.controlli & fuoriMuro(q, m) & fuoriLastra(m)
    el("tavola-attuale").html(tavola(q, m))
    el("tavola-proposta").html(tavolaProposta(q, m))
  except Exception as e:
    avvisi.add "il modello non si calcola con questi valori: " & e.msg
  el("derivate").html(tabellaDerivate(q))
  el("catene").html(schemaCatene(q))
  var a = ""
  for t in avvisi: a.add "<li>" & t & "</li>"
  el("avvisi").html(if a.len > 0: "<ul>" & a & "</ul>" else: "<p>nessun controllo scatta</p>")
  el("avvisi").toggleClass("vuoto", avvisi.len == 0)
  var r = "L <b>" & fmtNum(q.larghezza) & "</b> × H <b>" & fmtNum(q.altezza) & "</b> × P <b>" &
    fmtNum(q.profondita) & "</b>"
  for d in q.derivate:
    if d.nome in ["Bordo davanti al materasso", "Schienale sopra il materasso", "Spazio tra le ribalte"]:
      r.add " · <span" & (if d.allarme: " class=\"allarme\"" else: "") & ">" &
        d.nome.toLowerAscii & " <b>" & fmtNum(d.valore) & "</b></span>"
  el("riassunto").html(r)
  allinea()

proc chiedi() =
  ## Un aggiornamento per fotogramma, anche se il cursore manda tanti eventi.
  if not inAttesa:
    inAttesa = true
    prossimoFotogramma(proc (t: float) = aggiorna())

proc prova(testo: string) =
  ## "campo=valore,campo=valore": si parte dal rilievo e si cambiano quelli.
  p = iniziale()
  for coppia in testo.split(","):
    let kv = coppia.split("=")
    if kv.len == 2: p.imposta(kv[0].strip, parseFloat(kv[1].strip))
  aggiorna()

proc avviaBanco*(carta: Carta) =
  p = iniziale()
  el("controlli").html(controlliHtml())
  let campi = tutti("[data-campo]")
  for i in 0 ..< campi.len:
    closureScope:
      let e = campi[i]
      let campo = $e.dato("campo")
      e.addEventListener("input", proc (ev: Event) =
        if e.tipoInput == "checkbox": p.imposta(campo, if e.spunta: 1.0 else: 0.0)
        elif ($e.dato("x")).len == 0 and e.valore == e.valore:   # NaN mentre si scrive
          p.imposta(campo, e.valore)
        chiedi())
  el("ripristina").addEventListener("click", proc (ev: Event) =
    p = iniziale(); aggiorna())
  el("copia").addEventListener("click", proc (ev: Event) =
    let t = testoDaCopiare()
    copiaNegliAppunti(cstring(t), proc (ok: bool) =
      if ok:
        el("copia").textContent = "Copiato ✓"
        discard setTimeout(proc () = el("copia").textContent = "Copia", 1500)
      else:
        # niente appunti (es. dentro un iframe): il testo resta nel riquadro da copiare a mano
        el("box-incolla").nascosto(false)
        el("testo-incolla").testo = cstring(t)
        el("esito-incolla").textContent = "copia a mano il testo qui sopra"
        el("testo-incolla").focus()))
  el("incolla").addEventListener("click", proc (ev: Event) =
    el("box-incolla").nascosto(false)
    el("esito-incolla").textContent = ""
    leggiAppunti(proc (t: cstring) =
      if t.len > 0: el("testo-incolla").testo = t
      el("testo-incolla").focus()))
  el("annulla-incolla").addEventListener("click", proc (ev: Event) =
    el("box-incolla").nascosto(true))
  el("applica").addEventListener("click", proc (ev: Event) =
    let (n, scarti) = leggiTesto($el("testo-incolla").testo)
    var esito = if n == 0: "nessun parametro riconosciuto" else: "applicati " & $n & " parametri"
    if scarti.len > 0: esito.add " · non capite: " & scarti.join("; ")
    el("esito-incolla").textContent = cstring(esito)
    if n > 0:
      el("cambiati").setAttribute("open", "")
      aggiorna())
  let prove = tutti("button[data-prova]")
  for i in 0 ..< prove.len:
    closureScope:
      let b = prove[i]
      b.addEventListener("click", proc (ev: Event) =
        prova($b.dato("prova"))
        el("banco").mostraInVista())
  aggiorna()
  quandoThreePronto(proc () =
    avviaVisore({"base": parete(sicuro(p))}.toTable, carta)
    visoreAvviato = true)
