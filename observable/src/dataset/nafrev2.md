---
title: Dataset — NAF Rév. 2
---

<div class="page-header">
  <div class="breadcrumb"><a href="/">Accueil</a> › Datasets › NAF Rév. 2</div>
  <h1>Dataset NAF Rév. 2</h1>
  <p class="page-subtitle">Nomenclature française des activités économiques, référentiel hiérarchique publié par l'INSEE.</p>
</div>

```js
const datasets = await FileAttachment("../data/wda-datasets.json").json();
const meta = datasets.find((d) => d.provider === "nafrev2");

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
    <a class="see-also-link" href="/nafrev2">📊 Explorer la hiérarchie NAF Rév. 2</a>
    <a class="see-also-link" href="/dataset/sirene">🏢 Dataset SIRENE (utilise les codes APE)</a>
  </div>
</div>
