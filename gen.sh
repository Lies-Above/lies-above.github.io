#!/usr/bin/env sh
# Build the static GitHub Pages redirect tree from redirects.json.
#
# One self-contained HTML file per entry, redirecting via three independent
# mechanisms (no external resources, works with or without JavaScript):
#   <meta http-equiv="refresh">   instant redirect, no JS required
#   <link rel="canonical">        declares the canonical destination to crawlers
#   location.replace(...)         instant redirect, no back-button trap
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
	| [ $rel, (.value.url | @html | @base64), (.value.url | @json | @base64) ]
	| @tsv
' "$SRC" | while IFS="$TAB" read -r rel b_html b_json; do
	uhtml=$(printf '%s' "$b_html" | base64 -d)
	ujson=$(printf '%s' "$b_json" | base64 -d)
	mkdir -p "$OUT/$rel"
	cat >"$OUT/$rel/index.html" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="refresh" content="0; url=$uhtml">
<link rel="canonical" href="$uhtml">
<meta name="robots" content="noindex">
<title>Redirecting…</title>
<script>window.location.replace($ujson)</script>
</head>
<body style="margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;font-family:Georgia,'Times New Roman',serif;background:#ebebeb;color:#1a1a1a">
<p>Redirecting to <a href="$uhtml">$uhtml</a>…</p>
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
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{
  font-family:Georgia,'Times New Roman','Iowan Old Style','Palatino Linotype',serif;
  background:#ebebeb;color:#1a1a1a;min-height:100vh;
  display:flex;align-items:center;justify-content:center;padding:2rem;
  -webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale
}
.e{text-align:center;max-width:480px}
.c{font-size:clamp(5rem,12vw,8rem);font-weight:400;color:#1c516c;letter-spacing:-.04em;line-height:1;margin-bottom:1rem}
.d{width:48px;height:2px;background:#1c516c;margin:0 auto 1.5rem;border-radius:1px}
h1{font-size:1.35rem;font-weight:400;color:#1a1a1a;margin-bottom:.75rem;letter-spacing:-.02em}
p{font-size:.95rem;color:#666;line-height:1.6;letter-spacing:-.01em}
</style>
</head>
<body>
<div class="e">
<div class="c">404</div>
<div class="d"></div>
<h1>Not Found</h1>
<p>This reference could not be found.</p>
</div>
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
<script>
(function () {
  var id = (new URLSearchParams(location.search).get('id') || '').toLowerCase();
  if (id && /^[a-z0-9][a-z0-9.-]*$/.test(id) && id.indexOf('..') === -1) {
    location.replace('/' + id.split('.').join('/') + '/');
  }
})();
</script>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{
  font-family:Georgia,'Times New Roman','Iowan Old Style','Palatino Linotype',serif;
  background:#ebebeb;color:#1a1a1a;min-height:100vh;
  display:flex;align-items:center;justify-content:center;padding:2rem;
  -webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale
}
.e{text-align:center;max-width:480px}
.c{font-size:clamp(2.5rem,8vw,4rem);font-weight:400;color:#1c516c;letter-spacing:-.03em;line-height:1.1;margin-bottom:1rem}
.d{width:48px;height:2px;background:#1c516c;margin:0 auto 1.5rem;border-radius:1px}
p{font-size:.95rem;color:#666;line-height:1.6;letter-spacing:-.01em}
</style>
</head>
<body>
<div class="e">
<div class="c">Lies Above</div>
<div class="d"></div>
<p>Scan a QR code from the book to be taken to its source.</p>
</div>
</body>
</html>
EOF

echo "generated redirect tree into $OUT"
