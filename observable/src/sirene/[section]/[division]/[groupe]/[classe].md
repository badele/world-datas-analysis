---
title: SIRENE — Classe
---

```js
import { apeClickableChart } from "../../../../components/sirene-charts.js";
```

```js
const sectionId = observable.params.section;
const divisionId = observable.params.division;
const groupeId = observable.params.groupe;
const classeId = observable.params.classe;

const sections = FileAttachment(
  "../../../../data/nafrev2-sections.json",
).json();
const allDivisions = FileAttachment(
  "../../../../data/nafrev2-divisions.json",
).json();
const allGroupes = FileAttachment(
  "../../../../data/sirene-stats-by-groupe.json",
).json();
const allClasses = FileAttachment(
  "../../../../data/sirene-stats-by-classe.json",
).json();
const allCodesApe = FileAttachment(
  "../../../../data/sirene-top-codes-ape.json",
).json();
```

```js
const sectionMeta = sections.find((s) => s.section_id === sectionId) ?? {};
const sectionLabel = sectionMeta.section ?? sectionId;

const divisionMeta =
  allDivisions.find((d) => d.division_id === divisionId) ?? {};
const divisionLabel = divisionMeta.division ?? divisionId;

const groupeMeta = allGroupes.find((g) => g.groupe_id === groupeId) ?? {};
const groupeLabel = groupeMeta.groupe ?? groupeId;

const classeMeta = allClasses.find((c) => c.classe_id === classeId) ?? {};
const classeLabel = classeMeta.classe ?? classeId;
const totalEtablissements = classeMeta.nb_etablissements
  ? +classeMeta.nb_etablissements
  : 0;

const codesApe = allCodesApe
  .filter((d) => d.classe_id === classeId)
  .map((d) => ({ ...d, nb_etablissements: +d.nb_etablissements }))
  .sort((a, b) => b.nb_etablissements - a.nb_etablissements);
```

```js
display(
  html`<div class="page-header">
    <div class="breadcrumb">
      <a href="/">Accueil</a> › <a href="/sirene">SIRENE</a> ›
      <a href="/sirene/${sectionId}">Section ${sectionId}</a> ›
      <a href="/sirene/${sectionId}/${divisionId}">Division ${divisionId}</a> ›
      <a href="/sirene/${sectionId}/${divisionId}/${groupeId}"
        >Groupe ${groupeId}</a
      >
      › Classe ${classeId}
    </div>
    <h1>${classeLabel}</h1>
    <p class="page-subtitle">
      Classe ${classeId} — ${totalEtablissements.toLocaleString("fr-FR")} établissements
      SIRENE répartis sur ${codesApe.length} code(s) APE.
    </p>
  </div>`,
);
```

## Vue d'ensemble

<div class="stat-grid">
  <div class="stat-card">
    <div class="stat-value">${totalEtablissements.toLocaleString("fr-FR")}</div>
    <div class="stat-label">Établissements</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${codesApe.length}</div>
    <div class="stat-label">Codes APE</div>
  </div>
</div>

## Codes APE

<div class="chart-description">Répartition des établissements de la classe ${classeId} par code APE. Cliquez sur un code APE pour voir sa carte géographique.</div>

```js
display(
  apeClickableChart(codesApe, {
    fill: "#81c784",
    totalEtablissements,
    hrefFn: (d) =>
      `/sirene/${sectionId}/${divisionId}/${groupeId}/${classeId}/${d.sous_classe_id}`,
  }),
);
```

<div class="source-note">
  Source : <a href="/dataset/sirene">Dataset SIRENE</a> — registre national des entreprises géré par l'<a href="https://www.sirene.fr" target="_blank">INSEE</a>. Codes d'activité : <a href="/nafrev2">NAF Rév. 2</a>.
</div>

```js
display(
  html`<div class="see-also">
    <h3>Voir aussi</h3>
    <div class="see-also-links">
      <a
        class="see-also-link"
        href="/sirene/${sectionId}/${divisionId}/${groupeId}"
        >← Groupe ${groupeId} — ${groupeLabel}</a
      >
      <a class="see-also-link" href="/nafrev2"
        >📋 Référentiel NAF — classe ${classeId}</a
      >
      <a class="see-also-link" href="/dataset/sirene">🏢 Dataset SIRENE</a>
    </div>
  </div>`,
);
```
