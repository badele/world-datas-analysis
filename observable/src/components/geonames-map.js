import * as maplibregl from "npm:maplibre-gl";

maplibregl.setWorkerUrl(
  "https://unpkg.com/maplibre-gl@6.12.0/dist/maplibre-gl-worker.mjs",
);

// Antimeridian problem: TopoJSON→GeoJSON conversion keeps coordinates in their
// original longitude range. Polygons that cross the 180°/-180° meridian (Russia,
// Alaska, Fiji…) may have rings where one vertex is at +175° and the next at
// -175°. On a flat Mercator projection this looks like a jump of 350°, causing
// MapLibre to draw a giant triangle that cuts across the entire globe.
//
// unwrapRing makes consecutive longitudes continuous by adding/subtracting 360°
// so that no two adjacent points differ by more than 180°. This prevents the
// diagonal rendering artifact for most polygons.
//
// NOTE: unwrapRing alone is not a complete fix — it only handles rings whose
// first vertex falls on the "right" side of the antimeridian. The definitive
// solution is the globe projection (see createGeonamesMap below), which renders
// the world as a sphere and wraps coordinates correctly without any coordinate
// manipulation.
function unwrapRing(ring) {
  if (!ring || ring.length < 2) return ring;
  const out = [[...ring[0]]];
  for (let i = 1; i < ring.length; i++) {
    const prev = out[i - 1];
    const curr = [...ring[i]];
    while (curr[0] - prev[0] > 180) curr[0] -= 360;
    while (curr[0] - prev[0] < -180) curr[0] += 360;
    out.push(curr);
  }
  return out;
}

export function fixGeometry(geometry) {
  if (!geometry) return geometry;
  if (geometry.type === "Polygon") {
    return { ...geometry, coordinates: geometry.coordinates.map(unwrapRing) };
  }
  if (geometry.type === "MultiPolygon") {
    return {
      ...geometry,
      coordinates: geometry.coordinates.map((poly) => poly.map(unwrapRing)),
    };
  }
  return geometry;
}

function bluesLog(value, logMin, logMax) {
  if (!value || value <= 0) return "#cccccc";
  const logV = Math.log10(Math.max(value, Math.pow(10, logMin)));
  const t = Math.max(0, Math.min(1, (logV - logMin) / (logMax - logMin)));
  // Blues: #f7fbff → #08306b
  const r = Math.round(247 + t * (8 - 247));
  const g = Math.round(251 + t * (48 - 251));
  const b = Math.round(255 + t * (107 - 255));
  return `rgb(${r},${g},${b})`;
}

// YlBu two-hue palette for density — transitioning from yellow to cyan to dark
// blue gives a strong perceptual range across the logarithmic scale while
// keeping the warm/cool opposition intuitive (sparse = warm light, dense = cool dark).
// Stops: #ffffd4 → #41b6c4 → #0c2c84
const YLBU_STOPS = [
  [255, 255, 212],
  [65, 182, 196],
  [12, 44, 132],
];

function ylbuLog(value, logMin, logMax) {
  if (!value || value <= 0) return "#cccccc";
  const logV = Math.log10(Math.max(value, Math.pow(10, logMin)));
  const t = Math.max(0, Math.min(1, (logV - logMin) / (logMax - logMin)));
  const pos = t * (YLBU_STOPS.length - 1);
  const i = Math.min(Math.floor(pos), YLBU_STOPS.length - 2);
  const f = pos - i;
  const [r1, g1, b1] = YLBU_STOPS[i];
  const [r2, g2, b2] = YLBU_STOPS[i + 1];
  return `rgb(${Math.round(r1 + f * (r2 - r1))},${Math.round(
    g1 + f * (g2 - g1),
  )},${Math.round(b1 + f * (b2 - b1))})`;
}

function buildLegend(labelText, tickLabels, gradient) {
  const wrap = document.createElement("div");
  wrap.style.cssText =
    "padding:8px 12px 4px;display:flex;flex-direction:column;gap:2px;";

  const label = document.createElement("div");
  label.textContent = labelText;
  label.style.cssText = "font-size:11px;color:#aaa;margin-bottom:2px;";

  const bar = document.createElement("div");
  bar.style.cssText = `height:10px;width:240px;border-radius:2px;background:linear-gradient(to right,${gradient});`;

  const ticks = document.createElement("div");
  ticks.style.cssText =
    "width:240px;display:flex;justify-content:space-between;font-size:10px;color:#aaa;margin-top:2px;";
  tickLabels.forEach((t) => {
    const s = document.createElement("span");
    s.textContent = t;
    ticks.appendChild(s);
  });

  wrap.append(label, bar, ticks);
  return wrap;
}

