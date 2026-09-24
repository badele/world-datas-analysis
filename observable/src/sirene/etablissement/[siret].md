---
title: Fiche établissement SIRENE
---

```js
import * as maplibregl from "npm:maplibre-gl";
maplibregl.setWorkerUrl(
  "https://unpkg.com/maplibre-gl/dist/maplibre-gl-worker.mjs",
);
```

```js
const siret = observable.params.siret;
const etab = await FileAttachment(
  `../../data/sirene-etablissement/${siret}.json`,
).json();
```

```js
if (!etab)
  display(
    html`<div class="page-header">
      <h1>Établissement introuvable</h1>
      <p class="page-subtitle">SIRET : ${siret}</p>
    </div>`,
  );
```

```js
if (etab) {
  const siren = etab.siret?.slice(0, 9) ?? "";
  const categLabels = {
    GE: "Grande entreprise",
    ETI: "ETI",
    PME: "PME",
    undefined: "",
  };
  const effLabel =
    etab.effectifs_min > 0
      ? `${etab.effectifs_min}+ salarié(s)`
      : "Non déclarés";
  const dateEts = etab.date_creation
    ? new Date(etab.date_creation).toLocaleDateString("fr-FR", {
        year: "numeric",
        month: "long",
        day: "numeric",
      })
    : null;
  const dateUE = etab.date_creation_ue
    ? new Date(etab.date_creation_ue).toLocaleDateString("fr-FR", {
        year: "numeric",
        month: "long",
      })
    : null;
  const apePath =
    etab.insee_section_id &&
    etab.insee_division_id &&
    etab.insee_groupe_id &&
    etab.insee_classe_id &&
    etab.insee_sous_classe_id
      ? `/sirene/${etab.insee_section_id}/${etab.insee_division_id}/${etab.insee_groupe_id}/${etab.insee_classe_id}/${etab.insee_sous_classe_id}`
      : null;

  display(
    html`<div class="page-header">
      <div class="breadcrumb">
        <a href="/">Accueil</a> › <a href="/sirene">SIRENE</a> › ${apePath
          ? html`<a href="${apePath}">APE ${etab.ape_code}</a> ›`
          : ""} Fiche établissement
      </div>
      <div
        style="display:flex;align-items:center;gap:0.75rem;flex-wrap:wrap;margin-bottom:0.25rem"
      >
        <h1 style="margin:0">${etab.name}</h1>
        ${etab.is_siege
          ? html`<span class="etab-badge etab-badge-siege">Siège social</span>`
          : ""} ${etab.categorie
          ? html`<span class="etab-badge etab-badge-cat"
              >${etab.categorie}</span
            >`
          : ""}
      </div>
      <p class="page-subtitle">SIRET ${etab.siret} · SIREN ${siren}</p>
    </div>`,
  );

  display(
    html`<div class="stat-grid">
      ${dateEts
        ? html`<div class="stat-card">
            <div class="stat-value">${dateEts}</div>
            <div class="stat-label">Ouverture établissement</div>
          </div>`
        : ""}
      <div class="stat-card">
        <div class="stat-value">${effLabel}</div>
        <div class="stat-label">Effectifs</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">${etab.city ?? "—"}</div>
        <div class="stat-label">Commune</div>
      </div>
      ${etab.dept
        ? html`<div class="stat-card">
            <div class="stat-value">${etab.dept}</div>
            <div class="stat-label">Département</div>
          </div>`
        : ""}
    </div>`,
  );
}
```

