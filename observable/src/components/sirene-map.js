import * as maplibregl from "npm:maplibre-gl";
import { createMultiSelect } from "./wda-multiselect.js";
import { showPopup } from "./popup.js";

maplibregl.setWorkerUrl(
  "https://unpkg.com/maplibre-gl@6.12.0/dist/maplibre-gl-worker.mjs",
);

const MAP_STYLE = "https://tiles.openfreemap.org/styles/positron";

// Tranches INSEE officielles — valeur = effectifs_min stocké en DB
const EFFECTIFS_TRANCHES = [
  { label: "Non déclarés", min: 0, max: 0 },
  { label: "1 – 2", min: 1, max: 2 },
  { label: "3 – 5", min: 3, max: 5 },
  { label: "6 – 9", min: 6, max: 9 },
  { label: "10 – 19", min: 10, max: 19 },
  { label: "20 – 49", min: 20, max: 49 },
  { label: "50 – 99", min: 50, max: 99 },
  { label: "100 – 199", min: 100, max: 199 },
  { label: "200 – 249", min: 200, max: 249 },
  { label: "250 – 499", min: 250, max: 499 },
  { label: "500 – 999", min: 500, max: 999 },
  { label: "1 000 – 1 999", min: 1000, max: 1999 },
  { label: "2 000 – 4 999", min: 2000, max: 4999 },
  { label: "5 000 – 9 999", min: 5000, max: 9999 },
  { label: "10 000 +", min: 10000, max: Infinity },
];

// Rayon de base (zoom 14) par tranche — progression logarithmique
const TRANCHE_RADIUS = [5, 6, 7, 8, 9, 11, 13, 16, 19, 20, 23, 26, 30, 35, 40];

function trancheIndexOf(eff) {
  for (let i = EFFECTIFS_TRANCHES.length - 1; i >= 0; i--) {
    if (eff >= EFFECTIFS_TRANCHES[i].min) return i;
  }
  return 0;
}

// etab row = [lat, lon, name, address, siret, effectifs_min, is_siege, date_creation, legal_name, dept, ape]
function buildGeoJSON(etabs, activeSet) {
  return {
    type: "FeatureCollection",
    features: etabs
      .filter(([, , , , , eff]) => activeSet.has(trancheIndexOf(eff)))
      .map(
        ([
          lat,
          lon,
          name,
          address,
          siret,
          effectifs_min,
          is_siege,
          date_creation,
          legal_name,
          dept,
          ape,
        ]) => ({
          type: "Feature",
          geometry: { type: "Point", coordinates: [lon, lat] },
          properties: {
            name,
            address,
            siret,
            effectifs_min,
            is_siege,
            date_creation,
            legal_name,
            dept,
            ape,
            tranche_idx: trancheIndexOf(effectifs_min),
          },
        }),
      ),
  };
}

// Expression MapLibre step pour le rayon selon tranche_idx
function radiusStepExpr(zoomFactor) {
  const expr = ["step", ["get", "tranche_idx"], TRANCHE_RADIUS[0] * zoomFactor];
  for (let i = 1; i < EFFECTIFS_TRANCHES.length; i++) {
    expr.push(i, TRANCHE_RADIUS[i] * zoomFactor);
  }
  return expr;
}

export function effectifsLabel(effectifs_min) {
  const idx = trancheIndexOf(Number(effectifs_min ?? 0));
  const t = EFFECTIFS_TRANCHES[idx];
  if (!t || t.min === 0) return "Non déclarés";
  return t.max === Infinity
    ? `${t.min.toLocaleString("fr-FR")} salariés et plus`
    : `${t.label} salariés`;
}

// Retourne l'ensemble des indices actifs (tous si aucun sélectionné = "All")
function activeSetFrom(selectedKeys) {
  if (selectedKeys.length === 0)
    return new Set(EFFECTIFS_TRANCHES.map((_, i) => i));
  return new Set(selectedKeys);
}

