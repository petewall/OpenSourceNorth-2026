# Browser-Based Slide Deck

This mini app keeps your entire talk inside one Chromium window so you can jump
between narrative slides and live Grafana dashboards without ⌘-Tab juggling.

## Quickstart

```bash
cd /Users/petewall/src/PeteWall/OpenSourceNorth-2026/presentation
npm install      # already done once, repeat when deps change
npm start        # serves http://localhost:8080
```

The server exposes:

- `GET /api/slides` &mdash; slide metadata sourced from `slides.json`.
- Static assets in `public/` with a fullscreen-friendly UI plus Prev/Next controls
  and arrow-key bindings.

## Editing Slides

Slides live in [`slides.json`](../presentation/slides.json). Each entry supports:

| Field | Description |
| --- | --- |
| `id` | Stable identifier (used for anchor links later if needed). |
| `type` | `"content"` or `"iframe"`. |
| `title` / `subtitle` | Text for the header. |
| `body` | Array of bullet strings (content slides only). |
| `url` | Iframe source (Grafana dashboards, docs, etc.). |
| `notes` | Presenter notes shown in the footer. |

Replace the placeholder Grafana Play URLs with your local dashboards (include
`&kiosk` or `&fullscreen` query params if desired). Because everything is just
JSON + static files, reloading the page picks up edits instantly.

## Keyboard / Controls

- ← / → arrows: previous / next slide
- Space: next slide
- ⤢ button: toggle fullscreen (or use the browser's `F` key)

## Customizing Further

- Drop additional CSS, fonts, or branding into `public/style.css`.
- Add richer slide types by extending the renderer in `public/app.js`.
- Protect behind auth or tunnels by updating `server.js` (Express 5).
