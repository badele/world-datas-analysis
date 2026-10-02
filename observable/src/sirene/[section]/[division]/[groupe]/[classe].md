---
title: SIRENE — Classe
---

```js
import { apeClickableChart } from "../../../../components/sirene-charts.js";

import { initNafrev2DB } from "../../../../components/nafrev2-db.js";
import { initSireneStatsDB } from "../../../../components/sirene-stats-db.js";
```

```js
const sectionId = observable.params.section;
const divisionId = observable.params.division;
const groupeId = observable.params.groupe;
const classeId = observable.params.classe;
const { conn: _naf2conn } = await initNafrev2DB(invalidation);
const _secResult = await _naf2conn.query(
  `SELECT section_id, section FROM read_parquet('sections.parquet') ORDER BY section_id`,
);
const sections = _secResult
  .toArray()
  .map((r) => ({ section_id: r.section_id, section: r.section }));
const _divResult = await _naf2conn.query(
  `SELECT section_id, division_id, division FROM read_parquet('divisions.parquet') ORDER BY division_id`,
);
const allDivisions = _divResult
  .toArray()
  .map((r) => ({
    section_id: r.section_id,
    division_id: r.division_id,
    division: r.division,
  }));

const { conn: _statsConn } = await initSireneStatsDB(invalidation);
const _allGrpResult = await _statsConn.query(
  `SELECT * FROM read_parquet('stats-by-groupe.parquet')`,
);
const allGroupes = _allGrpResult
  .toArray()
  .map((r) => ({
    section_id: r.section_id,
    division_id: r.division_id,
    groupe_id: r.groupe_id,
    groupe: r.groupe,
    nb_etablissements: Number(r.nb_etablissements),
  }));
const _allClsResult = await _statsConn.query(
  `SELECT * FROM read_parquet('stats-by-classe.parquet')`,
);
const allClasses = _allClsResult
  .toArray()
  .map((r) => ({
    section_id: r.section_id,
    division_id: r.division_id,
    groupe_id: r.groupe_id,
    classe_id: r.classe_id,
    classe: r.classe,
    nb_etablissements: Number(r.nb_etablissements),
  }));
const _allApeResult = await _statsConn.query(
  `SELECT * FROM read_parquet('top-codes-ape.parquet')`,
);
const allCodesApe = _allApeResult
  .toArray()
  .map((r) => ({
    section_id: r.section_id,
    division_id: r.division_id,
    groupe_id: r.groupe_id,
    classe_id: r.classe_id,
    sous_classe_id: r.sous_classe_id,
    sous_classe: r.sous_classe,
    nb_etablissements: Number(r.nb_etablissements),
  }));
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
