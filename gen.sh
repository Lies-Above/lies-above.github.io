#!/usr/bin/env sh
# Build the static GitHub Pages redirect tree from redirects.json.
#
# One self-contained HTML file per entry (no external resources, all CSS/JS
# inline, system fonts only). Each page forwards to the cited source via:
#   <link rel="canonical">      declares the destination to crawlers
#   <noscript> meta refresh     instant forward when JavaScript is off
#   inline script               shows a styled "being taken to <url>" notice;
#                               a one-time "always skip" choice saved in
#                               localStorage makes later pages forward at once
#                               (location.replace, no back-button trap)
#
# Routing mirrors the original Scaleway function: JSON key "fn5.1" is prefixed
# with the edition ("v1.") to form lookup ID "v1.fn5.1", emitted at
# /v1/fn5/1/index.html so the printed QR URL .../v1/fn5/1 resolves statically.
#
# Dependency: jq. It parses the JSON AND escapes every destination URL:
#   @html  -> safe inside double-quoted HTML attributes (escapes & < > " ')
#   @json  -> a quoted JS string literal for location.replace(...)
# The fields are base64-wrapped so a URL can never break the line protocol.
# Never parse redirects.json with grep/sed: that loses the escaping guarantees.
#
# Usage: ./gen.sh [redirects.json] [outDir]   (defaults: redirects.json, .)
set -eu

SRC="${1:-redirects.json}"
OUT="${2:-.}"

command -v jq >/dev/null 2>&1 || {
	echo "gen.sh: jq is required (https://jqlang.github.io/jq/)" >&2
	exit 1
}

TAB=$(printf '\t')

jq -r '
	to_entries[]
	| (("v1." + .key) | gsub("\\."; "/")) as $rel
	| (.value.url | sub("^[a-zA-Z][a-zA-Z0-9+.-]*://"; "")) as $bare
	| ($bare | sub("/.*$"; "")) as $host
	| (if ($bare | test("/")) then ($bare | sub("^[^/]+"; "")) else "" end) as $path
	| [ $rel,
	    (.key | @html | @base64),
	    (.value.url | @html | @base64),
	    (.value.url | @json | @base64),
	    ($host | @html | @base64),
	    ($path | @html | @base64) ]
	| @tsv
' "$SRC" | while IFS="$TAB" read -r rel b_id b_html b_json b_host b_path; do
	uid=$(printf '%s' "$b_id" | base64 -d)
	uhtml=$(printf '%s' "$b_html" | base64 -d)
	ujson=$(printf '%s' "$b_json" | base64 -d)
	uhost=$(printf '%s' "$b_host" | base64 -d)
	upath=$(printf '%s' "$b_path" | base64 -d)
	mkdir -p "$OUT/$rel"
	cat >"$OUT/$rel/index.html" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<link rel="canonical" href="$uhtml">
