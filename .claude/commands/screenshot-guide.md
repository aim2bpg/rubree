# screenshot-guide

Capture annotated screenshots for every feature in Rubree and regenerate all GIFs.
Outputs feed into `docs/usage-guide.md` and serve as visual reference for `/verify-wasm`.

Run after any UI change that affects the visual flow, or when adding a new feature.

## Usage

```
/screenshot-guide
```

## What to keep — retention criteria

A file in `docs/screenshots/` is kept **only if at least one of the following is true**:

| Criterion | Check |
|---|---|
| Referenced in `docs/usage-guide.md` | `grep -r "screenshots/<file>" docs/usage-guide.md` |
| Referenced in `README.md` | `grep -r "screenshots/<file>" README.md` |

Everything else is deleted. Run this to audit at any time:

```bash
find docs/screenshots -type f | while IFS= read -r f; do
  rel="${f#docs/}"
  if grep -qrF "$rel" docs/usage-guide.md README.md 2>/dev/null; then
    echo "KEEP   $f"
  else
    echo "DELETE $f"
  fi
done
```

**Why this rule?** Unreferenced images inflate `.git` history permanently — every regeneration
doubles the storage cost. Only files that are actually displayed to a reader justify their size.

**GIF vs PNG:** prefer GIFs for features with interaction (they replace 2–3 static PNGs and show
the flow). Keep a static PNG only when a specific still frame needs to be highlighted in prose.

---

## Outputs

```
docs/screenshots/
├── features/   ← per-feature GIFs and PNGs for usage-guide.md
├── demo/       ← full-flow GIF for README (usage_demo.gif)
└── qa/         ← reserved for Layer 2 WASM E2E test snapshots (currently empty)
```

| Path | Purpose | 使い分け |
|---|---|---|
| `docs/screenshots/features/gif_<feature>.gif` | Per-feature animated GIFs | **操作の流れを見せる**ときに使う。機能の主要アセット |
| `docs/screenshots/features/<feature_name>.png` | Per-feature static PNGs | **特定の静止フレームを文章中で指す**ときだけ追加する。GIF でカバーできる機能は PNG 不要 |
| `docs/screenshots/demo/usage_demo.gif` | Full golden-path GIF | README 冒頭の概観デモ専用 |
| `docs/screenshots/qa/` | E2E test snapshots | Layer 2 CI 統合後に自動生成。手動で置かない |

**`features/` に PNG と GIF が共存するケース：**
GIF は「操作の流れ」、PNG は「文章中で特定の状態を参照させたいとき」という役割が異なります。
例: `gif_diagram.gif`（ダイアグラムが描画されるアニメーション）と `diagram_modal.png`（モーダルを開いた静止状態、prose で「この画面を確認」と指示するため）は両方必要。

**PNG を追加してよいのは次の条件を満たすときだけ：**
1. `usage-guide.md` の文章中に `![...](screenshots/features/xxx.png)` として埋め込む
2. その機能のインタラクションを見せる GIF ではカバーできない静止状態を示す必要がある

**Current inventory** (4 PNGs + 10 GIFs — all referenced):

| File | Referenced in |
|---|---|
| `diagram_modal.png` | `docs/usage-guide.md` |
| `examples_button.png` | `docs/usage-guide.md` |
| `named_captures.png` | `docs/usage-guide.md` |
| `options_case_insensitive.png` | `docs/usage-guide.md` |
| `gif_boot.gif` | `docs/usage-guide.md` |
| `gif_captures.gif` | `docs/usage-guide.md` |
| `gif_diagram.gif` | `docs/usage-guide.md` |
| `gif_match.gif` | `docs/usage-guide.md` |
| `gif_permalink.gif` | `docs/usage-guide.md` |
| `gif_quickref.gif` | `docs/usage-guide.md` |
| `gif_redos.gif` | `docs/usage-guide.md` |
| `gif_snippet.gif` | `docs/usage-guide.md` |
| `gif_substitution.gif` | `docs/usage-guide.md` |
| `usage_demo.gif` | `README.md` |

## When to run

