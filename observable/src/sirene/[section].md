---
title: SIRENE — Section
---

```js
import * as d3 from "npm:d3";
import { tabInput } from "../components/tabs.js";
import { top20Chart, apeClickableChart } from "../components/sirene-charts.js";
```

```js
const sectionId = observable.params.section;
const sections = FileAttachment("../data/nafrev2-sections.json").json();
const statsBySection = FileAttachment(
  "../data/sirene-stats-by-section.json",
).json();
const allDivisions = FileAttachment(
  "../data/sirene-stats-by-division.json",
).json();
const allGroupes = FileAttachment("../data/sirene-stats-by-groupe.json").json();
const allClasses = FileAttachment("../data/sirene-stats-by-classe.json").json();
const allTopCodesApe = FileAttachment(
  "../data/sirene-top-codes-ape.json",
).json();
```

```js
const sectionMeta = sections.find((s) => s.section_id === sectionId) ?? {};
const sectionLabel = sectionMeta.section ?? sectionId;

const sectionStats = statsBySection.find((s) => s.section_id === sectionId);
const totalEtablissements = sectionStats ? +sectionStats.nb_etablissements : 0;

const divisions = allDivisions
  .filter((d) => d.section_id === sectionId)
  .map((d) => ({ ...d, nb_etablissements: +d.nb_etablissements }))
  .sort((a, b) => b.nb_etablissements - a.nb_etablissements);

const groupes = allGroupes
  .filter((d) => d.section_id === sectionId)
  .map((d) => ({ ...d, nb_etablissements: +d.nb_etablissements }))
  .sort((a, b) => b.nb_etablissements - a.nb_etablissements)
  .slice(0, 20);

const classes = allClasses
  .filter((d) => d.section_id === sectionId)
  .map((d) => ({ ...d, nb_etablissements: +d.nb_etablissements }))
  .sort((a, b) => b.nb_etablissements - a.nb_etablissements)
  .slice(0, 20);

const topCodesApe = allTopCodesApe
  .filter((d) => d.section_id === sectionId)
  .map((d) => ({ ...d, nb_etablissements: +d.nb_etablissements }))
  .slice(0, 20);
```

<div class="page-header">
  <div class="breadcrumb"><a href="/">Accueil</a> › <a href="/sirene">SIRENE</a> › Section ${sectionId}</div>
  <h1>${sectionLabel}</h1>
  <p class="page-subtitle">Section ${sectionId} — ${totalEtablissements.toLocaleString("fr-FR")} établissements SIRENE répartis sur ${divisions.length} division(s).</p>
</div>

## Vue d'ensemble

<div class="stat-grid">
  <div class="stat-card">
    <div class="stat-value">${totalEtablissements.toLocaleString("fr-FR")}</div>
    <div class="stat-label">Établissements</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${divisions.length}</div>
    <div class="stat-label">Divisions</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${groupes.length}</div>
    <div class="stat-label">Groupes</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${classes.length}</div>
    <div class="stat-label">Classes</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${new Set(allTopCodesApe.filter(d => d.section_id === sectionId).map(d => d.sous_classe_id)).size}</div>
    <div class="stat-label">Codes APE</div>
  </div>
</div>

## Divisions

<div class="chart-description">Répartition des établissements de la section ${sectionId} par division. La taille de chaque rectangle est proportionnelle au nombre d'établissements. Cliquez pour explorer une division.</div>

