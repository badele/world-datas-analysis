const ICON_DOWNLOAD = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>`;
const ICON_SHARE = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg>`;
const ICON_FULLSCREEN = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="15 3 21 3 21 9"/><polyline points="9 21 3 21 3 15"/><line x1="21" y1="3" x2="14" y2="10"/><line x1="3" y1="21" x2="10" y2="14"/></svg>`;

const LOGO_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 58 20"><circle cx="10" cy="10" r="8.5" fill="none" stroke="#aaa" stroke-width="1.5"/><ellipse cx="10" cy="10" rx="4" ry="8.5" fill="none" stroke="#aaa" stroke-width="1"/><line x1="1.5" y1="10" x2="18.5" y2="10" stroke="#aaa" stroke-width="1"/><text x="23" y="14" font-family="sans-serif" font-size="11" font-weight="700" fill="#aaa" letter-spacing="1">WDA</text></svg>`;

function extractSwatches(block) {
  const container = block.querySelector('[class*="-swatches"]');
  if (!container) return [];
  const swatches = [];
  for (const item of container.querySelectorAll('[class*="-swatch"]')) {
    const svg = item.querySelector("svg[fill]");
    if (!svg) continue;
    const color = svg.getAttribute("fill");
    const clone = item.cloneNode(true);
    clone.querySelectorAll("svg, style").forEach((el) => el.remove());
    const label = clone.textContent.trim();
    if (color && label) swatches.push({ color, label });
  }
  return swatches;
}

function layoutSwatches(swatches, availableW) {
  if (!swatches.length) return { height: 0, rows: [] };
  const tmp = document.createElement("canvas").getContext("2d");
  tmp.font = "11px sans-serif";
  const swatchSize = 12,
    gap = 4,
    itemPad = 16;
  const rows = [[]];
  let cx = 0;
  for (const s of swatches) {
    const tw = tmp.measureText(s.label).width;
    const iw = swatchSize + gap + tw + itemPad;
    if (rows[rows.length - 1].length > 0 && cx + iw > availableW) {
      rows.push([]);
      cx = 0;
    }
    rows[rows.length - 1].push({ ...s, iw });
    cx += iw;
  }
  return { height: rows.length * 20 + 8, rows };
}

function loadImage(url) {
  return new Promise((resolve) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.src = url;
  });
}

async function composeAndDownload(
  contentW,
  contentH,
  drawContent,
  block,
  swatches = [],
) {
  const titleText =
    block.querySelector(".wda-chart-title")?.textContent?.trim() || "";
  const subtitleText =
    block.querySelector(".wda-chart-subtitle")?.textContent?.trim() || "";
  const sourceEl = block.querySelector(".wda-chart-source");
  const sourceText = sourceEl?.textContent?.trim() || "";
  const sourceLineW = sourceEl ? sourceEl.getBoundingClientRect().width : 0;

  const scale = 2;
  const pad = 20;
  const titleH = titleText ? 26 : 0;
  const subtitleH = subtitleText ? 20 : 0;
  const gapH = titleH || subtitleH ? 10 : 0;
  const sourceH = sourceText ? 28 : 0;
  const totalW = contentW + pad * 2;
  const swatchLayout = layoutSwatches(swatches, contentW);
  const swatchH = swatchLayout.height;
  const totalH =
    pad + titleH + subtitleH + gapH + swatchH + contentH + sourceH + pad;

  const logoUrl = URL.createObjectURL(
    new Blob([LOGO_SVG], { type: "image/svg+xml" }),
  );
  const logoImg = await loadImage(logoUrl);
  URL.revokeObjectURL(logoUrl);

  const canvas = document.createElement("canvas");
  canvas.width = totalW * scale;
  canvas.height = totalH * scale;
  const ctx = canvas.getContext("2d");
  ctx.scale(scale, scale);
  ctx.fillStyle = "#1a1a2e";
  ctx.fillRect(0, 0, totalW, totalH);

  let y = pad;
  if (titleText) {
    ctx.font = "bold 16px sans-serif";
    ctx.fillStyle = "#e0e0e0";
    ctx.fillText(titleText, pad, y + 16);
    y += titleH;
  }
  if (subtitleText) {
    ctx.font = "13px sans-serif";
    ctx.fillStyle = "#aaaaaa";
    ctx.fillText(subtitleText, pad, y + 14);
    y += subtitleH;
  }
  y += gapH;

  if (swatchLayout.rows.length > 0 && swatchH > 0) {
    let sy = y + 2;
    for (const row of swatchLayout.rows) {
      let sx = pad;
      for (const { color, label, iw } of row) {
        ctx.fillStyle = color;
        ctx.fillRect(sx, sy, 12, 12);
        ctx.font = "11px sans-serif";
        ctx.fillStyle = "#e0e0e0";
        ctx.fillText(label, sx + 16, sy + 10);
        sx += iw;
      }
      sy += 20;
    }
    y += swatchH;
  }

  drawContent(ctx, pad, y, contentW, contentH);

  const logoW = 58,
    logoH = 20;
  ctx.globalAlpha = 0.5;
  ctx.drawImage(logoImg, totalW - pad - logoW, pad - 4, logoW, logoH);
  ctx.globalAlpha = 1;

  y += contentH;
  if (sourceText) {
    ctx.strokeStyle = "#3d3d6b";
    ctx.lineWidth = 0.5;
    ctx.beginPath();
    ctx.moveTo(pad, y + 6);
    ctx.lineTo(pad + sourceLineW, y + 6);
    ctx.stroke();
    ctx.font = "11px sans-serif";
    ctx.fillStyle = "#3d3d6b";
    ctx.fillText(sourceText, pad, y + 18);
  }

  const filename = titleText.replace(/\s+/g, "-").toLowerCase() || "chart";
  canvas.toBlob((pngBlob) => {
    const a = document.createElement("a");
    a.href = URL.createObjectURL(pngBlob);
    a.download = `wda-${filename}.png`;
    a.click();
  });
}

