## Tema dei documenti nimib: gli stessi colori, caratteri e modo chiaro/scuro
## degli artefatti claude.ai (spiegazione e visore 3D).
##
## Si usa con `nbInit(theme = useTema)`. Parte dal tema di nimib e sostituisce
## i fogli di stile da CDN (water.css, atom-one-light) con uno stile proprio.
## Il codice è già colorato da nimib alla generazione (classi `hljs-*`),
## quindi highlight.js nel browser non serve.

import std/json
import nimib
import nimib/themes as nbThemes

const fonts* = """<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:wght@500;600&family=IBM+Plex+Sans:ital,wght@0,400;0,500;0,600;1,400&family=IBM+Plex+Mono:wght@400;500&display=swap">"""

# I token di colore: valori chiari in :root, scuri se il sistema è in modo scuro.
const stile* = """<style>
:root {
  --bg: #eef0f1; --paper: #f8f9fa; --fg: #1d2429; --muted: #5b666e; --line: #cdd4d9;
  --accent: #a8682a; --code-bg: #e3e7ea; --out-bg: #f3efe6; --stage: #dfe3e6;
  --k: #8a3f86; --str: #2f7a43; --num: #a8682a; --com: #7b858c; --fn: #2b5f9e;
  --display: "Barlow Condensed", "Arial Narrow", sans-serif;
  --body: "IBM Plex Sans", system-ui, sans-serif;
  --mono: "IBM Plex Mono", ui-monospace, monospace;
}
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
  --bg: #161a1d; --paper: #1f2428; --fg: #e4e8ea; --muted: #9ba6ad; --line: #343c42;
  --accent: #e0a161; --code-bg: #232a2f; --out-bg: #2a2722; --stage: #23292d;
  --k: #d49ad0; --str: #8fd19e; --num: #e0a161; --com: #8a959c; --fn: #8db8ec; color-scheme: dark } }
:root[data-theme="dark"] {
  --bg: #161a1d; --paper: #1f2428; --fg: #e4e8ea; --muted: #9ba6ad; --line: #343c42;
  --accent: #e0a161; --code-bg: #232a2f; --out-bg: #2a2722; --stage: #23292d;
  --k: #d49ad0; --str: #8fd19e; --num: #e0a161; --com: #8a959c; --fn: #8db8ec; color-scheme: dark }
html, body { background: var(--bg); color: var(--fg); }
body { margin: 0; font: 16px/1.6 var(--body);
  padding-left: max(16px, env(safe-area-inset-left, 0px));
  padding-right: max(16px, env(safe-area-inset-right, 0px)); padding-block: 16px 40px; }
header, main, footer, section#source { max-width: 760px; margin: 0 auto; }
main { display: flow-root; }
main > p, main > ul, main > ol, main > blockquote { max-width: 68ch; }
.nb-box { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
header .nb-box { font-size: 14px; color: var(--muted); }
header .nb-box code { background: none; padding: 0; color: var(--muted); }
header svg { fill: currentColor; }
header svg path { fill: currentColor; }
header hr, footer hr { border: 0; border-top: 1px solid var(--line); margin: 10px 0 28px; }
footer { margin-top: 48px; padding-top: 12px; border-top: 1px solid var(--line); }
.nb-small { font-size: 13px; color: var(--muted); }
button { font: 500 13px var(--body); color: var(--fg); background: var(--paper); border: 1px solid var(--line);
  border-radius: 4px; padding: 5px 12px; cursor: pointer; }
button:hover { border-color: var(--accent); }
button:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
section#source { display: none; margin-top: 16px; }
h1, h2, h3 { font-family: var(--display); font-weight: 600; line-height: 1.1; text-wrap: balance; letter-spacing: 0.01em; }
h1 { font-size: clamp(34px, 7vw, 48px); margin: 0 0 16px; }
h2 { font-size: 28px; margin: 44px 0 10px; padding-top: 14px; border-top: 1px solid var(--line); }
h3 { font-size: 22px; margin: 28px 0 8px; }
p, ul, ol { margin: 0 0 14px; }
li { margin-bottom: 4px; }
a { color: var(--accent); }
strong { font-weight: 600; }
blockquote { margin: 18px 0; padding: 4px 0 4px 18px; border-left: 3px solid var(--accent); font-size: 19px; }
blockquote p { margin: 0; }
code { font-family: var(--mono); font-size: 0.88em; background: var(--code-bg); padding: 1px 5px; border-radius: 3px; }
pre { margin: 0 0 6px; padding: 12px 14px; background: var(--code-bg); border-radius: 4px; overflow-x: auto;
  font: 13.5px/1.55 var(--mono); }
pre code { background: none; padding: 0; font-size: inherit; }
pre.nb-output { background: var(--out-bg); border-left: 3px solid var(--accent); margin-bottom: 18px; white-space: pre-wrap; }
samp { font-family: var(--mono); }
pre + pre.nb-output { margin-top: -2px; }
.hljs-keyword, .hljs-built_in { color: var(--k); }
.hljs-string { color: var(--str); }
.hljs-number, .hljs-literal { color: var(--num); }
.hljs-comment { color: var(--com); font-style: italic; }
.hljs-title, .hljs-type { color: var(--fn); }
table { border-collapse: collapse; margin: 0 0 18px; font-size: 14.5px; display: block; overflow-x: auto; }
th, td { text-align: left; padding: 6px 14px 6px 0; border-bottom: 1px solid var(--line); vertical-align: top; }
th { font-family: var(--display); font-size: 15px; letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted); font-weight: 500; }
main svg { display: block; max-width: 100%; height: auto; margin: 6px 0 22px; border: 1px solid var(--line); border-radius: 4px; }
main > div[id$="3d"] { margin-top: 6px; }
</style>"""

proc useTema*(nb: var Nb) =
  nbThemes.useDefault(nb)
  nb.doc.context["stylesheet"] = %fonts
  nb.doc.context["highlight"] = %""
  nb.doc.context["nb_style"] = %stile
  nb.doc.context["disableHighlightJs"] = %true
