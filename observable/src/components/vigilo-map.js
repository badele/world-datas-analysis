import * as maplibregl from "npm:maplibre-gl";
import { showPopup } from "./popup.js";

maplibregl.setWorkerUrl(
  "https://unpkg.com/maplibre-gl/dist/maplibre-gl-worker.mjs",
);

const MAP_STYLE = "https://tiles.openfreemap.org/styles/positron";

export function createVigiloMap(
  container,
  observations,
  { center = [2.35, 46.5], zoom = 5 } = {},
) {
  const map = new maplibregl.Map({
    container,
    style: MAP_STYLE,
    center,
    zoom,
    attributionControl: { compact: true },
  });

  map.on("load", () => {
    const geojson = {
      type: "FeatureCollection",
      features: observations
        .filter((d) => d.latitude != null && d.longitude != null)
        .map((d) => ({
          type: "Feature",
          geometry: { type: "Point", coordinates: [d.longitude, d.latitude] },
          properties: {
            category: d.category ?? "",
            color: d.color ?? "#3b82f6",
            address: d.address ?? "",
            comment: d.comment ?? "",
            city: d.geonames_city ?? "",
            ts: d.ts,
            approved: d.approved,
          },
        })),
    };

    map.addSource("observations", { type: "geojson", data: geojson });

    map.addLayer({
      id: "obs-heat",
      type: "heatmap",
      source: "observations",
      maxzoom: 13,
      paint: {
        "heatmap-weight": 1,
        "heatmap-intensity": ["interpolate", ["linear"], ["zoom"], 5, 1, 13, 3],
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
        "heatmap-radius": ["interpolate", ["linear"], ["zoom"], 5, 15, 13, 30],
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
      id: "obs-points",
      type: "circle",
      source: "observations",
      minzoom: 12,
      paint: {
        "circle-radius": ["interpolate", ["linear"], ["zoom"], 12, 5, 16, 10],
        "circle-color": ["get", "color"],
        "circle-stroke-width": 1.5,
        "circle-stroke-color": "#ffffff",
        "circle-opacity": 0.9,
      },
    });

    const popup = new maplibregl.Popup({
      closeButton: false,
      maxWidth: "300px",
      className: "vigilo-popup",
    });

    map.on("mouseenter", "obs-points", (e) => {
      map.getCanvas().style.cursor = "pointer";
      const p = e.features[0].properties;
      const date = p.ts
        ? new Date(p.ts * 1000).toLocaleDateString("fr-FR")
        : "";
      popup
        .setLngLat(e.lngLat)
        .setHTML(
          `<strong>${p.category}</strong>` +
            (p.city ? `<br><em>${p.city}</em>` : "") +
            (p.address ? `<br>${p.address}` : "") +
            (p.comment ? `<br><small>${p.comment}</small>` : "") +
            (date ? `<br><small style="color:#9ba3b5">${date}</small>` : ""),
        )
        .addTo(map);
    });

    map.on("mouseleave", "obs-points", () => {
      map.getCanvas().style.cursor = "";
      popup.remove();
    });

    map.on("click", "obs-points", (e) => {
      e.originalEvent.stopPropagation();
      const p = e.features[0].properties;
      const date = p.ts
        ? new Date(p.ts * 1000).toLocaleDateString("fr-FR")
        : null;
      const canvasRect = map.getCanvas().getBoundingClientRect();
      const rows = [
        { label: "Catégorie", value: p.category },
        p.city ? { label: "Ville", value: p.city } : null,
        p.address
          ? { label: "Adresse", value: p.address, copyValue: p.address }
          : null,
        p.comment ? { label: "Commentaire", value: p.comment } : null,
        date ? { label: "Date", value: date, copyValue: false } : null,
      ].filter(Boolean);
      showPopup(
        {
          clientX: canvasRect.left + e.point.x,
          clientY: canvasRect.top + e.point.y,
        },
        { title: p.category, rows },
      );
    });
  });

  return map;
}
