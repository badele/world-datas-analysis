/**
 * Unified HTML bar chart — fills 100% of container width via CSS.
 *
 * opts:
 *   yFn(d)       — label string for each row
 *   fill         — bar color
 *   totalEtablissements — used to compute %
 *   hrefFn(d)    — optional: wrap label in <a href>
 *   onRowClick(d) — optional: click handler (takes priority over href)
 */
export function barChart(
  data,
  { yFn, fill, totalEtablissements, hrefFn, onRowClick } = {},
) {
  if (!data || !data.length) return document.createTextNode("Aucune donnée.");
  const maxVal = Math.max(...data.map((d) => d.nb_etablissements));
  const container = document.createElement("div");
  container.className = "wda-bar-chart";

  for (const d of data) {
    const pct =
      totalEtablissements > 0
        ? (d.nb_etablissements / totalEtablissements) * 100
        : 0;
    const barPct = maxVal > 0 ? (d.nb_etablissements / maxVal) * 100 : 0;
    const labelText = yFn(d);

    const row = container.appendChild(document.createElement("div"));
    row.className = "wda-bar-row";
    row.title = labelText;

    if (onRowClick) {
      row.style.cursor = "pointer";
      row.addEventListener("click", () => onRowClick(d));
    } else if (hrefFn) {
      const href = hrefFn(d);
      if (href) {
        row.style.cursor = "pointer";
        row.addEventListener("click", () => {
          window.location.href = href;
        });
      }
    }

    // Label (left column) — wrapped in <a> for accessibility/right-click
    const labelEl = row.appendChild(document.createElement("div"));
    labelEl.className = "wda-bar-label";
    if (hrefFn && !onRowClick) {
      const href = hrefFn(d);
      if (href) {
        const a = labelEl.appendChild(document.createElement("a"));
        a.href = href;
        a.textContent = labelText;
        a.addEventListener("click", (e) => e.stopPropagation());
      } else {
        labelEl.textContent = labelText;
      }
    } else {
      labelEl.textContent = labelText;
    }

    // Bar area (right column)
    const barWrap = row.appendChild(document.createElement("div"));
    barWrap.className = "wda-bar-wrap";

    const bar = barWrap.appendChild(document.createElement("div"));
    bar.className = "wda-bar";
    bar.style.width = barPct + "%";
    bar.style.background = fill;

    const val = barWrap.appendChild(document.createElement("span"));
    val.className = "wda-bar-val";
    val.textContent = `${d.nb_etablissements.toLocaleString(
      "fr-FR",
    )} (${pct.toFixed(1)} %)`;
  }
  return container;
}

// Kept for backward compat on sirene.md — delegates to barChart
export function top20Chart(
  data,
  { yFn, hrefFn, fill, totalEtablissements } = {},
) {
  return barChart(data, { yFn, fill, totalEtablissements, hrefFn });
}

// APE bar chart — navigates via hrefFn (preferred) or calls onApeClick for inline map
export function apeClickableChart(
  data,
  { fill, totalEtablissements, onApeClick, hrefFn } = {},
) {
  return barChart(data, {
    yFn: (d) => `${d.sous_classe_id} — ${d.sous_classe}`,
    fill,
    totalEtablissements,
    hrefFn: hrefFn ?? null,
    onRowClick: hrefFn
      ? null
      : (d) => onApeClick?.(d.sous_classe_id, d.sous_classe),
  });
}
