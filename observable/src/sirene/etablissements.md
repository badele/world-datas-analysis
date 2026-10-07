---
title: SIRENE — Recherche établissements
---

```js
import * as duckdb from "npm:@duckdb/duckdb-wasm";
import { createSireneMap, effectifsLabel } from "../components/sirene-map.js";
import { showPopup } from "../components/popup.js";
```

```js
const etabStats = await FileAttachment("../data/sirene-etab-stats.json").json();
const _stats = etabStats[0] ?? {};
```

```js
const R2_BASE = "https://pub-6526c18d68154746a16baf2f76a38544.r2.dev/sirene";
const MAX_ETABS_TABLE = 50_000;

function etabParquetUrl(prefix) {
  return `${R2_BASE}/observable__etab__pfx.${prefix}__data_0.parquet`;
}
```

```js
const _state = (() => {
  if (!window._etabState) {
    window._etabState = {
      db: null,
      parquetCache: new Map(),
      registered: new Set(),
    };
  }
  invalidation.then(() => {
    window._etabState.db?.terminate().catch(() => {});
    window._etabState.db = null;
    window._etabState.registered.clear();
  });
  return window._etabState;
})();
```

<div class="page-header">
  <div class="breadcrumb"><a href="/">Accueil</a> › <a href="/sirene">SIRENE</a> › Établissements</div>
  <h1>SIRENE — Recherche d'établissements</h1>
  <p class="page-subtitle">Recherchez des établissements par nom ou raison sociale parmi les ${(_stats.nb_etablissements ?? 0).toLocaleString("fr-FR")} établissements géolocalisés du registre SIRENE.</p>
</div>

<div class="stat-grid">
  <div class="stat-card">
    <div class="stat-value">${(_stats.nb_etablissements ?? 0).toLocaleString("fr-FR")}</div>
    <div class="stat-label">Établissements géolocalisés</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${(_stats.nb_siren ?? 0).toLocaleString("fr-FR")}</div>
    <div class="stat-label">Entreprises (SIREN)</div>
  </div>
</div>

## Recherche

<div class="filter-bar">

```js
const etabNameSearch = view(
  Inputs.text({
    label: "Établissement",
    placeholder: "Nom ou raison sociale… (ex: Renault, Mairie de Paris…)",
    title: "Recherche par préfixe — saisissez au moins 3 caractères",
    debounce: 400,
  }),
);
```

</div>

<!-- Spinner -->
<div id="etab-loading" class="map-loading" style="display:none">
  <div class="map-loading-spinner"></div>
  <span id="etab-loading-text">Chargement…</span>
</div>

<!-- Map host — stable DOM position required by MapLibre -->
<div id="etab-map-host" style="display:none"></div>

<!-- Results container — filled by click handler -->
<div id="etab-results"></div>

```js
// Persistent MapLibre instance — created once, updated on each search
const _mapEtab = (() => {
  const m = createSireneMap(
    document.getElementById("etab-map-host"),
    "",
    [],
    {},
  );
  window._etabMapInstance = m;
  invalidation.then(() => {
    m.remove();
    window._etabMapInstance = null;
  });
  return m;
})();
```