- After UI / copy / layout changes visible in any feature
- After a new feature is added that should appear in the guide
- When `docs/usage-guide.md` screenshots look stale
- When the README `usage_demo.gif` looks stale

---

## Steps

### 1. Ensure the PWA dev server is running

```bash
(cd pwa && npm run dev) &
PWA_PID=$!
sleep 5
```

The server must be on **http://localhost:5173** with COOP/COEP headers (Vite handles this automatically).

### 2. Ensure dependencies are present

```bash
which convert || sudo apt-get install -y imagemagick
ls node_modules/playwright/index.mjs
```

### 3. Capture screenshots via Playwright

Write a Node script at `/tmp/capture_guide.mjs` and run it:

```bash
node /tmp/capture_guide.mjs
```

The script should:
1. Boot the app (click Start → Agree → wait for WASM)
2. For each feature, enter the test pattern + test string, wait for the result, then take a screenshot
3. Save raw PNGs to `/tmp/raw_<feature>_<step>.png`
4. Return element bounding boxes for annotation

Key Playwright selectors:

| Element | Selector |
|---|---|
| Regex input | `#regular_expression_expression` |
| Test string | `#regular_expression_test_string` |
| Substitution | `#regular_expression_substitution` |
| Options checkboxes | `#regular_expression_options` |
| Diagram zoom button | `[data-action="click->diagram-modal#open"]` |
| Share button | `[data-action="click->permalink#share"]` |
| Result area | `#regexp` |
| Match highlights | `.regexp-match-highlight` |
| Quick reference | `[data-controller="quick-reference"]` |

### 4. Annotate with ImageMagick

Draw red/coloured rounded boxes on each raw PNG and save to `docs/screenshots/features/`:

```bash
# ImageMagick 6 syntax — use -stroke (not -strokecolor), -fill none
convert raw.png \
  -stroke red -strokewidth 3 -fill none \
  -draw "roundrectangle 100,200 400,250 5,5" \
  -font FreeSans-Bold -pointsize 14 \
  -fill red -stroke none \
  -annotate +100+195 "Label text" \
  docs/screenshots/features/<feature_name>.png
```

Colour convention: red = primary action, blue = input field, amber = diagram/output, green = secondary field.

### 5. Generate per-feature GIFs

```bash
# Template — repeat for each feature, adjusting paths and delays
convert \
  -delay 200 /tmp/raw_match_01.png \
  -delay 300 /tmp/raw_match_02.png \
  -loop 0 -layers optimize \
  docs/screenshots/features/gif_match.gif
```

### 6. Regenerate usage_demo.gif (README GIF)

```bash
convert \
  -delay 250 \( /tmp/raw_boot_01.png      -resize 900x \) \
  -delay 250 \( /tmp/raw_boot_02.png      -resize 900x \) \
  -delay 150 \( /tmp/raw_boot_03.png      -resize 900x \) \
  -delay 200 \( /tmp/raw_boot_04.png      -resize 900x \) \
  -delay 250 \( /tmp/raw_match_01.png     -resize 900x \) \
  -delay 300 \( /tmp/raw_match_02.png     -resize 900x \) \
  -delay 250 \( docs/screenshots/features/diagram_modal.png -resize 900x \) \
  -delay 300 \( /tmp/raw_subst_01.png     -resize 900x \) \
  -delay 300 \( /tmp/raw_permalink_01.png -resize 900x \) \
  -loop 0 -layers optimize \
  docs/screenshots/demo/usage_demo.gif
```

Target size: under 500 KB. If larger, reduce `-resize` to `800x` or drop a frame.

### 7. Kill the dev server

```bash
kill $PWA_PID
```

### 8. Verify and commit

- Open `docs/screenshots/demo/usage_demo.gif` in a browser to confirm the animation
- The README `## Usage` section embeds this GIF — check it renders on GitHub
- Commit: `docs: regenerate usage screenshots and GIFs`

---

## Notes

- ImageMagick font: `FreeSans-Bold` (available in the DevContainer)
- If Playwright MCP is connected, prefer MCP tools over raw Node scripts for reliability
- These screenshots double as **expected visual state** for `/verify-wasm` manual verification
- After adding a new feature, add a new `guide/<feature>/` section here under "Current inventory"