function injectPopupStyles() {
  if (document.getElementById("wda-geonames-popup-style")) return;
  const style = document.createElement("style");
  style.id = "wda-geonames-popup-style";
  style.textContent = `
    .wda-geonames-popup .maplibregl-popup-content {
      background: #000;
      color: #e0e0e0;
      padding: 6px 10px;
      border-radius: 4px;
      font-size: 13px;
      line-height: 1.4;
    }
    .wda-geonames-popup .maplibregl-popup-tip {
      border-top-color: #000;
      border-bottom-color: #000;
    }
  `;
  document.head.appendChild(style);
}

// metric: "population" (default) | "density" (hab/km²)
export async function createGeonamesMap(
  container,
  countries,
  { metric = "population" } = {},
) {
  const { feature } = await import(
    "https://cdn.jsdelivr.net/npm/topojson-client@3/+esm"
  );
  const world = await fetch(
    "https://cdn.jsdelivr.net/npm/world-atlas@2/countries-110m.json",
  ).then((r) => r.json());

  const popByNumeric = new Map(countries.map((d) => [d.iso_numeric, d]));
  const allFeatures = feature(world, world.objects.countries).features;

  const isDensity = metric === "density";

  // Compute the value used for coloring depending on metric
  const getValue = (info) => {
    if (isDensity) {
      const pop = info.population ?? 0;
      const area = info.area_km2 ?? 0;
      return pop > 0 && area > 0 ? pop / area : 0;
    }
    return info.population ?? 0;
  };

  const values = countries.map(getValue).filter((v) => v > 0);
  const logMin = isDensity ? Math.log10(0.1) : Math.log10(1e4);
  const logMax = Math.log10(Math.max(...values));

  const geojson = {
    type: "FeatureCollection",
    features: allFeatures.map((f) => {
      const info = popByNumeric.get(+f.id) ?? {};
      const value = getValue(info);
      const density =
        info.population > 0 && info.area_km2 > 0
          ? info.population / info.area_km2
          : 0;
      return {
        ...f,
        geometry: fixGeometry(f.geometry),
        properties: {
          country: info.country ?? "",
          population: info.population ?? 0,
          area_km2: info.area_km2 ?? 0,
          density,
          fill: ylbuLog(value, logMin, logMax),
        },
      };
    }),
  };

  // Insert legend just before the map container
  const legendLabel = isDensity ? "Densité (hab/km²)" : "Population";
  const legendTicks = isDensity
    ? ["0,1", "1", "10", "100", "1 k", "10 k"]
    : ["10 k", "100 k", "1 M", "10 M", "100 M", "1 Md"];
  const legendColors = ["#ffffd4", "#41b6c4", "#0c2c84"];
  const legendGradient = legendColors.join(",");
  container.parentElement?.insertBefore(
    buildLegend(legendLabel, legendTicks, legendGradient),
    container,
  );

  // Store legend config so the PNG export can redraw it on canvas
  container._wdaLegend = {
    label: legendLabel,
    ticks: legendTicks,
    colors: legendColors,
  };

  // Globe projection (MapLibre GL v3+) is the definitive fix for antimeridian
  // artifacts: it renders the world as a sphere so polygons that cross ±180°
  // are drawn correctly without any coordinate manipulation.
  const map = new maplibregl.Map({
    container,
    style: {
      version: 8,
      sources: {},
      layers: [
        {
          id: "background",
          type: "background",
          paint: { "background-color": "#d4e9f7" },
        },
      ],
      projection: { type: "globe" },
    },
    center: [10, 20],
    zoom: 1.2,
    minZoom: 0.5,
    maxZoom: 10,
    preserveDrawingBuffer: true,
    attributionControl: false,
  });

  container._wdaMap = map;

  await new Promise((resolve) => map.on("load", resolve));

  map.addSource("countries", { type: "geojson", data: geojson });

  map.addLayer({
    id: "countries-fill",
    type: "fill",
    source: "countries",
    paint: {
      "fill-color": ["get", "fill"],
      "fill-opacity": 0.9,
    },
  });

  map.addLayer({
    id: "countries-border",
    type: "line",
    source: "countries",
    paint: {
      "line-color": "#ffffff",
      "line-width": 0.5,
      "line-opacity": 0.8,
    },
  });

  const popup = new maplibregl.Popup({
    closeButton: false,
    closeOnClick: false,
    maxWidth: "220px",
    className: "wda-geonames-popup",
  });

  injectPopupStyles();

  map.on("mousemove", "countries-fill", (e) => {
    map.getCanvas().style.cursor = "pointer";
    const p = e.features[0].properties;
    if (p.country) {
      let html = `<strong>${p.country}</strong><br>`;
      if (isDensity) {
        html +=
          p.density > 0
            ? `${Number(p.density).toLocaleString("fr-FR", {
                maximumFractionDigits: 1,
              })} hab/km²`
            : "—";
      } else {
        html +=
          p.population > 0
            ? `${Number(p.population).toLocaleString("fr-FR")} hab.`
            : "—";
      }
      popup.setLngLat(e.lngLat).setHTML(html).addTo(map);
    }
  });

  map.on("mouseleave", "countries-fill", () => {
    map.getCanvas().style.cursor = "";
    popup.remove();
  });

  return map;
}
