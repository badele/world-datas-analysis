---
title: Dataset — SIRENE
---

<div class="page-header">
  <div class="breadcrumb"><a href="/">Accueil</a> › Datasets › SIRENE</div>
  <h1>Dataset SIRENE</h1>
  <p class="page-subtitle">Registre national des entreprises et établissements français, géré par l'INSEE.</p>
</div>

```js
const datasets = await FileAttachment("../data/wda-datasets.json").json();
const meta = datasets.find((d) => d.provider === "sirene");

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
    <a class="see-also-link" href="/nafrev2">📊 Répartition des établissements par secteur NAF</a>
    <a class="see-also-link" href="/dataset/nafrev2">📋 Dataset NAF Rév. 2</a>
  </div>
</div>
