# Pokémon TCG Checklist Generator

I collect by theme: every Ampharos ever printed, every card a particular illustrator
drew. Useful groupings exist out there, but the thing I actually wanted didn't, a
one-click way to generate a printable visual guide showing exactly where each card
goes in my binder. So I built one.

It's a PowerShell + HTML generator. Give it a theme (a Pokémon, an illustrator, a
set) and it builds a subset checklist, a binder-grid layout, and a TCGplayer Mass
Entry string for buying whatever you're missing, all rendered to PDF via Chrome
headless.

## What it does

- **A checklist and binder guide for any theme.** A subset checklist
  (`generate.ps1`) plus a binder-grid layout (`build_grids.ps1`) that mirrors your
  physical pages, for any Pokémon, illustrator, or set. Per-theme card data lives in
  `checklists/<theme>/data.js` and the HTML templates render it. Sample outputs for
  Ampharos, Komiya, and Wailmer/Wailord are included.
- **Closes the loop to buying.** A TCGplayer Mass Entry string
  (`build_komiya_massentry.ps1`) turns the gap list into a one-paste order. Tying
  together the pieces of collecting, what exists, what you have, and what to buy, is
  the real point.
- **Era-aware page breaks.** The layout leaves deliberate gaps in the grid so the
  binder's pages split cleanly between card eras. A small personal touch, and the
  part I'm happiest with, because it makes the printed pages feel right in hand.

## Where it's at

I printed and used everything here to fill in my own collections, so it does the job.
Of my collector tools this one probably has the broadest potential audience. It's
just not yet at the polish and ease-of-use of my other interactive pages (the disc
golf and soccer sites). Getting it there, so anyone can generate their own themed
checklist without touching a script, is the next step.

## Layout

```
checklists/
├── generate.ps1                 subset checklist generator (theme → PDF)
├── build_grids.ps1              binder-grid layout generator
├── build_komiya_massentry.ps1   TCGplayer Mass Entry string builder
├── <theme>/                     per-theme checklist.html + data.js
│                                (ampharos, komiya, wailmer_wailord)
├── grids/                       per-theme binder-grid HTML
├── symbols/                     Pokémon set-symbol icons (UI assets)
└── *_checklist.pdf,
    *_grid_pages.pdf             sample generated outputs
```

## Stack

PowerShell · HTML/CSS · JavaScript · Chrome headless (HTML → PDF).

## Related

Companion repo:
**[pokemon-tcg-pricing](https://github.com/dgoodenough/pokemon-tcg-pricing)**, a
DuckDB pricing and collection-analytics pipeline over the same card domain.

## A note on Pokémon IP

Pokémon, the set symbols, and card data are © The Pokémon Company / Nintendo / Game
Freak. This is a personal, non-commercial fan tool. The set-symbol images in
`checklists/symbols/` are included solely as UI assets for rendering checklists.

## License

[MIT](LICENSE).