async function downloadChart(block) {
  const swatches = extractSwatches(block);

  // SVG chart — pick the largest by area to avoid selecting small legend ramps
  const allSvgs = [...block.querySelectorAll("svg")].filter(
    (s) => parseInt(s.getAttribute("width") || "0") > 100,
  );
  if (allSvgs.length) {
    const svgArea = (s) =>
      (s.viewBox?.baseVal?.width || s.clientWidth || 0) *
      (s.viewBox?.baseVal?.height || s.clientHeight || 0);
    allSvgs.sort((a, b) => svgArea(b) - svgArea(a));
    const svg = allSvgs[0];
    const svgW = svg.viewBox?.baseVal?.width || svg.clientWidth || 640;
    const svgH = svg.viewBox?.baseVal?.height || svg.clientHeight || 400;

    const serializer = new XMLSerializer();
    const svgUrl = URL.createObjectURL(
      new Blob([serializer.serializeToString(svg)], { type: "image/svg+xml" }),
    );
    const chartImg = await loadImage(svgUrl);
    URL.revokeObjectURL(svgUrl);

    // Capture color ramp legend (e.g. choropleth scale) if present
    const rampSvg = block.querySelector('svg[class*="-ramp"]');
    let rampImg = null,
      rampW = 0,
      rampH = 0;
    if (rampSvg) {
      rampW = rampSvg.viewBox?.baseVal?.width || rampSvg.clientWidth || 240;
      rampH = rampSvg.viewBox?.baseVal?.height || rampSvg.clientHeight || 50;
      // Replace currentColor with light color so text/ticks render on dark background
      const rampSvgStr = serializer
        .serializeToString(rampSvg)
        .replaceAll("currentColor", "#e0e0e0");
      const rampUrl = URL.createObjectURL(
        new Blob([rampSvgStr], { type: "image/svg+xml" }),
      );
      rampImg = await loadImage(rampUrl);
      URL.revokeObjectURL(rampUrl);
    }

    const extraH = rampImg ? rampH + 8 : 0;
    await composeAndDownload(
      svgW,
      svgH + extraH,
      (ctx, x, y, w, h) => {
        if (rampImg) {
          ctx.drawImage(rampImg, x, y, rampW, rampH);
          ctx.drawImage(chartImg, x, y + rampH + 8, w, h - rampH - 8);
        } else {
          ctx.drawImage(chartImg, x, y, w, h);
        }
      },
      block,
      swatches,
    );
    return;
  }

  // MapLibre GL canvas — trigger repaint, wait for frame, then read via toDataURL
  const mapEl = block.querySelector(".vigilo-map");
  const mapCanvas = block.querySelector(".maplibregl-canvas");
  if (mapCanvas) {
    const mapInstance = mapEl?._wdaMap;
    if (mapInstance) {
      await new Promise((resolve) => {
        mapInstance.once("render", resolve);
        mapInstance.triggerRepaint();
        // fallback if render event never fires (e.g. headless)
        setTimeout(resolve, 300);
      });
    }
    const rect = mapCanvas.getBoundingClientRect();
    const dataUrl = mapCanvas.toDataURL();
    const mapImg = await loadImage(dataUrl);

    const legendData = mapEl?._wdaLegend;
    const legendH = legendData ? 38 : 0;

    await composeAndDownload(
      rect.width,
      rect.height + legendH,
      (ctx, x, y, cw, ch) => {
        if (legendData) {
          drawMapLegend(ctx, x, y, cw, legendData);
          ctx.drawImage(mapImg, x, y + legendH, cw, ch - legendH);
        } else {
          ctx.drawImage(mapImg, x, y, cw, ch);
        }
      },
      block,
      swatches,
    );
  }
}