```js
{
  const w = 900,
    h = 360;
  const color = d3.scaleOrdinal(
    divisions.map((_, i) => i),
    d3.schemeTableau10,
  );

  const root = d3
    .hierarchy({ children: divisions })
    .sum((d) => d.nb_etablissements)
    .sort((a, b) => b.value - a.value);

  d3.treemap().size([w, h]).padding(2).paddingOuter(4).round(true)(root);

  const svg = d3
    .create("svg")
    .attr("width", "100%")
    .attr("viewBox", `0 0 ${w} ${h}`)
    .style("font-family", "var(--sans-serif)");

  const defs = svg.append("defs");
  root.leaves().forEach((d, i) => {
    defs
      .append("clipPath")
      .attr("id", `div-clip-${i}`)
      .append("rect")
      .attr("width", Math.max(0, d.x1 - d.x0 - 6))
      .attr("height", Math.max(0, d.y1 - d.y0 - 6));
  });

  const leaf = svg
    .selectAll("g")
    .data(root.leaves())
    .join("g")
    .attr("transform", (d) => `translate(${d.x0},${d.y0})`);

  leaf
    .append("a")
    .attr("href", (d) => `/sirene/${sectionId}/${d.data.division_id}`)
    .append("rect")
    .attr("width", (d) => Math.max(0, d.x1 - d.x0))
    .attr("height", (d) => Math.max(0, d.y1 - d.y0))
    .attr("fill", (d, i) => color(i))
    .attr("fill-opacity", 0.82)
    .attr("rx", 4)
    .attr("stroke", "white")
    .attr("stroke-width", 1.5);

  leaf
    .append("text")
    .attr("clip-path", (d, i) => `url(#div-clip-${i})`)
    .attr("x", 6)
    .attr("y", 18)
    .attr("fill", "white")
    .attr("font-size", "13px")
    .attr("font-weight", "700")
    .attr("pointer-events", "none")
    .text((d) => (d.x1 - d.x0 > 32 ? d.data.division_id : ""));

  leaf
    .append("text")
    .attr("clip-path", (d, i) => `url(#div-clip-${i})`)
    .attr("x", 6)
    .attr("y", 33)
    .attr("fill", "rgba(255,255,255,0.9)")
    .attr("font-size", "10px")
    .attr("pointer-events", "none")
    .text((d) => {
      const cw = d.x1 - d.x0,
        ch = d.y1 - d.y0;
      if (cw < 55 || ch < 42) return "";
      const maxChars = Math.floor(cw / 6.5);
      return d.data.division.length > maxChars
        ? d.data.division.slice(0, maxChars) + "…"
        : d.data.division;
    });

  leaf
    .append("text")
    .attr("clip-path", (d, i) => `url(#div-clip-${i})`)
    .attr("x", 6)
    .attr("y", (d) => d.y1 - d.y0 - 6)
    .attr("fill", "rgba(255,255,255,0.75)")
    .attr("font-size", "10px")
    .attr("pointer-events", "none")
    .text((d) => {
      const cw = d.x1 - d.x0,
        ch = d.y1 - d.y0;
      if (cw < 55 || ch < 36) return "";
      return (
        d.data.nb_etablissements.toLocaleString("fr-FR") +
        " (" +
        ((d.data.nb_etablissements / totalEtablissements) * 100).toFixed(1) +
        " %)"
      );
    });

  leaf
    .append("title")
    .text(
      (d) =>
        `${d.data.division_id} — ${
          d.data.division
        }\n${d.data.nb_etablissements.toLocaleString(
          "fr-FR",
        )} établissements (${(
          (d.data.nb_etablissements / totalEtablissements) *
          100
        ).toFixed(1)} %)`,
    );

  display(svg.node());
}
```

## Top 20

```js
const LEVELS = [
  {
    label: "Groupe",
    data: groupes,
    yFn: (d) => `${d.groupe_id} — ${d.groupe}`,
    hrefFn: (d) => `/sirene/${sectionId}/${d.division_id}`,
    fill: "#ffb74d",
    hasMap: false,
  },
  {
    label: "Classe",
    data: classes,
    yFn: (d) => `${d.classe_id} — ${d.classe}`,
    hrefFn: (d) => `/sirene/${sectionId}/${d.division_id}`,
    fill: "#ce93d8",
    hasMap: false,
  },
  {
    label: "APE",
    data: topCodesApe,
    yFn: (d) => `${d.sous_classe_id} — ${d.sous_classe}`,
    hrefFn: (d) =>
      `/sirene/${sectionId}/${d.division_id}/${d.groupe_id}/${d.classe_id}/${d.sous_classe_id}`,
    fill: "#81c784",
    hasMap: false,
  },
];

const selectedLevel = view(tabInput(LEVELS, LEVELS[0]));
```

<div class="chart-description">Top 20 des ${selectedLevel.label.toLowerCase()}s les plus représentés dans cette section. ${selectedLevel.hasMap ? "Cliquez sur un code APE pour afficher la carte." : "Cliquez pour explorer."}</div>

```js
display(
  top20Chart(selectedLevel.data, {
    yFn: selectedLevel.yFn,
    hrefFn: selectedLevel.hrefFn,
    fill: selectedLevel.fill,
    totalEtablissements,
  }),
);
```

<div class="source-note">
  Source : <a href="/dataset/sirene">Dataset SIRENE</a> — registre national des entreprises géré par l'<a href="https://www.sirene.fr" target="_blank">INSEE</a>. Codes d'activité : <a href="/nafrev2">NAF Rév. 2</a>.
</div>

<div class="see-also">
  <h3>Voir aussi</h3>
  <div class="see-also-links">
    <a class="see-also-link" href="/sirene">← Toutes les sections SIRENE</a>
    <a class="see-also-link" href="/nafrev2">📋 Référentiel NAF — section ${sectionId}</a>
    <a class="see-also-link" href="/dataset/sirene">🏢 Dataset SIRENE</a>
  </div>
</div>
