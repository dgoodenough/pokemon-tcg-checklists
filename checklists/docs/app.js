/* Pokémon TCG Collection Builder — client-side generator.
   Filters a bundled catalog (data/catalog.json) by Pokémon / artist / set, builds the
   collection, and renders it as a printable Ledger checklist or 9-pocket binder grid,
   plus a downloadable TCGplayer mass-entry list. No server. */
(function () {
  "use strict";
  var SID = 0, NUM = 1, NAME = 2, RAR = 3, ART = 4, VAR = 5, PNAME = 6, NRAW = 7;
  var VORDER = ["1stEdition","1stEditionHolofoil","unlimited","unlimitedHolofoil","normal","holofoil","reverseHolofoil","cosmosHolofoil","nonHoloDeck","stampedPromo"];
  var VLABEL = { "1stEdition":"1st Ed","1stEditionHolofoil":"1st Ed Holo","unlimited":"Unlimited","unlimitedHolofoil":"Unl. Holo","normal":"Regular","holofoil":"Holo","reverseHolofoil":"Reverse","cosmosHolofoil":"Cosmos","nonHoloDeck":"Non-Holo","stampedPromo":"Stamped" };
  var CAT = null, COLL = null, MODE = "checklist";

  function el(t, c, x) { var e = document.createElement(t); if (c) e.className = c; if (x != null) e.textContent = x; return e; }
  function esc(s) { return String(s == null ? "" : s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;"); }
  function symUrl(sid) { return "https://images.pokemontcg.io/" + sid + "/symbol.png"; }
  function yr(d) { return d ? String(d).slice(0, 4) : ""; }
  function slug() { return COLL.title.toLowerCase().replace(/[^a-z0-9]+/g,"_").replace(/^_|_$/g,""); }

  // ---- build a collection object from a spec ----
  function build(type, target) {
    var t = (target || "").trim(); if (!t) return null;
    var pred;
    if (type === "pokemon") { var ns = t.split(",").map(function (s) { return s.trim().toLowerCase(); }).filter(Boolean);
      pred = function (c) { var n = c[NAME].toLowerCase(); return ns.some(function (q) { return n.indexOf(q) >= 0; }); };
    } else if (type === "artist") { var q = t.toLowerCase(); pred = function (c) { return c[ART].toLowerCase().indexOf(q) >= 0; };
    } else { var sid = t.toLowerCase(); pred = function (c) { return c[SID].toLowerCase() === sid; }; }

    var rows = CAT.cards.filter(pred);
    if (!rows.length) return null;
    var sets = [], curId = null, cur = null;
    rows.forEach(function (c) {
      if (c[SID] !== curId) { if (cur) sets.push(cur); curId = c[SID]; var m = CAT.sets[curId] || { n: curId, s: "", d: "", c: "" };
        cur = { set_id: curId, name: m.n, series: m.s, releaseDate: m.d, code: m.c, symbol: symUrl(curId), cards: [], vset: {} }; }
      var vs = c[VAR] ? c[VAR].split("|") : [];
      cur.cards.push({ num: c[NUM], name: c[NAME], rarity: c[RAR], variants: vs, pname: c[PNAME], nraw: c[NRAW] });
      vs.forEach(function (v) { cur.vset[v] = 1; });
    });
    if (cur) sets.push(cur);
    sets.forEach(function (s) { s.variants = VORDER.filter(function (v) { return s.vset[v]; }).map(function (v) { return { key: v, label: VLABEL[v] }; }); });

    var title, sub;
    if (type === "pokemon") { title = t.split(",").map(function (s) { return s.trim(); }).join(" & "); sub = "Every English printing featuring " + title; }
    else if (type === "artist") { title = t; sub = "Every English card illustrated by " + title; }
    else { title = (CAT.sets[t.toLowerCase()] ? CAT.sets[t.toLowerCase()].n : t); sub = "Complete checklist for " + title; }
    return { type: type, target: t, title: title, subtitle: sub, totalCards: rows.length, sets: sets };
  }

  // ---- checklist view ----
  function renderChecklist(view) {
    COLL.sets.forEach(function (s) {
      var block = el("div", "setblock");
      var band = el("div", "setband");
      var im = el("img"); im.src = s.symbol; im.alt = ""; im.onerror = function () { this.style.display = "none"; }; band.appendChild(im);
      band.appendChild(el("span", null, s.name));
      var meta = el("span", "meta"); meta.textContent = s.cards.length + " cards" + (s.releaseDate ? "  ·  " + yr(s.releaseDate) : "") + (s.series ? "  ·  " + s.series : ""); band.appendChild(meta);
      block.appendChild(band);
      var t = el("table", "cards"), th = el("thead"), hr = el("tr");
      ["#", "Card", "Rarity"].forEach(function (h) { hr.appendChild(el("th", null, h)); });
      s.variants.forEach(function (v) { hr.appendChild(el("th", "box", v.label)); });
      th.appendChild(hr); t.appendChild(th);
      var tb = el("tbody");
      s.cards.forEach(function (c) {
        var tr = el("tr");
        tr.appendChild(el("td", "num", c.num)); tr.appendChild(el("td", "card", c.name)); tr.appendChild(el("td", "rar", c.rarity || ""));
        s.variants.forEach(function (v) { var td = el("td", "box"); if (c.variants.indexOf(v.key) >= 0) td.appendChild(el("span", "sq")); else td.appendChild(el("span", "na", "—")); tr.appendChild(td); });
        tb.appendChild(tr);
      });
      t.appendChild(tb); block.appendChild(t); view.appendChild(block);
    });
  }

  // ---- binder grid view (9-pocket, packed; never start an era in pocket 8/9) ----
  function packPages() {
    var items = []; COLL.sets.forEach(function (s) { s.cards.forEach(function (c) { items.push({ set: s.name, sym: s.symbol, series: s.series, num: c.num, name: c.name }); }); });
    var pages = [], cur = [], last = null;
    items.forEach(function (it) { if (cur.length === 9) { pages.push(cur); cur = []; last = null; } else if (cur.length >= 7 && last !== null && it.series !== last) { pages.push(cur); cur = []; last = null; } cur.push(it); last = it.series; });
    if (cur.length) pages.push(cur);
    while (pages.length >= 2 && pages[pages.length - 1].length === 1 && pages[pages.length - 2].length <= 8) { pages[pages.length - 2].push(pages.pop()[0]); }
    return pages;
  }
  function renderGrid(view) {
    var pages = packPages(), seq = 0;
    pages.forEach(function (pg, pi) {
      var page = el("div", "bpage");
      var eras = []; pg.forEach(function (it) { if (eras.indexOf(it.series) < 0) eras.push(it.series); });
      var head = el("div", "bhead");
      head.innerHTML = '<span class="bt">' + esc(COLL.title) + '</span><span class="be">' + esc(eras.join("  ·  ")) + '</span><span class="bp">Page ' + (pi + 1) + " / " + pages.length + "</span>";
      page.appendChild(head);
      var g = el("div", "bgrid");
      for (var i = 0; i < 9; i++) {
        var cell = el("div");
        if (i < pg.length) { seq++; var it = pg[i]; cell.className = "pocket";
          cell.innerHTML = '<span class="pseq">' + seq + '</span><div class="prow">' + (it.sym ? '<img src="' + esc(it.sym) + '" onerror="this.remove()">' : "") + '<div class="pset">' + esc(it.set) + '</div></div><div class="pfill"></div><div class="pnum"><span>#</span>' + esc(it.num) + '</div><div class="pname">' + esc(it.name) + "</div>";
        } else cell.className = "pocket empty";
        g.appendChild(cell);
      }
      page.appendChild(g); view.appendChild(page);
    });
  }

  // ---- mass-entry list ----
  function massText() {
    var lines = [];
    COLL.sets.forEach(function (s) { var cd = s.code || ("??" + s.set_id); s.cards.forEach(function (c) { lines.push("1 " + (c.pname || c.name) + " [" + cd + "] " + (c.nraw || c.num)); }); });
    return lines.join("\r\n") + "\r\n";
  }
  function download(name, text, type) { var b = new Blob([text], { type: type || "text/plain" }); var u = URL.createObjectURL(b); var a = el("a"); a.href = u; a.download = name; document.body.appendChild(a); a.click(); a.remove(); URL.revokeObjectURL(u); }

  // ---- render the whole result panel ----
  function renderResult() {
    var view = document.getElementById("view"); view.innerHTML = ""; view.className = (MODE === "grid" ? "gridmode" : "");
    if (!COLL) { view.appendChild(el("p", "empty", "Pick a type and target, then Generate.")); return; }
    document.title = COLL.title + " — TCG Collection Builder";
    var head = el("div", "head");
    var titles = el("div", "titles"); titles.appendChild(el("h2", null, COLL.title)); if (COLL.subtitle) titles.appendChild(el("p", "sub", COLL.subtitle)); head.appendChild(titles);
    var figs = el("div", "figs"); figs.appendChild(el("div", "stat", String(COLL.totalCards))); figs.appendChild(el("div", "stat-label", "cards / " + COLL.sets.length + " sets")); head.appendChild(figs);
    view.appendChild(head);

    var bar = el("div", "toolbar");
    var seg = el("div", "seg");
    var b1 = el("button", MODE === "checklist" ? "active" : null, "Checklist"); b1.onclick = function () { MODE = "checklist"; renderResult(); };
    var b2 = el("button", MODE === "grid" ? "active" : null, "Binder grid"); b2.onclick = function () { MODE = "grid"; renderResult(); };
    seg.appendChild(b1); seg.appendChild(b2); bar.appendChild(seg);
    var pr = el("button", "btn primary", "Print / Save PDF"); pr.onclick = function () { window.print(); }; bar.appendChild(pr);
    var me = el("button", "btn", "Mass-entry .txt"); me.onclick = function () { download(slug() + "_massentry_LP.txt", massText()); }; bar.appendChild(me);
    view.appendChild(bar);

    var body = el("div", MODE === "grid" ? "gridwrap" : "sheet");
    if (MODE === "grid") renderGrid(body); else renderChecklist(body);
    view.appendChild(body);
    document.getElementById("main").scrollTop = 0;
  }

  // ---- form wiring ----
  var HINTS = {
    pokemon: ["e.g. Sandygast,Palossand", "Comma-separate names to combine an evolution family."],
    artist:  ["e.g. Mitsuhiro Arita", "Matches the artist credit (includes co-credits)."],
    set:     ["e.g. sv8", "Use the pokemontcg.io set id (sv8, swsh12, base1, neo1…)."]
  };
  function wire() {
    var type = document.getElementById("type"), tgt = document.getElementById("target"), hint = document.getElementById("hint"), status = document.getElementById("status");
    type.onchange = function () { var h = HINTS[type.value]; tgt.placeholder = h[0]; hint.textContent = h[1]; };
    document.getElementById("gen").onsubmit = function (e) {
      e.preventDefault();
      var c = build(type.value, tgt.value);
      if (!c) { status.textContent = "No cards matched that."; status.className = "status err"; return; }
      status.textContent = ""; status.className = "status";
      COLL = c; MODE = "checklist"; renderResult();
      history.replaceState(null, "", "#" + type.value + ":" + encodeURIComponent(tgt.value.trim()));
    };
    document.querySelectorAll(".ex").forEach(function (b) {
      b.onclick = function () { type.value = b.dataset.type; type.onchange(); tgt.value = b.dataset.target; document.getElementById("gen").requestSubmit(); };
    });
  }

  // ---- boot ----
  fetch("data/catalog.json").then(function (r) { return r.json(); }).then(function (j) {
    CAT = j;
    document.getElementById("catstat").textContent = j.cards.length.toLocaleString() + " cards · " + Object.keys(j.sets).length + " sets";
    wire();
    var m = location.hash.replace(/^#/, "").match(/^(pokemon|artist|set):(.+)$/);
    if (m) { document.getElementById("type").value = m[1]; document.getElementById("type").onchange(); document.getElementById("target").value = decodeURIComponent(m[2]); document.getElementById("gen").requestSubmit(); }
    else renderResult();
  }).catch(function (e) { document.getElementById("view").innerHTML = "<p class='empty'>Couldn't load the catalog: " + esc(String(e)) + "</p>"; });
})();
