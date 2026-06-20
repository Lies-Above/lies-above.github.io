# lies-above.github.io

Static QR-code redirector for the book *Lies Above*, hosted on GitHub Pages.

Each footnote QR code points at a stable path like `/v1/fn5/1`. This repo holds
one self-contained HTML page per reference that forwards the visitor to the
cited source. There is no server and no build step at deploy time — GitHub Pages
serves the committed files directly, so **what is in this repo is exactly what is
served**.

## How a redirect works

`redirects.json` is the source of truth: a flat map keyed by the bare reference
ID, each value `{ "url", "description" }`.

```json
{ "fn5.1": { "url": "https://example.org/source", "description": "…" } }
```

`gen.sh` turns each entry into a page. The key `fn5.1` is prefixed with the
edition (`v1.`) to form the lookup ID `v1.fn5.1`, written to
`v1/fn5/1/index.html`. Each page redirects three independent ways, with no
external resources:

- `<meta http-equiv="refresh">` — instant, works without JavaScript
- `<link rel="canonical">` — declares the destination to crawlers
- `window.location.replace(...)` — instant, leaves no back-button trap

A request to `/?id=v1.fn5.1` is rewritten by the root page to `/v1/fn5/1/`, so
the query form resolves to the same page. Unknown references fall through to the
branded `404.html`.

## Regenerating

Run after editing `redirects.json`, then commit the result:

```sh
./gen.sh                  # reads redirects.json, writes the tree into .
git add -A && git commit -m "Regenerate redirect tree"
```

**Dependency:** [`jq`](https://jqlang.github.io/jq/). It parses the JSON and
escapes every destination URL — `@html` for the HTML-attribute slots, `@json`
for the JavaScript string. Do not parse `redirects.json` with `grep`/`sed`; that
loses the escaping guarantees.

## Deployment

GitHub Pages → Settings → Pages → Deploy from a branch → `main` / `/ (root)`.
The repo name `lies-above.github.io` makes the site serve at the org root,
`https://lies-above.github.io/`. A custom domain is added later via a `CNAME`
file plus DNS records.
