---
title: Dataset — Vigilo
---

<div class="page-header">
  <div class="breadcrumb"><a href="/">Accueil</a> › Datasets › Vigilo</div>
  <h1>Dataset Vigilo</h1>
  <p class="page-subtitle">Signalements citoyens liés aux déplacements vélo et piétons, collectés via l'application Vigilo.</p>
</div>

```js
const datasets = await FileAttachment("../data/wda-datasets.json").json();
const meta = datasets.find((d) => d.provider === "vigilo");

display(
  html`<div class="card">
    <h3>Informations</h3>
    <div class="meta-row">
      <div class="meta-item">
        <div class="meta-label">Description</div>
        <div class="meta-value">${meta.description}</div>
      </div>
      <div class="meta-item">
        <div class="meta-label">Source officielle</div>
        <div class="meta-value">
          <a href="${meta.source}" target="_blank">${meta.website}</a>
        </div>
      </div>
      <div class="meta-item">
        <div class="meta-label">Observations</div>
        <div class="meta-value">
          ${meta.nb_observations.toLocaleString("fr-FR")}
        </div>
      </div>
      <div class="meta-item">
        <div class="meta-label">Variables</div>
        <div class="meta-value">${meta.nb_variables}</div>
      </div>
      <div class="meta-item">
        <div class="meta-label">Périmètres (${meta.wda_scope})</div>
        <div class="meta-value">${meta.nb_scopes.toLocaleString("fr-FR")}</div>
      </div>
    </div>
  </div>`,
);
```

<div class="see-also">
  <h3>Explorer les données</h3>
  <div class="see-also-links">
    <a class="see-also-link" href="/vigilo">📊 Vue d'ensemble par instance</a>
    <a class="see-also-link" href="/vigilo/cities">🗺 Carte de toutes les villes</a>
  </div>
</div>