function drawMapLegend(ctx, x, y, w, { label, ticks, colors }) {
  const barW = Math.min(240, w);

  ctx.font = "11px sans-serif";
  ctx.fillStyle = "#aaaaaa";
  ctx.fillText(label, x, y + 11);

  const grad = ctx.createLinearGradient(x, 0, x + barW, 0);
  colors.forEach((c, i) => grad.addColorStop(i / (colors.length - 1), c));
  ctx.fillStyle = grad;
  ctx.beginPath();
  ctx.roundRect(x, y + 14, barW, 10, 2);
  ctx.fill();

  ctx.font = "10px sans-serif";
  ctx.fillStyle = "#aaaaaa";
  ticks.forEach((t, i) => {
    const tx = x + (i / (ticks.length - 1)) * barW;
    ctx.fillText(t, tx, y + 36);
  });
}

function shareChart(block) {
  const title =
    block.querySelector(".wda-chart-title")?.textContent?.trim() || "Chart";
  const url =
    window.location.origin + window.location.pathname + window.location.search;
  if (navigator.share) {
    navigator.share({ title, url }).catch(() => {});
  } else {
    navigator.clipboard.writeText(url).then(() => {
      const btn = block.querySelector('[data-action="share"]');
      if (btn) {
        const prev = btn.innerHTML;
        btn.innerHTML =
          '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>';
        setTimeout(() => (btn.innerHTML = prev), 1500);
      }
    });
  }
}

function toggleFullscreen(block, btn) {
  if (document.fullscreenElement) {
    document.exitFullscreen();
  } else {
    block.requestFullscreen();
  }
  document.addEventListener(
    "fullscreenchange",
    () => {
      btn.title = document.fullscreenElement
        ? "Quitter le plein écran"
        : "Plein écran";
      // MapLibre uses ResizeObserver but needs a nudge after fullscreen transition
      const mapInstance = block.querySelector(".vigilo-map")?._wdaMap;
      if (mapInstance) setTimeout(() => mapInstance.resize(), 50);
    },
    { once: false },
  );
}

function processBlock(block) {
  if (block.querySelector(".wda-chart-actions")) return;

  const bar = document.createElement("div");
  bar.className = "wda-chart-actions";
  bar.innerHTML = `
      <button class="wda-action-btn" data-action="download" title="Télécharger l'image">${ICON_DOWNLOAD}</button>
      <button class="wda-action-btn" data-action="share" title="Partager">${ICON_SHARE}</button>
      <button class="wda-action-btn" data-action="fullscreen" title="Plein écran">${ICON_FULLSCREEN}</button>
    `;

  bar.addEventListener("click", (e) => {
    const btn = e.target.closest("[data-action]");
    if (!btn) return;
    if (btn.dataset.action === "download") downloadChart(block);
    else if (btn.dataset.action === "share") shareChart(block);
    else if (btn.dataset.action === "fullscreen") toggleFullscreen(block, btn);
  });

  const source = block.querySelector(".wda-chart-source");
  if (source) block.insertBefore(bar, source);
  else block.appendChild(bar);
}

export function initBlockActions(block) {
  processBlock(block);
}

export function initChartActions() {
  document.querySelectorAll(".wda-chart-block").forEach(processBlock);
}