```js
{
  // Reset display on every reactive update (input change)
  document.getElementById("etab-map-host").style.display = "none";
  document.getElementById("etab-loading").style.display = "none";
  document.getElementById("etab-results").innerHTML = "";

  const term = (etabNameSearch ?? "").trim();

  if (term.length === 0) {
    // nothing
  } else if (term.length < 3) {
    display(
      html`<div
        class="hint"
        style="margin:.75rem 0;color:var(--theme-foreground-muted)"
      >
        Saisissez au moins 3 caractères pour lancer la recherche.
      </div>`,
    );
  } else {
    const prefix = term.slice(0, 2).toLowerCase();
    const url = etabParquetUrl(prefix);

    const btn = html`<button
      style="
      display:inline-flex;align-items:center;gap:.5rem;
      padding:.6rem 1.4rem;margin:.75rem 0 .5rem;
      background:var(--theme-foreground-focus,#3b82f6);color:#fff;
      border:none;border-radius:6px;font-size:.95rem;font-weight:500;
      cursor:pointer;transition:opacity .15s;
    "
    >
      Rechercher "${term}"
    </button>`;

    btn.addEventListener("click", async () => {
      btn.disabled = true;
      btn.style.opacity = "0.45";
      btn.style.cursor = "not-allowed";
      btn.textContent = "Chargement…";

      const loadEl = document.getElementById("etab-loading");
      const hostEl = document.getElementById("etab-map-host");
      const resEl = document.getElementById("etab-results");
      const setTxt = (t) => {
        document.getElementById("etab-loading-text").textContent = t;
      };

      loadEl.style.display = "";
      hostEl.style.display = "none";
      resEl.innerHTML = "";

      try {
        // Phase 1 : fetch parquet (cached by prefix)
        if (!_state.parquetCache.has(prefix)) {
          setTxt(`Téléchargement (${prefix})…`);
          const resp = await fetch(url);
          if (resp.status === 404) {
            _state.parquetCache.set(prefix, null);
          } else if (!resp.ok) {
            throw new Error(`HTTP ${resp.status} — ${url}`);
          } else {
            _state.parquetCache.set(prefix, await resp.arrayBuffer());
          }
        }

        if (_state.parquetCache.get(prefix) === null) {
          loadEl.style.display = "none";
          btn.disabled = false;
          btn.style.opacity = "";
          btn.style.cursor = "";
          btn.textContent = "Aucune donnée pour ce préfixe";
          return;
        }

        // Phase 2 : init DuckDB WASM (once per session)
        if (!_state.db) {
          setTxt("Initialisation WASM…");
          const bundles = duckdb.getJsDelivrBundles();
          const bundle = await duckdb.selectBundle(bundles);
          const workerUrl = URL.createObjectURL(
            new Blob([`importScripts("${bundle.mainWorker}");`], {
              type: "text/javascript",
            }),
          );
          const worker = new Worker(workerUrl);
          const instance = new duckdb.AsyncDuckDB(
            new duckdb.VoidLogger(),
            worker,
          );
          await instance.instantiate(bundle.mainModule, bundle.pthreadWorker);
          _state.db = instance;
        }

        // Phase 3 : register parquet in VFS (once per prefix)
        const fileName = `etab_${prefix}.parquet`;
        if (!_state.registered.has(prefix)) {
          setTxt(`Indexation (${prefix})…`);
          await _state.db.registerFileBuffer(
            fileName,
            new Uint8Array(_state.parquetCache.get(prefix).slice(0)),
          );
          _state.registered.add(prefix);
        }

        // Phase 4 : SQL
        setTxt("Requête SQL…");
        const conn = await _state.db.connect();
        try {
          const escapedName = term.replace(/'/g, "''").toLowerCase();
          const escapedSiret = term.replace(/'/g, "''");
          const whereClause =
            `WHERE LOWER(name) LIKE '${escapedName}%'` +
            ` OR siret LIKE '${escapedSiret}%'`;

          const countResult = await conn.query(
            `SELECT COUNT(*) AS cnt FROM read_parquet('${fileName}') ${whereClause}`,
          );
          const count = Number(countResult.toArray()[0].cnt);

          loadEl.style.display = "none";

          if (count === 0) {
            btn.textContent = "Aucun résultat";
            btn.disabled = false;
            btn.style.opacity = "";
            btn.style.cursor = "";
            return;
          }

          if (count > MAX_ETABS_TABLE) {
            btn.disabled = false;
            btn.style.opacity = "";
            btn.style.cursor = "";
            btn.textContent = "Affiner la recherche";
            resEl.innerHTML = `
              <div class="too-many-warning">
                <svg class="too-many-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                     fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                  <line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
                </svg>
                <span><strong>${count.toLocaleString(
                  "fr-FR",
                )} établissements</strong> correspondent —
                trop pour afficher (limite : ${MAX_ETABS_TABLE.toLocaleString(
                  "fr-FR",
                )}).
                Saisissez un préfixe plus long pour affiner.</span>
              </div>`;
            return;
          }

          const result = await conn.query(
            `SELECT latitude, longitude, name, legal_name, adresse, siret,
                    nb_effectifs_min, is_siege,
                    CAST(date_creation AS VARCHAR) AS date_creation,
                    dept, ape
             FROM read_parquet('${fileName}')
             ${whereClause}
             ORDER BY nb_effectifs_min DESC NULLS LAST`,
          );

          const rows = result
            .toArray()
            .map((r) => [
              r.latitude,
              r.longitude,
              r.name ?? "",
              r.adresse ?? "",
              r.siret ?? "",
              Number(r.nb_effectifs_min ?? 0),
              r.is_siege ? 1 : 0,
              r.date_creation ?? null,
              r.legal_name ?? "",
              r.dept ?? "",
              r.ape ?? "",
            ]);

          // Map
          if (rows.some((r) => r[0] != null && r[1] != null)) {
            hostEl.style.display = "";
            window._etabMapInstance?.update(
              rows,
              `${count.toLocaleString("fr-FR")} établissement${
                count > 1 ? "s" : ""
              } — « ${term} »`,
            );
          }

          btn.textContent = `${count.toLocaleString("fr-FR")} résultat${
            count > 1 ? "s" : ""
          } ✓`;

          // Table
          const TABLE_MAX = 1_000;
          const tableRows = rows.slice(0, TABLE_MAX);
          const truncated = rows.length > TABLE_MAX;

          const tableHtml = `
            <div style="margin-top:1.25rem">
              ${
                truncated
                  ? `<div class="too-many-warning" style="margin-bottom:.75rem">
                       <svg class="too-many-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                            fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                         <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                         <line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
                       </svg>
                       <span>Tableau limité aux <strong>${TABLE_MAX.toLocaleString(
                         "fr-FR",
                       )}</strong>
                       premiers résultats sur ${rows.length.toLocaleString(
                         "fr-FR",
                       )} — affinez la recherche.</span>
                     </div>`
                  : `<p class="etab-table-count">${rows.length.toLocaleString(
                      "fr-FR",
                    )} établissement${rows.length > 1 ? "s" : ""}</p>`
              }
              <div style="overflow-x:auto">
                <table class="wda-table">
                  <thead>
                    <tr>
                      <th>Établissement</th>
                      <th>Adresse</th>
                      <th>APE</th>
                      <th>SIREN</th>
                      <th>SIRET</th>
                      <th>Effectifs</th>
                      <th>Création</th>
                    </tr>
                  </thead>
                  <tbody id="etab-tbody"></tbody>
                </table>
              </div>
            </div>`;
          resEl.innerHTML = tableHtml;

          const tbody = resEl.querySelector("#etab-tbody");
          for (const r of tableRows) {
            const nom = r[2] ?? "";
            const legal = r[8] ?? "";
            const showLeg = legal && legal !== nom;
            const dept = r[9] ?? "";
            const addr = r[3] ?? "";
            const siret = r[4] ?? "";
            const siren = siret.slice(0, 9);
            const ape = r[10] ?? "";
            const dateStr = r[7]
              ? new Date(r[7]).toLocaleDateString("fr-FR", {
                  year: "numeric",
                  month: "short",
                })
              : "";
            const tr = document.createElement("tr");
            tr.innerHTML = `
              <td>
                <span class="etab-nom">${nom}</span>
                ${
                  r[6]
                    ? `<span class="etab-badge etab-badge-siege">Siège</span>`
                    : ""
                }
                ${showLeg ? `<span class="etab-legal">${legal}</span>` : ""}
              </td>
              <td>${
                dept ? `<span class="etab-dept-tag">${dept}</span>` : ""
              }${addr}</td>
              <td>${
                ape
                  ? `<a href="/sirene?ape=${encodeURIComponent(
                      ape,
                    )}" class="etab-source-link">${ape}</a>`
                  : ""
              }</td>
              <td style="white-space:nowrap">
                <code class="etab-siret-copy" data-siret="${siren}" title="Cliquer pour copier"
                      onclick="navigator.clipboard.writeText(this.dataset.siret).then(()=>{this.classList.add('copied');setTimeout(()=>this.classList.remove('copied'),1200)})"
                  >${siren}</code><br/>
                <a href="https://annuaire-entreprises.data.gouv.fr/entreprise/${siren}" target="_blank" class="etab-source-link etab-source-link-datagouv">data.gouv</a>
                <a href="https://www.pappers.fr/entreprise/${siren}" target="_blank" class="etab-source-link etab-source-link-pappers">pappers</a>
              </td>
              <td style="white-space:nowrap">
                <code class="etab-siret-copy" data-siret="${siret}" title="Cliquer pour copier"
                      onclick="navigator.clipboard.writeText(this.dataset.siret).then(()=>{this.classList.add('copied');setTimeout(()=>this.classList.remove('copied'),1200)})"
                  >${siret}</code><br/>
                <a href="https://annuaire-entreprises.data.gouv.fr/etablissement/${siret}" target="_blank" class="etab-source-link etab-source-link-datagouv">data.gouv</a>
                <a href="https://data.inpi.fr/entreprises/${siren}?q=${siret}" target="_blank" class="etab-source-link etab-source-link-inpi">inpi</a>
              </td>
              <td><span class="etab-effectifs-badge">${effectifsLabel(
                r[5],
              )}</span></td>
              <td style="white-space:nowrap">${dateStr}</td>`;
            tbody.appendChild(tr);
          }
        } finally {
          await conn.close().catch(() => {});
        }
      } catch (err) {
        document.getElementById("etab-loading").style.display = "none";
        btn.disabled = false;
        btn.style.opacity = "";
        btn.style.cursor = "";
        btn.textContent = "Erreur — Réessayer";
        console.error("[etab search]", err);
      }
    });

    display(btn);
  }
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
      <a class="see-also-link" href="/sirene">Nomenclature APE</a>
      <a class="see-also-link" href="/nafrev2">Référentiel NAF Rév. 2</a>
      <a class="see-also-link" href="/dataset/sirene">Dataset SIRENE</a>
    </div>
  </div>`,
);
```
