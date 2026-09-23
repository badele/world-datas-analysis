---
title: SIRENE — Code APE
---

```js
import {
  createSireneMap,
  effectifsLabel,
} from "../../../../../components/sirene-map.js";
```

```js
const sectionId = observable.params.section;
const divisionId = observable.params.division;
const groupeId = observable.params.groupe;
const classeId = observable.params.classe;
const apeId = observable.params.ape;

const sections = FileAttachment(
  "../../../../../data/nafrev2-sections.json",
).json();
const allDivisions = FileAttachment(
  "../../../../../data/nafrev2-divisions.json",
).json();
const allGroupes = FileAttachment(
  "../../../../../data/sirene-stats-by-groupe.json",
).json();
const allClasses = FileAttachment(
  "../../../../../data/sirene-stats-by-classe.json",
).json();
const allCodesApe = FileAttachment(
  "../../../../../data/sirene-top-codes-ape.json",
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

const apeMeta = allCodesApe.find((d) => d.sous_classe_id === apeId) ?? {};
const apeLabel = apeMeta.sous_classe ?? apeId;
const totalEtablissements = apeMeta.nb_etablissements
  ? +apeMeta.nb_etablissements
  : 0;
```

```js
const resp = await fetch(
  `/_file/data/sirene-etabs/${encodeURIComponent(apeId)}.json`,
);
const etabs = resp.ok ? await resp.json() : [];
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
      ›
      <a href="/sirene/${sectionId}/${divisionId}/${groupeId}/${classeId}"
        >Classe ${classeId}</a
      >
      › APE ${apeId}
    </div>
    <h1>${apeId} — ${apeLabel}</h1>
    <p class="page-subtitle">
      Classe ${classeId} · Groupe ${groupeId} · Division ${divisionId} · Section
      ${sectionId}
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
</div>

## Carte

<div class="chart-description">Répartition géographique des établissements avec le code APE ${apeId}. Filtrez par tranche d'effectifs. Zoomez pour voir les établissements individuels.</div>

```js
{
  const mapEl = document.createElement("div");
  mapEl.style.cssText = "width:100%;";
  display(mapEl);

  const detailEl = document.createElement("div");
  detailEl.className = "etab-detail-panel";
  detailEl.style.display = "none";
  display(detailEl);

  createSireneMap(mapEl, apeId, etabs, {
    onEtabSelect(p) {
      const siren = p.siret?.slice(0, 9) ?? "";
      const dateStr = p.date_creation
        ? new Date(p.date_creation).toLocaleDateString("fr-FR", {
            year: "numeric",
            month: "long",
            day: "numeric",
          })
        : null;
      const effLabel = effectifsLabel(p.effectifs_min);
      detailEl.style.display = "block";
      detailEl.innerHTML = `
        <div class="etab-detail-header">
          <div style="display:flex;align-items:center;gap:0.6rem;flex-wrap:wrap">
            <strong class="etab-detail-name">${p.name}</strong>
            ${
              p.is_siege
                ? `<span class="etab-badge etab-badge-siege">Siège social</span>`
                : ""
            }
          </div>
          <button class="etab-detail-close" title="Fermer">✕</button>
        </div>
        <div class="etab-detail-body">
          <div class="etab-detail-col">
            ${
              p.address
                ? `<div class="etab-info-row"><span class="etab-info-label">Adresse</span><span class="etab-info-value">${p.address}</span></div>`
                : ""
            }
            ${
              p.dept
                ? `<div class="etab-info-row"><span class="etab-info-label">Département</span><span class="etab-info-value">${p.dept}</span></div>`
                : ""
            }
            ${
              dateStr
                ? `<div class="etab-info-row"><span class="etab-info-label">Ouverture</span><span class="etab-info-value">${dateStr}</span></div>`
                : ""
            }
            <div class="etab-info-row"><span class="etab-info-label">Effectifs</span><span class="etab-info-value">${effLabel}</span></div>
          </div>
          <div class="etab-detail-col">
            ${
              p.legal_name
                ? `<div class="etab-info-row"><span class="etab-info-label">Raison sociale</span><span class="etab-info-value">${p.legal_name}</span></div>`
                : ""
            }
            <div class="etab-info-row"><span class="etab-info-label">SIRET</span><span class="etab-info-value">${
              p.siret
            }</span></div>
            <div class="etab-info-row"><span class="etab-info-label">SIREN</span><span class="etab-info-value">${siren}</span></div>
          </div>
        </div>`;
      detailEl.querySelector(".etab-detail-close").onclick = () => {
        detailEl.style.display = "none";
      };
    },
  });
}
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
        href="/sirene/${sectionId}/${divisionId}/${groupeId}/${classeId}"
        >← Classe ${classeId} — ${classeLabel}</a
      >
      <a class="see-also-link" href="/nafrev2"
        >📋 Référentiel NAF — code ${apeId}</a
      >
      <a class="see-also-link" href="/dataset/sirene">🏢 Dataset SIRENE</a>
    </div>
  </div>`,
);
```