export function createSireneMap(
  container,
  apeId,
  etabs = [],
  { onEtabSelect, title } = {},
) {
  let currentEtabs = etabs;

  // ── Controls ──────────────────────────────────────────────────────────
  const controlsEl = document.createElement("div");
  controlsEl.className = "sirene-map-controls";

  const titleEl = document.createElement("div");
  titleEl.className = "sirene-map-title";
  titleEl.textContent = title ?? (apeId ? `Code APE : ${apeId}` : "");
  controlsEl.appendChild(titleEl);

  const multiselect = createMultiSelect(
    EFFECTIFS_TRANCHES.map((t, i) => ({ idx: i, label: t.label })),
    {
      label: "Effectifs : ",
      format: (d) => d.label,
      keyOf: (d) => d.idx,
      allLabel: "Tous",
    },
  );
  controlsEl.appendChild(multiselect);
  container.appendChild(controlsEl);

  // ── Map ───────────────────────────────────────────────────────────────
  const mapEl = document.createElement("div");
  mapEl.style.cssText =
    "width:100%;height:60vh;border-radius:6px;overflow:hidden;margin-top:0.75rem;position:relative;";
  container.appendChild(mapEl);

  const map = new maplibregl.Map({
    container: mapEl,
    style: MAP_STYLE,
    center: [2.35, 46.5],
    zoom: 5,
    attributionControl: { compact: true },
  });

  map.on("load", () => {
    const initialGeoJSON = buildGeoJSON(currentEtabs, activeSetFrom([]));
    map.addSource("sirene-src", {
      type: "geojson",
      data: initialGeoJSON,
    });

    map.addLayer({
      id: "sirene-heat",
      type: "heatmap",
      source: "sirene-src",
      maxzoom: 13,
      paint: {
        "heatmap-weight": [
          "step",
          ["get", "tranche_idx"],
          0.1, // 0  : non déclarés
          1,
          0.2, // 1  : 1–2
          2,
          0.3, // 2  : 3–5
          3,
          0.5, // 3  : 6–9
          4,
          0.8, // 4  : 10–19
          5,
          1.5, // 5  : 20–49
          6,
          3, // 6  : 50–99
          7,
          6, // 7  : 100–199
          8,
          10, // 8  : 200–249
          9,
          15, // 9  : 250–499
          10,
          25, // 10 : 500–999
          11,
          40, // 11 : 1 000–1 999
          12,
          65, // 12 : 2 000–4 999
          13,
          90, // 13 : 5 000–9 999
          14,
          120, // 14 : 10 000+
        ],
        "heatmap-intensity": [
          "interpolate",
          ["linear"],
          ["zoom"],
          4,
          0.3,
          7,
          1,
          13,
          3,
        ],
        "heatmap-color": [
          "interpolate",
          ["linear"],
          ["heatmap-density"],
          0,
          "rgba(33,102,172,0)",
          0.2,
          "rgb(103,169,207)",
          0.4,
          "rgb(209,229,240)",
          0.6,
          "rgb(253,219,199)",
          0.8,
          "rgb(239,138,98)",
          1,
          "rgb(178,24,43)",
        ],
        "heatmap-radius": [
          "interpolate",
          ["linear"],
          ["zoom"],
          4,
          3,
          7,
          8,
          13,
          25,
        ],
        "heatmap-opacity": [
          "interpolate",
          ["linear"],
          ["zoom"],
          12,
          0.8,
          13,
          0,
        ],
      },
    });

    map.addLayer({
      id: "sirene-points",
      type: "circle",
      source: "sirene-src",
      minzoom: 12,
      paint: {
        "circle-radius": [
          "interpolate",
          ["linear"],
          ["zoom"],
          12,
          radiusStepExpr(0.5),
          16,
          radiusStepExpr(1),
        ],
        "circle-color": "#e53935",
        "circle-opacity": 0.85,
        "circle-stroke-width": 1.5,
        "circle-stroke-color": "#fff",
      },
    });

    // ── Hover tooltip ─────────────────────────────────────────────────
    const hoverPopup = new maplibregl.Popup({
      closeButton: false,
      maxWidth: "280px",
      className: "vigilo-popup",
    });

    map.on("mouseenter", "sirene-points", (e) => {
      map.getCanvas().style.cursor = "pointer";
      const p = e.features[0].properties;
      const tranche = EFFECTIFS_TRANCHES[p.tranche_idx];
      const effLabel = tranche
        ? tranche.min === 0
          ? "Non déclarés"
          : `${tranche.label} salarié(s)`
        : "";
      hoverPopup
        .setLngLat(e.lngLat)
        .setHTML(
          `<strong>${p.name}</strong>` +
            (p.address ? `<br><em>${p.address}</em>` : "") +
            (effLabel ? `<br><small>${effLabel}</small>` : "") +
            `<br><small style="opacity:0.6;font-style:italic">Cliquer pour voir le détail sous la carte</small>`,
        )
        .addTo(map);
    });
    map.on("mouseleave", "sirene-points", () => {
      map.getCanvas().style.cursor = "";
      hoverPopup.remove();
    });

    // ── Click → popup détail établissement ───────────────────────────
    map.on("click", "sirene-points", (e) => {
      e.originalEvent.stopPropagation();
      const p = e.features[0].properties;
      const siren = p.siret ? String(p.siret).slice(0, 9) : null;
      const dateCreation = p.date_creation
        ? new Date(p.date_creation).toLocaleDateString("fr-FR", {
            year: "numeric",
            month: "long",
            day: "numeric",
          })
        : null;
      const rows = [
        p.legal_name && p.legal_name !== p.name
          ? { label: "Raison sociale", value: p.legal_name, copyValue: false }
          : null,
        siren
          ? {
              label: "SIREN",
              value: siren,
              copyValue: siren,
              links: [
                {
                  label: "data.gouv",
                  href: `https://annuaire-entreprises.data.gouv.fr/entreprise/${siren}`,
                },
                {
                  label: "pappers",
                  href: `https://www.pappers.fr/entreprise/${siren}`,
                },
              ],
            }
          : null,
        p.siret
          ? {
              label: "SIRET",
              value: p.siret,
              copyValue: p.siret,
              links: [
                {
                  label: "data.gouv",
                  href: `https://annuaire-entreprises.data.gouv.fr/etablissement/${p.siret}`,
                },
                {
                  label: "inpi",
                  href: `https://data.inpi.fr/entreprises/${siren}?q=${p.siret}`,
                },
              ],
            }
          : null,
        {
          label: "Code APE",
          value: p.ape,
          copyValue: false,
          links: p.ape
            ? [
                {
                  label: "Rechercher",
                  href: `/sirene?ape=${encodeURIComponent(p.ape)}`,
                },
              ]
            : [],
        },
        {
          label: "Effectifs",
          value: effectifsLabel(p.effectifs_min),
          copyValue: false,
        },
        p.address
          ? { label: "Adresse", value: p.address, copyValue: false }
          : null,
        p.dept
          ? { label: "Département", value: p.dept, copyValue: false }
          : null,
        dateCreation
          ? { label: "Création", value: dateCreation, copyValue: false }
          : null,
        p.is_siege
          ? { label: "Siège social", value: "Oui", copyValue: false }
          : null,
      ].filter(Boolean);
      showPopup(e.originalEvent, {
        title: p.name,
        rows,
        href: p.siret ? `/sirene/etablissement/${p.siret}` : null,
      });
      if (onEtabSelect) onEtabSelect(p);
    });

    updateHeatmap(initialGeoJSON.features.length);

    // ── Multiselect filter ────────────────────────────────────────────
    multiselect.addEventListener("input", () => {
      const geojson = buildGeoJSON(
        currentEtabs,
        activeSetFrom(multiselect.value),
      );
      if (!map.getSource("sirene-src")) return;
      map.getSource("sirene-src").setData(geojson);
      updateHeatmap(geojson.features.length);
    });
  });

  function updateHeatmap(count) {
    // Plus il y a peu de points, plus on booste intensité et rayon
    const boost =
      count === 0
        ? 1
        : count < 50
          ? 12
          : count < 200
            ? 8
            : count < 500
              ? 5
              : count < 2000
                ? 2.5
                : count < 5000
                  ? 1.5
                  : 1;
    map.setPaintProperty("sirene-heat", "heatmap-intensity", [
      "interpolate",
      ["linear"],
      ["zoom"],
      4,
      0.3 * boost,
      7,
      1 * boost,
      13,
      3 * boost,
    ]);
    map.setPaintProperty("sirene-heat", "heatmap-radius", [
      "interpolate",
      ["linear"],
      ["zoom"],
      4,
      3 * boost,
      7,
      8 * boost,
      13,
      25,
    ]);
  }

  function update(newEtabs, newTitle) {
    currentEtabs = newEtabs;
    if (newTitle !== undefined) titleEl.textContent = newTitle;
    map.resize(); // recalculate canvas size in case container was hidden (display:none → visible)
    if (!map.getSource("sirene-src")) return; // will use currentEtabs when map loads
    const geojson = buildGeoJSON(
      currentEtabs,
      activeSetFrom(multiselect.value ?? []),
    );
    map.getSource("sirene-src").setData(geojson);
    updateHeatmap(geojson.features.length);
  }

  return { map, remove: () => map.remove(), update };
}