```js
if (etab) {
  const addr = [etab.street, etab.postal, etab.city].filter(Boolean).join(" ");
  const siren = etab.siret?.slice(0, 9) ?? "";
  const apePath =
    etab.insee_section_id && etab.insee_sous_classe_id
      ? `/sirene/${etab.insee_section_id}/${etab.insee_division_id}/${etab.insee_groupe_id}/${etab.insee_classe_id}/${etab.insee_sous_classe_id}`
      : null;

  display(
    html`<div class="etab-sections">
      <div class="etab-section">
        <h2>Adresse</h2>
        <div class="etab-info-grid">
          ${etab.street
            ? html`<div class="etab-info-row">
                <span class="etab-info-label">Voie</span
                ><span class="etab-info-value">${etab.street}</span>
              </div>`
            : ""} ${etab.postal
            ? html`<div class="etab-info-row">
                <span class="etab-info-label">Code postal</span
                ><span class="etab-info-value">${etab.postal}</span>
              </div>`
            : ""} ${etab.city
            ? html`<div class="etab-info-row">
                <span class="etab-info-label">Commune</span
                ><span class="etab-info-value">${etab.city}</span>
              </div>`
            : ""} ${etab.dept
            ? html`<div class="etab-info-row">
                <span class="etab-info-label">Département</span
                ><span class="etab-info-value">${etab.dept}</span>
              </div>`
            : ""}
        </div>
      </div>

      <div class="etab-section">
        <h2>Activité</h2>
        <div class="etab-info-grid">
          <div class="etab-info-row">
            <span class="etab-info-label">Code APE</span>
            <span class="etab-info-value">
              ${apePath
                ? html`<a href="${apePath}">${etab.ape_code}</a>`
                : etab.ape_code} ${etab.ape_label
                ? html` — ${etab.ape_label}`
                : ""}
            </span>
          </div>
          ${etab.insee_division
            ? html`<div class="etab-info-row">
                <span class="etab-info-label">Division NAF</span
                ><span class="etab-info-value"
                  >${etab.insee_division_id} — ${etab.insee_division}</span
                >
              </div>`
            : ""} ${etab.insee_section
            ? html`<div class="etab-info-row">
                <span class="etab-info-label">Section NAF</span
                ><span class="etab-info-value"
                  >${etab.insee_section_id} — ${etab.insee_section}</span
                >
              </div>`
            : ""}
        </div>
      </div>

      <div class="etab-section">
        <h2>Unité légale</h2>
        <div class="etab-info-grid">
          ${etab.legal_name
            ? html`<div class="etab-info-row">
                <span class="etab-info-label">Dénomination</span
                ><span class="etab-info-value">${etab.legal_name}</span>
              </div>`
            : ""} ${etab.sigle
            ? html`<div class="etab-info-row">
                <span class="etab-info-label">Sigle</span
                ><span class="etab-info-value">${etab.sigle}</span>
              </div>`
            : ""}
          <div class="etab-info-row">
            <span class="etab-info-label">SIREN</span
            ><span class="etab-info-value">${siren}</span>
          </div>
          ${etab.date_creation_ue
            ? html`<div class="etab-info-row">
                <span class="etab-info-label">Création entreprise</span
                ><span class="etab-info-value"
                  >${new Date(etab.date_creation_ue).toLocaleDateString(
                    "fr-FR",
                    { year: "numeric", month: "long" },
                  )}</span
                >
              </div>`
            : ""} ${etab.categorie
            ? html`<div class="etab-info-row">
                <span class="etab-info-label">Catégorie</span
                ><span class="etab-info-value">${etab.categorie}</span>
              </div>`
            : ""}
        </div>
      </div>
    </div>`,
  );
}
```

## Localisation

```js
if (etab && etab.latitude && etab.longitude) {
  const mapEl = document.createElement("div");
  mapEl.style.cssText =
    "width:100%;height:320px;border-radius:8px;overflow:hidden;margin-top:0.5rem;";
  display(mapEl);

  const map = new maplibregl.Map({
    container: mapEl,
    style: "https://tiles.openfreemap.org/styles/positron",
    center: [etab.longitude, etab.latitude],
    zoom: 15,
    attributionControl: { compact: true },
  });

  new maplibregl.Marker({ color: "#e53935" })
    .setLngLat([etab.longitude, etab.latitude])
    .setPopup(
      new maplibregl.Popup().setHTML(
        `<strong>${etab.name}</strong>${
          etab.street ? `<br>${etab.street}` : ""
        }`,
      ),
    )
    .addTo(map);
}
```

```js
if (etab) {
  const apePath =
    etab.insee_section_id && etab.insee_sous_classe_id
      ? `/sirene/${etab.insee_section_id}/${etab.insee_division_id}/${etab.insee_groupe_id}/${etab.insee_classe_id}/${etab.insee_sous_classe_id}`
      : null;
  display(
    html`<div class="source-note">
      Source : <a href="/dataset/sirene">Dataset SIRENE</a> — INSEE.
    </div>`,
  );
  display(
    html`<div class="see-also">
      <h3>Voir aussi</h3>
      <div class="see-also-links">
        ${apePath
          ? html`<a class="see-also-link" href="${apePath}"
              >← APE ${etab.ape_code} — ${etab.ape_label ?? ""}</a
            >`
          : ""}
        <a class="see-also-link" href="/sirene">🏢 Vue d'ensemble SIRENE</a>
      </div>
    </div>`,
  );
}
```
