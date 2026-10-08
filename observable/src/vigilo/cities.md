---
title: Vigilo — Toutes les villes
---

```js
import { createVigiloMap } from "../components/vigilo-map.js";
import { createMultiSelect } from "../components/wda-multiselect.js";
import { initVigiloDB } from "../components/vigilo-db.js";
import * as Plot from "npm:@observablehq/plot";
```

```js
const _vigiBase = "https://pub-6526c18d68154746a16baf2f76a38544.r2.dev/vigilo";
const { db, conn } = await initVigiloDB(_vigiBase, invalidation);

const _obsResult = await conn.query(`
  SELECT o.scopeid, o.token, o.ts,
         ROUND(o.latitude::DOUBLE, 6) AS latitude,
         ROUND(o.longitude::DOUBLE, 6) AS longitude,
         o.address, o.catid,
         c.name AS category, c.color,
         o.geonames_city
  FROM read_parquet('observations.parquet') o
  LEFT JOIN read_parquet('categories.parquet') c ON c.id = o.catid
  WHERE o.latitude IS NOT NULL AND o.longitude IS NOT NULL
`);
const allObs = _obsResult.toArray().map((r) => ({
  scopeid: r.scopeid,
  token: r.token,
  ts: r.ts !== null ? Number(r.ts) : null,
  latitude: r.latitude !== null ? Number(r.latitude) : null,
  longitude: r.longitude !== null ? Number(r.longitude) : null,
  address: r.address,
  catid: r.catid !== null ? Number(r.catid) : null,
  category: r.category,
  color: r.color,
  geonames_city: r.geonames_city,
}));

const _scopesResult = await conn.query(`
  SELECT id, display_name, is_active
  FROM read_parquet('scopes.parquet')
  ORDER BY display_name
`);
const scopes = _scopesResult.toArray().map((r) => ({
  id: r.id,
  display_name: r.display_name,
  is_active: r.is_active,
}));

const _statsResult = await conn.query(`
  SELECT s.id, s.display_name, s.is_active,
         COUNT(o.token)::INTEGER AS count
  FROM read_parquet('scopes.parquet') s
  LEFT JOIN read_parquet('observations.parquet') o ON o.scopeid = s.id
  GROUP BY s.id, s.display_name, s.is_active
  ORDER BY count DESC
`);
const stats = _statsResult.toArray().map((r) => ({
  id: r.id,
  display_name: r.display_name,
  is_active: r.is_active,
  count: Number(r.count),
}));
```

<div class="page-header">
  <div class="breadcrumb"><a href="./">Accueil</a> › <a href="vigilo">Vigilo</a> › Toutes les villes</div>
  <h1>Carte des signalements Vigilo</h1>
  <p class="page-subtitle">Visualisation de l'ensemble des signalements citoyens sur le territoire français. Zoomez pour passer de la heatmap de densité aux points individuels.</p>
</div>

<div class="grid grid-cols-2">

<div class="card">
<h3>À propos de Vigilo</h3>
<div class="meta-row">
  <div class="meta-item">
    <div class="meta-label">Description</div>
    <div class="meta-value">Signalements citoyens liés aux déplacements vélo et piétons dans les villes françaises.</div>
  </div>
  <div class="meta-item">
    <div class="meta-label">Total signalements</div>
    <div class="meta-value">${allObs.length.toLocaleString("fr-FR")}</div>
  </div>
  <div class="meta-item">
    <div class="meta-label">Instances</div>
    <div class="meta-value">${stats.filter(d => d.count > 0).length} actives sur ${scopes.length} connues</div>
  </div>
  <div class="meta-item">
    <div class="meta-label">Couverture</div>
    <div class="meta-value">France métropolitaine</div>
  </div>
  <div class="meta-item">
    <div class="meta-label">Licence</div>
    <div class="meta-value">Open Data — CC BY</div>
  </div>
  <div class="meta-item">
    <div class="meta-label">Source</div>
    <div class="meta-value"><a href="dataset/vigilo">Dataset Vigilo</a> (<a href="https://vigilo.city" target="_blank">vigilo.city</a>)</div>
  </div>
</div>
</div>

<div class="card">
<h3>Instances disponibles</h3>
<div class="meta-row">

```js
for (const s of stats
  .filter((d) => d.count > 0)
  .sort((a, b) => b.count - a.count)) {
  display(
    html`<div class="meta-item">
      <div class="meta-label">
        <a href="vigilo/${s.id}">${s.display_name}</a>
      </div>
      <div class="meta-value">
        ${Number(s.count).toLocaleString("fr-FR")} signalements
      </div>
    </div>`,
  );
}
```

</div>
</div>

</div>

<div class="filter-bar">

```js
const selectedScopes = view(
  createMultiSelect(scopes, {
    label: "Instance",
    format: (d) => d.display_name,
    keyOf: (d) => d.id,
  }),
);
```

```js
const availableCities = [
  ...new Set(
    (selectedScopes.length > 0
      ? allObs.filter((d) => selectedScopes.includes(d.scopeid))
      : allObs
    )
      .map((d) => d.geonames_city)
      .filter(Boolean),
  ),
].sort((a, b) => a.localeCompare(b));

const selectedCities = view(
  createMultiSelect(availableCities, { label: "Ville" }),
);
```

```js
const observations = (
  selectedScopes.length > 0
    ? allObs.filter((d) => selectedScopes.includes(d.scopeid))
    : allObs
).filter(
  (d) =>
    selectedCities.length === 0 || selectedCities.includes(d.geonames_city),
);
```

<span class="obs-count">${observations.length.toLocaleString("fr-FR")} signalement(s)</span>

</div>

```js
const obsWithCoords = observations.filter(
  (d) => d.latitude != null && d.longitude != null && d.latitude !== "",
);
let mapLat = 46.5,
  mapLon = 2.35,
  mapZoom = 5;
if (obsWithCoords.length) {
  const lats = obsWithCoords.map((d) => +d.latitude).sort((a, b) => a - b);
  const lons = obsWithCoords.map((d) => +d.longitude).sort((a, b) => a - b);
  mapLat = (lats[0] + lats[lats.length - 1]) / 2;
  mapLon = (lons[0] + lons[lons.length - 1]) / 2;
  const span = Math.max(
    lats[lats.length - 1] - lats[0],
    lons[lons.length - 1] - lons[0],
  );
  if (span > 0)
    mapZoom = Math.max(4, Math.min(13, Math.round(Math.log2(0.5 / span) + 10)));
}
const mapDiv = display(document.createElement("div"));
mapDiv.className = "vigilo-map";
const map = createVigiloMap(mapDiv, observations, {
  center: [mapLon, mapLat],
  zoom: mapZoom,
});
invalidation.then(() => map.remove());
```

<div class="source-note">
  Source : <a href="dataset/vigilo">Dataset Vigilo</a> — signalements collectés par des collectifs cyclistes locaux via <a href="https://vigilo.city" target="_blank">vigilo.city</a>.
</div>

<div class="see-also">
  <h3>Voir aussi</h3>
  <div class="see-also-links">
    <a class="see-also-link" href="vigilo">📊 Vue d'ensemble par instance</a>
    <a class="see-also-link" href="./">← Retour à l'accueil</a>
  </div>
</div>