// cityPoints = [{lat, lon, nb, city}] — agrégé par ville, toutes APE confondues
export function createSireneAggMap(container, cityPoints = []) {
  const mapEl = document.createElement("div");
  mapEl.style.cssText =
    "width:100%;height:60vh;border-radius:6px;overflow:hidden;margin-top:0.75rem;";
  container.appendChild(mapEl);

  const geojson = {
    type: "FeatureCollection",
    features: cityPoints
      .filter(
        (p) =>
          p.lat != null && p.lon != null && isFinite(p.lat) && isFinite(p.lon),
      )
      .map((p) => ({
        type: "Feature",
        geometry: { type: "Point", coordinates: [p.lon, p.lat] },
        properties: { city: p.city, nb: p.nb },
      })),
  };

  const map = new maplibregl.Map({
    container: mapEl,
    style: MAP_STYLE,
    center: [2.35, 46.5],
    zoom: 5,
    attributionControl: { compact: true },
  });

  map.on("load", () => {
    map.addSource("agg-src", { type: "geojson", data: geojson });

    map.addLayer({
      id: "agg-heat",
      type: "heatmap",
      source: "agg-src",
      maxzoom: 10,
      paint: {
        "heatmap-weight": [
          "interpolate",
          ["linear"],
          ["get", "nb"],
          0,
          0.1,
          100,
          0.5,
          1000,
          1,
          10000,
          3,
          100000,
          6,
        ],
        "heatmap-intensity": [
          "interpolate",
          ["linear"],
          ["zoom"],
          4,
          0.5,
          9,
          2,
        ],
        "heatmap-color": [
          "interpolate",
          ["linear"],
          ["heatmap-density"],
          0,
          "rgba(33,102,172,0)",
          0.2,
          "rgb(103,169,207)",
          0.5,
          "rgb(253,219,199)",
          0.8,
          "rgb(239,138,98)",
          1,
          "rgb(178,24,43)",
        ],
        "heatmap-radius": ["interpolate", ["linear"], ["zoom"], 4, 8, 9, 25],
        "heatmap-opacity": ["interpolate", ["linear"], ["zoom"], 8, 1, 10, 0],
      },
    });

    map.addLayer({
      id: "agg-circles",
      type: "circle",
      source: "agg-src",
      minzoom: 8,
      paint: {
        "circle-radius": [
          "interpolate",
          ["linear"],
          ["zoom"],
          8,
          ["step", ["get", "nb"], 3, 100, 5, 1000, 8, 10000, 12, 100000, 18],
          14,
          ["step", ["get", "nb"], 5, 100, 8, 1000, 13, 10000, 20, 100000, 30],
        ],
        "circle-color": "#e53935",
        "circle-opacity": 0.75,
        "circle-stroke-width": 1,
        "circle-stroke-color": "#fff",
      },
    });

    const popup = new maplibregl.Popup({
      closeButton: false,
      maxWidth: "220px",
      className: "vigilo-popup",
    });
    map.on("mouseenter", "agg-circles", (e) => {
      map.getCanvas().style.cursor = "pointer";
      const p = e.features[0].properties;
      popup
        .setLngLat(e.lngLat)
        .setHTML(
          `<strong>${p.city || "Ville inconnue"}</strong><br>` +
            `${Number(p.nb).toLocaleString("fr-FR")} établissement${
              p.nb > 1 ? "s" : ""
            }`,
        )
        .addTo(map);
    });
    map.on("mouseleave", "agg-circles", () => {
      map.getCanvas().style.cursor = "";
      popup.remove();
    });
  });

  return map;
}