<meta name="robots" content="noindex">
<link rel="icon" type="image/png" href="/favicon.png">
<meta name="theme-color" content="#0b0b0c">
<title>Redirecting · Lies Above</title>
<noscript><meta http-equiv="refresh" content="0; url=$uhtml"></noscript>
<script>(function(){try{if(localStorage.getItem("la:skip")==="1")location.replace($ujson)}catch(e){}})()</script>
<style>
:root{--ink:#0b0b0c;--bg:#fff;--line:#e4e4e0;--grid:#efefea;--muted:#666;--faint:#70706c;--mono:ui-monospace,'SF Mono',SFMono-Regular,'Cascadia Mono','Segoe UI Mono','Roboto Mono',Menlo,Consolas,monospace;--sans:system-ui,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif}
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:var(--sans);color:var(--ink);line-height:1.5;background-color:var(--bg);background-image:linear-gradient(var(--grid) 1px,transparent 1px),linear-gradient(90deg,var(--grid) 1px,transparent 1px);background-size:46px 46px;background-position:center top;display:flex;flex-direction:column;min-height:100vh;-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale}
.bar{background:var(--ink);color:#fff;border-bottom:1px solid #000}
.bar-inner{max-width:64rem;margin:0 auto;padding:.95rem clamp(1.25rem,5vw,3.5rem);display:flex;align-items:center;justify-content:space-between;gap:1rem}
.brand{font-family:var(--mono);font-weight:800;letter-spacing:.2em;font-size:.95rem;color:#fff;text-decoration:none}
.bar-link{font-family:var(--mono);font-size:.7rem;letter-spacing:.14em;text-transform:uppercase;color:#b9b9b9;text-decoration:none;white-space:nowrap}
.bar-link:hover{color:#fff}
.wrap{flex:1;width:100%;max-width:64rem;margin:0 auto;background:var(--bg);border-inline:1px solid var(--line);padding:clamp(2.75rem,8vw,5rem) clamp(1.25rem,5vw,3.5rem);display:flex;flex-direction:column;justify-content:center}
.eyebrow{font-family:var(--mono);font-size:.7rem;letter-spacing:.24em;text-transform:uppercase;color:var(--faint);margin-bottom:1.1rem}
.h{font-size:clamp(1.45rem,4vw,1.95rem);font-weight:600;letter-spacing:-.01em;max-width:42rem}
.rule{width:48px;height:3px;background:var(--ink);margin:1.4rem 0}
.dest{display:inline-block;max-width:100%;font-family:var(--mono);font-size:.95rem;line-height:1.6;word-break:break-all;text-decoration:none;color:var(--ink)}
.dest::before{content:"↗";color:var(--ink);margin-right:.5rem}
.dest .host{font-weight:700;color:var(--ink)}
.dest .path{color:var(--faint)}
.dest:hover .host,.dest:hover .path{text-decoration:underline}
.cta{margin-top:1.9rem}
.go{display:inline-flex;align-items:center;gap:.55rem;font-family:var(--mono);font-size:.78rem;letter-spacing:.12em;text-transform:uppercase;color:#fff;background:var(--ink);text-decoration:none;border:1px solid var(--ink);padding:.78rem 1.3rem;min-height:24px}
.go:hover{background:#000}
.remember{margin-top:1.5rem;display:inline-flex;align-items:center;gap:.6rem;font-family:var(--mono);font-size:.74rem;letter-spacing:.02em;color:var(--muted);cursor:pointer}
.remember input{width:1rem;height:1rem;accent-color:#0b0b0c;cursor:pointer}
.note{margin-top:1.7rem;font-family:var(--mono);font-size:.68rem;letter-spacing:.04em;line-height:1.6;color:var(--faint);max-width:42rem}
.note a{color:var(--ink);text-decoration:underline;text-underline-offset:2px}
a:focus-visible,button:focus-visible,input:focus-visible{outline:2px solid var(--ink);outline-offset:2px}
.bar a:focus-visible{outline-color:#fff}
@media(prefers-reduced-motion:reduce){*{transition:none!important}}
</style>
</head>
<body>
<header class="bar"><div class="bar-inner">
<a class="brand" href="/">LIES ABOVE</a>
<a class="bar-link" href="https://liesabove.com" target="_blank" rel="noopener" aria-label="liesabove.com (opens in a new tab)">liesabove.com <span aria-hidden="true">&#8599;</span></a>
</div></header>
<main class="wrap">
<p class="eyebrow">Reference · $uid</p>
<p class="h">You&rsquo;re being taken to the cited source</p>
<div class="rule" aria-hidden="true"></div>
<a class="dest" href="$uhtml"><span class="host">$uhost</span><span class="path">$upath</span></a>
<div class="cta">
<a class="go" id="go" href="$uhtml">Continue to source <span aria-hidden="true">&rarr;</span></a>
</div>
<label class="remember"><input type="checkbox" id="skip"> Always go straight to sources, don&rsquo;t show this again</label>
<p class="note">This page only forwards you to the source it cites. Your choice is saved in this browser only, nothing is sent anywhere. To switch the preview back on later, visit <a href="/">liesabove.app</a> or clear your browser data for this site.</p>
</main>
<script>(function(){var c=document.getElementById("skip");document.getElementById("go").addEventListener("click",function(e){if(c.checked){try{localStorage.setItem("la:skip","1")}catch(_){}}e.preventDefault();location.replace($ujson)})})()</script>
</body>
</html>
EOF
done

cat >"$OUT/404.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>404 · Not Found</title>
<link rel="icon" type="image/png" href="/favicon.png">
<meta name="theme-color" content="#0b0b0c">
<style>
:root{
  --ink:#0b0b0c;--bg:#fff;--line:#e4e4e0;--grid:#efefea;--muted:#666;--faint:#70706c;
  --mono:ui-monospace,'SF Mono',SFMono-Regular,'Cascadia Mono','Segoe UI Mono','Roboto Mono',Menlo,Consolas,monospace;
  --sans:system-ui,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;
}
*{margin:0;padding:0;box-sizing:border-box}
body{
  font-family:var(--sans);color:var(--ink);line-height:1.5;background-color:var(--bg);
  background-image:linear-gradient(var(--grid) 1px,transparent 1px),linear-gradient(90deg,var(--grid) 1px,transparent 1px);
  background-size:46px 46px;background-position:center top;
  display:flex;flex-direction:column;min-height:100vh;
  -webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale
}
.bar{background:var(--ink);color:#fff;border-bottom:1px solid #000}
.bar-inner{max-width:64rem;margin:0 auto;padding:.95rem clamp(1.25rem,5vw,3.5rem);display:flex;align-items:center;justify-content:space-between;gap:1rem}
.brand{font-family:var(--mono);font-weight:800;letter-spacing:.2em;font-size:.95rem;color:#fff;text-decoration:none}
.bar-link{font-family:var(--mono);font-size:.7rem;letter-spacing:.14em;text-transform:uppercase;color:#b9b9b9;text-decoration:none;white-space:nowrap}
.bar-link:hover{color:#fff}
.wrap{flex:1;width:100%;max-width:64rem;margin:0 auto;background:var(--bg);border-inline:1px solid var(--line);padding:clamp(2.75rem,8vw,5rem) clamp(1.25rem,5vw,3.5rem);display:flex;flex-direction:column;justify-content:center}
.eyebrow{font-family:var(--mono);font-size:.7rem;letter-spacing:.24em;text-transform:uppercase;color:var(--faint);margin-bottom:1.1rem}
.c{font-family:var(--mono);font-weight:800;font-size:clamp(4.5rem,16vw,9rem);letter-spacing:-.04em;line-height:.9;color:var(--ink)}
.rule{width:48px;height:3px;background:var(--ink);margin:1.5rem 0}
.s{font-size:1.2rem;color:var(--ink);font-weight:600}
.n{margin-top:1.1rem;font-size:.95rem;line-height:1.65;color:var(--muted);max-width:42rem}
.n a{color:var(--ink);text-decoration:none;border-bottom:1px solid var(--ink);padding-bottom:1px}
.n a:hover,.n a:focus-visible{background:var(--ink);color:#fff}
.sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap;border:0}
.skip{position:absolute;left:.75rem;top:-4rem;z-index:20;background:var(--ink);color:#fff;font-family:var(--mono);font-size:.78rem;letter-spacing:.06em;padding:.65rem 1rem;text-decoration:none;border:1px solid #fff;transition:top .15s ease}
.skip:focus{top:.75rem}
a:focus-visible{outline:2px solid var(--ink);outline-offset:2px;border-radius:1px}
.bar a:focus-visible,.skip:focus-visible{outline:2px solid #fff;outline-offset:2px}
.bar a{min-height:24px;display:inline-flex;align-items:center}
main:focus{outline:none}
@media(prefers-reduced-motion:reduce){*{transition:none!important;scroll-behavior:auto!important}}
</style>
</head>
<body>
<a class="skip" href="#main">Skip to main content</a>
<header class="bar"><div class="bar-inner">
<a class="brand" href="/">LIES ABOVE</a>
<a class="bar-link" href="https://liesabove.com" target="_blank" rel="noopener" aria-label="liesabove.com (opens in a new tab)">liesabove.com <span aria-hidden="true">&#8599;</span></a>
</div></header>
<main class="wrap" id="main" tabindex="-1">
<p class="eyebrow">Error</p>
<h1 class="c">404</h1>
<div class="rule" aria-hidden="true"></div>
<p class="s">Not Found</p>
<p class="n">This reference could not be found. Browse <a href="/references/">all references</a> or return to <a href="/">the redirect home</a>.</p>
</main>
</body>
</html>
EOF

cat >"$OUT/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Lies Above</title>
<link rel="icon" type="image/png" href="/favicon.png">
<meta name="theme-color" content="#0b0b0c">
<script>
(function () {
  var id = (new URLSearchParams(location.search).get('id') || '').toLowerCase();
  if (id && /^[a-z0-9][a-z0-9.-]*$/.test(id) && id.indexOf('..') === -1) {
    location.replace('/' + id.split('.').join('/') + '/');
  }
})();
</script>
<style>
:root{
  --ink:#0b0b0c;--bg:#fff;--paper:#f4f4f1;--line:#e4e4e0;--grid:#efefea;--muted:#666;--faint:#70706c;
  --mono:ui-monospace,'SF Mono',SFMono-Regular,'Cascadia Mono','Segoe UI Mono','Roboto Mono',Menlo,Consolas,monospace;
  --sans:system-ui,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;
}
*{margin:0;padding:0;box-sizing:border-box}
body{
  font-family:var(--sans);color:var(--ink);line-height:1.5;background-color:var(--bg);
  background-image:linear-gradient(var(--grid) 1px,transparent 1px),linear-gradient(90deg,var(--grid) 1px,transparent 1px);
  background-size:46px 46px;background-position:center top;
  display:flex;flex-direction:column;min-height:100vh;
  -webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale
}
.bar{background:var(--ink);color:#fff;border-bottom:1px solid #000}
.bar-inner{max-width:64rem;margin:0 auto;padding:.95rem clamp(1.25rem,5vw,3.5rem);display:flex;align-items:center;justify-content:space-between;gap:1rem}
.brand{font-family:var(--mono);font-weight:800;letter-spacing:.2em;font-size:.95rem;color:#fff;text-decoration:none}
.bar-link{font-family:var(--mono);font-size:.7rem;letter-spacing:.14em;text-transform:uppercase;color:#b9b9b9;text-decoration:none;white-space:nowrap}
.bar-link:hover{color:#fff}
.wrap{flex:1;width:100%;max-width:64rem;margin:0 auto;background:var(--bg);border-inline:1px solid var(--line);padding:clamp(2.75rem,8vw,5rem) clamp(1.25rem,5vw,3.5rem);display:flex;flex-direction:column;justify-content:center}
.eyebrow{font-family:var(--mono);font-size:.7rem;letter-spacing:.24em;text-transform:uppercase;color:var(--faint);margin-bottom:1.1rem}
.t{font-family:var(--mono);font-weight:800;font-size:clamp(2.6rem,9vw,4.5rem);letter-spacing:-.03em;line-height:1;color:var(--ink)}
.rule{width:48px;height:3px;background:var(--ink);margin:1.5rem 0}
.s{font-size:1.1rem;line-height:1.5;color:var(--muted)}
.n{margin-top:1.3rem;font-size:.95rem;line-height:1.65;color:var(--muted);max-width:42rem}
.n a{color:var(--ink);text-decoration:none;border-bottom:1px solid var(--ink);padding-bottom:1px}
.n a:hover{background:var(--ink);color:#fff}
.cta{margin-top:1.9rem;display:flex;flex-wrap:wrap;gap:.85rem}
.cta a{display:inline-flex;align-items:center;gap:.55rem;font-family:var(--mono);font-size:.78rem;letter-spacing:.12em;text-transform:uppercase;color:var(--ink);text-decoration:none;border:1px solid var(--ink);padding:.7rem 1.2rem;min-height:24px;transition:background .15s ease,color .15s ease}
.cta a.ghost{border-color:var(--line);color:var(--muted)}
.cta a:hover,.cta a.ghost:hover{background:var(--ink);color:#fff;border-color:var(--ink)}
.cta a:focus-visible{outline:2px solid var(--ink);outline-offset:3px}
.cta .glyph{font-weight:700;letter-spacing:-.05em}
.nav{margin-top:2.1rem;display:flex;flex-wrap:wrap;gap:.7rem 1.4rem}
.nav a{font-family:var(--mono);font-size:.72rem;letter-spacing:.08em;text-transform:uppercase;color:var(--ink);text-decoration:none;border-bottom:1px solid var(--ink);padding-bottom:2px}
.nav a:hover{background:var(--ink);color:#fff}
.f{margin-top:2.2rem;font-family:var(--mono);font-size:.7rem;letter-spacing:.06em;text-transform:uppercase;color:var(--faint)}
.f a{color:var(--ink);text-decoration:none;border-bottom:1px solid var(--ink)}
.f a:hover,.f a:focus-visible{background:var(--ink);color:#fff}
.assure{margin-top:1.25rem;font-family:var(--mono);font-size:.7rem;letter-spacing:.1em;text-transform:uppercase;color:var(--faint);line-height:1.7}
.rp{display:inline-flex;flex-wrap:wrap;align-items:center;gap:.5rem;margin-top:1.1rem;font-family:var(--mono);font-size:.66rem;letter-spacing:.1em;text-transform:uppercase;color:var(--faint)}
.switch{display:inline-flex;align-items:center;gap:.5rem;font:inherit;letter-spacing:inherit;color:var(--muted);background:none;border:0;padding:0;cursor:pointer}
.switch-track{position:relative;flex:none;width:2.5rem;height:1.35rem;background:var(--bg);border:1px solid var(--line);border-radius:1rem;transition:background .15s ease,border-color .15s ease}
.switch-thumb{position:absolute;top:50%;left:.2rem;width:.95rem;height:.95rem;transform:translateY(-50%);background:var(--muted);border-radius:50%;transition:left .15s ease,background .15s ease}
.switch:hover .switch-track{border-color:var(--ink)}
.switch[aria-checked="true"] .switch-track{background:var(--ink);border-color:var(--ink)}
.switch[aria-checked="true"] .switch-thumb{left:calc(100% - .95rem - .2rem);background:#fff}
.switch-state{min-width:1.7rem;text-align:left}
.switch:focus-visible{outline:2px solid var(--ink);outline-offset:3px}
.nav a:hover,.nav a:focus-visible{background:var(--ink);color:#fff}
.n a:hover,.n a:focus-visible{background:var(--ink);color:#fff}
.sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap;border:0}
.skip{position:absolute;left:.75rem;top:-4rem;z-index:20;background:var(--ink);color:#fff;font-family:var(--mono);font-size:.78rem;letter-spacing:.06em;padding:.65rem 1rem;text-decoration:none;border:1px solid #fff;transition:top .15s ease}
.skip:focus{top:.75rem}
a:focus-visible{outline:2px solid var(--ink);outline-offset:2px;border-radius:1px}
.bar a:focus-visible,.skip:focus-visible{outline:2px solid #fff;outline-offset:2px}
.bar a,.nav a{min-height:24px;display:inline-flex;align-items:center}
main:focus{outline:none}
@keyframes rise{from{opacity:0;transform:translateY(9px)}to{opacity:1;transform:none}}
.mast>*{animation:rise .55s cubic-bezier(.22,.61,.36,1) both}
.mast .t{animation-delay:.05s}.mast .s{animation-delay:.1s}.mast .n{animation-delay:.15s}.mast .cta{animation-delay:.2s}.mast .nav{animation-delay:.25s}
@media(prefers-reduced-motion:reduce){*{animation:none!important;transition:none!important;scroll-behavior:auto!important}}
</style>
</head>
<body>
<a class="skip" href="#main">Skip to main content</a>
<header class="bar"><div class="bar-inner">
<a class="brand" href="/">LIES ABOVE</a>
<a class="bar-link" href="https://liesabove.com" target="_blank" rel="noopener" aria-label="liesabove.com (opens in a new tab)">liesabove.com <span aria-hidden="true">&#8599;</span></a>
</div></header>
<main class="wrap" id="main" tabindex="-1"><div class="mast">
<p class="eyebrow">URL Redirection Service</p>
<h1 class="t">Lies Above</h1>
<div class="rule" aria-hidden="true"></div>
<p class="s">How the Pentagon Misled Congress and Cost America its Skies</p>
<p class="n">The official home of the URL redirection service for <em>Lies Above</em>. Scan a QR code from the book to reach the source it cites. All you need is access to this website. There is nothing to download, install, run, or sign in to.</p>
<p class="assure">No download · No install · Nothing to run · No login</p>
<div class="cta">
<a href="https://youtu.be/jpPueBH-roM" target="_blank" rel="noopener" aria-label="Watch the trailer on YouTube (opens in a new tab)"><span aria-hidden="true">&#9656;</span> Watch the trailer</a>
<a class="ghost" href="https://github.com/Lies-Above/lies-above.github.io" target="_blank" rel="noopener" aria-label="View the app source code on GitHub (opens in a new tab)"><span class="glyph" aria-hidden="true">&lt;/&gt;</span> View the source <span aria-hidden="true">&#8599;</span></a>
</div>
<nav class="nav">
<a href="/references/">All references</a>
<a href="/bibliography/">Bibliography</a>
<a href="/index/">Index</a>
<a href="/ai/">AI Use</a>
<a href="/privacy/">Privacy</a>
</nav>
<p class="f">Or visit <a href="https://liesabove.com">liesabove.com</a>, where you can see more of my UAP content.</p>
<p class="rp"><span id="rp-label">Redirect preview</span> <button type="button" id="rp-toggle" class="switch" role="switch" aria-checked="true" aria-labelledby="rp-label"><span class="switch-track" aria-hidden="true"><span class="switch-thumb"></span></span><span class="switch-state" id="rp-state" aria-hidden="true">On</span></button></p>
</div></main>
<script>(function(){var t=document.getElementById("rp-toggle");if(!t)return;var st=document.getElementById("rp-state");function skip(){try{return localStorage.getItem("la:skip")==="1"}catch(e){return false}}function p(){var on=!skip();t.setAttribute("aria-checked",on?"true":"false");if(st)st.textContent=on?"On":"Off"}t.addEventListener("click",function(){try{if(skip())localStorage.removeItem("la:skip");else localStorage.setItem("la:skip","1")}catch(e){}p()});p()})()</script>
</body>
</html>
EOF

# Human-readable reference index: every entry from redirects.json shown with its
# destination URL in plain text, so a reader can see where a QR code leads before
# scanning it. Client-side filter only; no data leaves the page. jq @html escapes
# every key/description/URL before it reaches the HTML.
mkdir -p "$OUT/references"
cat >"$OUT/references/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>References · Lies Above</title>
<link rel="icon" type="image/png" href="/favicon.png">
<meta name="theme-color" content="#0b0b0c">
<meta name="robots" content="noindex">
<style>
:root{
  --ink:#0b0b0c;--bg:#fff;--paper:#f4f4f1;--line:#e4e4e0;--grid:#efefea;--muted:#666;--faint:#70706c;
  --mono:ui-monospace,'SF Mono',SFMono-Regular,'Cascadia Mono','Segoe UI Mono','Roboto Mono',Menlo,Consolas,monospace;
  --sans:system-ui,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;
}
*{margin:0;padding:0;box-sizing:border-box}
body{
  font-family:var(--sans);color:var(--ink);line-height:1.5;background-color:var(--bg);
  background-image:linear-gradient(var(--grid) 1px,transparent 1px),linear-gradient(90deg,var(--grid) 1px,transparent 1px);
  background-size:46px 46px;background-position:center top;
  -webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale
}
.bar{background:var(--ink);color:#fff;border-bottom:1px solid #000}
.bar-inner{max-width:64rem;margin:0 auto;padding:.95rem clamp(1.25rem,5vw,3.5rem);display:flex;align-items:center;justify-content:space-between;gap:1rem}
.brand{font-family:var(--mono);font-weight:800;letter-spacing:.2em;font-size:.95rem;color:#fff;text-decoration:none}
.bar-link{font-family:var(--mono);font-size:.7rem;letter-spacing:.14em;text-transform:uppercase;color:#b9b9b9;text-decoration:none;white-space:nowrap}
.bar-link:hover{color:#fff}
.wrap{max-width:64rem;margin:0 auto;background:var(--bg);border-inline:1px solid var(--line);min-height:100vh}
.pad{padding-inline:clamp(1.25rem,5vw,3.5rem)}
.mast{padding-top:clamp(2.5rem,6vw,4.25rem);padding-bottom:1.75rem;border-bottom:1px solid var(--line)}
.eyebrow{font-family:var(--mono);font-size:.7rem;letter-spacing:.24em;text-transform:uppercase;color:var(--faint);margin-bottom:1.1rem}
.t{font-family:var(--mono);font-weight:800;font-size:clamp(2.4rem,7vw,4rem);letter-spacing:-.02em;line-height:1;color:var(--ink)}
.s{font-size:1.05rem;color:var(--muted);margin-top:1.1rem}
.s em{font-style:italic}
.lead{font-size:.95rem;color:var(--muted);margin-top:.55rem;max-width:42rem;line-height:1.6}
.crumbs{max-width:64rem;margin:0 auto;width:100%;background:var(--bg);border-inline:1px solid var(--line);border-bottom:1px solid var(--line);padding:.7rem clamp(1.25rem,5vw,3.5rem)}
.crumbs ol{list-style:none;display:flex;flex-wrap:wrap;align-items:center;gap:.5rem;font-family:var(--mono);font-size:.68rem;letter-spacing:.12em;text-transform:uppercase}
.crumbs li{display:flex;align-items:center;gap:.5rem}
.crumbs li+li::before{content:"\203A";color:var(--faint)}
.crumbs a{color:var(--muted);text-decoration:none;border-bottom:1px solid transparent;min-height:24px;display:inline-flex;align-items:center}
.crumbs a:hover,.crumbs a:focus-visible{color:var(--ink);border-bottom-color:var(--ink)}
.crumbs [aria-current="page"]{color:var(--ink)}
.search{position:sticky;top:0;background:var(--bg);padding-top:1.1rem;padding-bottom:1.1rem;border-bottom:1px solid var(--ink);z-index:4}
#q{width:100%;font-family:var(--mono);font-size:.95rem;padding:.85rem 1rem;border:1px solid var(--ink);border-radius:0;color:var(--ink);background:var(--bg)}
#q::placeholder{color:var(--faint)}
#q:focus-visible{outline:2px solid var(--ink);outline-offset:2px}
.count{font-family:var(--mono);font-size:.7rem;letter-spacing:.14em;text-transform:uppercase;color:var(--faint);margin-top:.75rem}
.list{list-style:none}
.item{display:grid;grid-template-columns:6.75rem minmax(0,1fr);gap:.3rem 1.6rem;padding:1.3rem 0;border-bottom:1px solid var(--line);transition:background .15s ease;scroll-margin-top:7rem}
.item:hover,.item:focus-within{background:var(--paper)}
.item:focus-within .ref{background:var(--ink);color:#fff}
.ref{font-family:var(--mono);font-size:.72rem;color:var(--ink);background:var(--bg);border:1px solid var(--ink);border-radius:0;padding:.32rem .55rem;justify-self:start;align-self:start;display:inline-flex;align-items:center;justify-content:center;min-width:3.5rem;text-align:center;white-space:nowrap;line-height:1.2;transition:background .15s ease,color .15s ease}
.item:hover .ref{background:var(--ink);color:#fff}
.body{min-width:0}
.desc{color:#1a1a1a;font-size:.98rem;line-height:1.62;overflow-wrap:break-word}
.dest{display:inline-block;max-width:100%;margin-top:.6rem;font-family:var(--mono);font-size:.8rem;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;vertical-align:bottom;text-decoration:none}
.dest::before{content:"\2197";color:var(--ink);margin-right:.45rem}
.dest .host{font-weight:700;color:var(--ink)}
.dest .path{color:var(--faint)}
.dest:hover .host,.dest:focus-visible .host{text-decoration:underline}
.dest:hover .path,.dest:focus-visible .path{color:var(--muted);text-decoration:underline}
@media(max-width:560px){.item{grid-template-columns:minmax(0,1fr);gap:.55rem}}
.foot{font-family:var(--mono);font-size:.7rem;letter-spacing:.1em;text-transform:uppercase;color:var(--faint);text-align:center;padding:2.5rem 1.25rem 3rem}
.foot a{color:var(--ink);text-decoration:none;border-bottom:1px solid var(--ink);padding-bottom:1px}
.foot a:hover,.foot a:focus-visible{background:var(--ink);color:#fff}
.rp{display:inline-flex;flex-wrap:wrap;align-items:center;gap:.5rem;margin-top:1.1rem;font-family:var(--mono);font-size:.66rem;letter-spacing:.1em;text-transform:uppercase;color:var(--faint)}
.switch{display:inline-flex;align-items:center;gap:.5rem;font:inherit;letter-spacing:inherit;color:var(--muted);background:none;border:0;padding:0;cursor:pointer}
.switch-track{position:relative;flex:none;width:2.5rem;height:1.35rem;background:var(--bg);border:1px solid var(--line);border-radius:1rem;transition:background .15s ease,border-color .15s ease}
.switch-thumb{position:absolute;top:50%;left:.2rem;width:.95rem;height:.95rem;transform:translateY(-50%);background:var(--muted);border-radius:50%;transition:left .15s ease,background .15s ease}
.switch:hover .switch-track{border-color:var(--ink)}
.switch[aria-checked="true"] .switch-track{background:var(--ink);border-color:var(--ink)}
.switch[aria-checked="true"] .switch-thumb{left:calc(100% - .95rem - .2rem);background:#fff}
.switch-state{min-width:1.7rem;text-align:left}
.switch:focus-visible{outline:2px solid var(--ink);outline-offset:3px}
.sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap;border:0}
.skip{position:absolute;left:.75rem;top:-4rem;z-index:20;background:var(--ink);color:#fff;font-family:var(--mono);font-size:.78rem;letter-spacing:.06em;padding:.65rem 1rem;text-decoration:none;border:1px solid #fff;transition:top .15s ease}
.skip:focus{top:.75rem}
a:focus-visible{outline:2px solid var(--ink);outline-offset:2px;border-radius:1px}
.bar a:focus-visible,.skip:focus-visible{outline:2px solid #fff;outline-offset:2px}
.bar a{min-height:24px;display:inline-flex;align-items:center}
main:focus{outline:none}
@keyframes rise{from{opacity:0;transform:translateY(9px)}to{opacity:1;transform:none}}
.mast>*{animation:rise .55s cubic-bezier(.22,.61,.36,1) both}
.mast .t{animation-delay:.05s}.mast .s{animation-delay:.12s}.mast .lead{animation-delay:.18s}
@media(prefers-reduced-motion:reduce){*{animation:none!important;transition:none!important;scroll-behavior:auto!important}}
</style>
</head>
<body>
<a class="skip" href="#main">Skip to main content</a>
<header class="bar"><div class="bar-inner">
<a class="brand" href="/">LIES ABOVE</a>
<a class="bar-link" href="https://liesabove.com" target="_blank" rel="noopener" aria-label="liesabove.com (opens in a new tab)">liesabove.com <span aria-hidden="true">&#8599;</span></a>
</div></header>
<nav class="crumbs" aria-label="Breadcrumb"><ol>
<li><a href="/">Home</a></li>
<li><span aria-current="page">References</span></li>
</ol></nav>
<main class="wrap" id="main" tabindex="-1">
<div class="mast pad">
<p class="eyebrow">Reference Index</p>
<h1 class="t">References</h1>
<p class="s">Every source cited in <em>Lies Above</em>.</p>
<p class="lead">Each QR code in the book points to one of the links below. Search to see exactly where a code leads before you scan it. Links open in a new tab.</p>
</div>
<div class="search pad" role="search">
<label class="sr-only" for="q">Search references by code, description, or URL</label>
<input id="q" type="search" placeholder="Search by reference, description, or URL…" autocomplete="off" autocapitalize="off" spellcheck="false" aria-describedby="count">
<p class="count" id="count" role="status" aria-live="polite"></p>
</div>
<ul class="list pad" id="rows">
EOF

jq -r '
	to_entries
	| sort_by([ (.key | gsub("[0-9.]+"; "")), (.key | [scan("[0-9]+") | tonumber]) ])
	| .[]
	| .key as $k
	| ((.value.description // "—")) as $d
	| .value.url as $url
	| ($url | sub("^[a-zA-Z][a-zA-Z0-9+.-]*://"; "")) as $bare
	| ($bare | sub("/.*$"; "")) as $host
	| (if ($bare | test("/")) then ($bare | sub("^[^/]+"; "")) else "" end) as $path
	| "<li class=\"item\"><div class=\"ref\">" + ($k | @html)
		+ "</div><div class=\"body\"><p class=\"desc\">" + ($d | @html)
		+ "</p><a class=\"dest\" href=\"" + ($url | @html)
		+ "\" title=\"" + ($url | @html)
		+ "\" target=\"_blank\" rel=\"noopener nofollow\"><span class=\"host\">" + ($host | @html)
		+ "</span><span class=\"path\">" + ($path | @html)
		+ "</span><span class=\"sr-only\"> (opens in a new tab)</span></a></div></li>"
' "$SRC" >>"$OUT/references/index.html"

cat >>"$OUT/references/index.html" <<'EOF'
</ul>
</main>
<footer class="foot">Back to <a href="/">the redirect home</a> &nbsp;&middot;&nbsp; <a href="https://liesabove.com">liesabove.com</a><br><span class="rp"><span id="rp-label">Redirect preview</span> <button type="button" id="rp-toggle" class="switch" role="switch" aria-checked="true" aria-labelledby="rp-label"><span class="switch-track" aria-hidden="true"><span class="switch-thumb"></span></span><span class="switch-state" id="rp-state" aria-hidden="true">On</span></button></span></footer>
<script>
(function () {
  var q = document.getElementById('q');
  var count = document.getElementById('count');
  var rows = Array.prototype.slice.call(document.querySelectorAll('#rows .item'));
  function render() {
    var v = q.value.trim().toLowerCase();
    var n = 0;
    for (var i = 0; i < rows.length; i++) {
      var show = !v || rows[i].textContent.toLowerCase().indexOf(v) !== -1;
      rows[i].style.display = show ? '' : 'none';
      if (show) n++;
    }
    count.textContent = n + (n === 1 ? ' reference' : ' references');
  }
  q.addEventListener('input', render);
  render();
})();
</script>
<script>(function(){var t=document.getElementById("rp-toggle");if(!t)return;var st=document.getElementById("rp-state");function skip(){try{return localStorage.getItem("la:skip")==="1"}catch(e){return false}}function p(){var on=!skip();t.setAttribute("aria-checked",on?"true":"false");if(st)st.textContent=on?"On":"Off"}t.addEventListener("click",function(){try{if(skip())localStorage.removeItem("la:skip");else localStorage.setItem("la:skip","1")}catch(e){}p()});p()})()</script>
</body>
</html>
EOF

echo "generated redirect tree into $OUT"
