---
name: frontend-patterns
description: Rubree's frontend conventions — when to use Alpine.js vs Stimulus, how Turbo Frame and form submission work, ERB whitespace rules for preformatted output, inline helper methods, and SVG safety. Use when writing or reviewing Stimulus controllers, Alpine.js components, ERB templates, Turbo Frames, or anything that touches the client-side rendering pipeline.
---

# Frontend Patterns

## Alpine.js vs Stimulus

Both are used in this project. The distinction is what the state represents:

- **Alpine.js** — use for purely client-side state that does not survive a Turbo navigation and
  has no server interaction. In Rubree this covers the `wrap`/`showInvisibles` toggles in the
  results panel (persisted in `localStorage`) and the `show`/`hide` toggle in the Ruby code
  snippet. Alpine initialises inline with `x-data` and reacts without a separate controller file.

- **Stimulus** — use for anything that coordinates with Turbo events, reads the DOM on
  `connect`/`disconnect`, or calls back to the server. In Rubree this covers form submission
  (`regexp-form`), the diagram modal (`diagram-modal`), clipboard copy, permalink generation,
  and the examples panel (`regexp-examples`).

```erb
<%# ✅ Alpine for localStorage-persisted toggle — co-located, no controller file needed %>
<div x-data="{ wrap: localStorage.getItem('wrap') !== 'false',
               init() { this.$watch('wrap', v => localStorage.setItem('wrap', v)) } }">

<%# ✅ Stimulus for Turbo event coordination — needs connect/disconnect lifecycle %>
<form data-controller="regexp-form" data-action="input->regexp-form#submit">
```

Don't reach for Stimulus just because something is interactive — if the state is local and
ephemeral (or only needs `localStorage`), Alpine keeps the logic co-located with the markup.

## Turbo Frame and form submission flow

The entire results area lives inside a single Turbo Frame named `regexp`:

```erb
<%= turbo_frame_tag "regexp" do %>
  <%# match results, diagram, substitution, ruby code — all re-rendered on submit %>
<% end %>
```

The form's `data-turbo-frame="regexp"` directs the response back into that frame on submit, so
only the results panel updates — no full page reload.

**Form submission is debounced:** `regexp-form` controller calls `requestSubmit()` after a
200 ms delay on each keystroke, preventing the WASM runtime from being flooded while typing.

**Loading overlay is delayed 300 ms:** the spinner only appears if the response takes longer
than 300 ms (`regexp_form_controller.js` sets a `setTimeout(..., 300)` before showing the
overlay). Fast WASM responses complete before the timer fires, so there is no spinner flash on
typical inputs. The timeout is cancelled on `turbo:frame-render` for the `regexp` frame.

## ERB whitespace in preformatted output

When a container is styled with `whitespace-pre` or `font-mono`, the `<%= %>` tag must be placed
flush against the opening element's closing `>` with **no intervening newline or space**. ERB
emits any surrounding whitespace verbatim, and `whitespace-pre` renders it as a leading blank
character or extra line in the browser:

```erb
<%# ✅ ERB flush against the opening tag — no leading whitespace in the rendered output %>
<div class="whitespace-pre font-mono ..."><%= regular_expression.substitution_result %></div>

<%# ❌ newline before ERB tag — visible as a leading blank line inside the preformatted box %>
<div class="whitespace-pre font-mono ...">
  <%= regular_expression.substitution_result %>
</div>
```

For the same reason, the match-span highlighting loop in `_match.html.erb` is written as a
single semicolon-separated expression starting immediately after the `>` of the container
`<div>`. Breaking it across lines would inject whitespace before the first highlighted character.
ERB Lint may flag these as "line too long" — this is acceptable for preformatted output blocks.
Do not reformat them.

## Helper methods defined inside ERB templates

`escape_invisibles` — which converts `\n`, `\t`, `\r` to visible symbols like `⏎`, `⇥`, `␍`
— is defined with a bare `def` inside the ERB template rather than in `app/helpers/`. This is
intentional: the function is only needed within the two `<template x-if="showInvisibles">` blocks
of a single partial, and adding it to `ApplicationHelper` would pollute the global helper
namespace for a purely local concern. The inline `def` creates a method in the template's binding
scope.

If `escape_invisibles` ever needs to be shared across multiple partials, move it to
`app/helpers/regular_expressions_helper.rb` at that point.

## SVG output is sanitized — do not bypass it

`RailroadDiagram#diagram_svg` passes the generated SVG through
`ActionController::Base.helpers.sanitize(...)` with an explicit allowlist before returning it.
The result is an `ActiveSupport::SafeBuffer` (html-safe), which is why `<%= diagram_svg %>` in
the view renders without double-escaping.

Do not call `raw(...)` or `.html_safe` on unsanitized SVG. A crafted regex pattern could
otherwise inject arbitrary HTML/JavaScript via the SVG output.

```ruby
# ✅ what RailroadDiagram.sanitize_svg does — narrow allowlist, returns SafeBuffer
ActionController::Base.helpers.sanitize(
  raw_svg,
  tags: %w[svg g path rect circle line text style defs title desc],
  attributes: %w[d fill stroke x y cx cy r width height viewBox xmlns class type
                 transform text-anchor font stroke-width rx ry]
)

# ❌ never do this — bypasses XSS protection on user-influenced SVG content
raw(regular_expression.diagram_svg)
```

---

## Review checklist — frontend

When reviewing a PR or diff that touches the client-side layer:

### Client-side philosophy

- [ ] No server-side dependency introduced — the app remains deployable as a static site to
  GitHub Pages (no runtime external API calls that require a backend, no new server-rendered
  endpoints that break in the WASM context)
- [ ] If gem dependencies or Rails internals changed, verify the WASM build still works
  (`bin/rails wasmify:build` or check the CI Deploy job) — gems that don't compile to WASM will
  silently break the browser app

### Browser compatibility

- [ ] Behavior is Chrome/Edge-only — no assumption that Safari or Firefox will work; new Web APIs
  must be in Chrome stable. (Safari/Firefox fail due to WebAssembly asyncify / Service Worker
  incompatibilities — see README → Browser Compatibility for the full explanation)
