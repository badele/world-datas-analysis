const ICON_DOWNLOAD = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>`;
const ICON_SHARE = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg>`;
const ICON_FULLSCREEN = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="15 3 21 3 21 9"/><polyline points="9 21 3 21 3 15"/><line x1="21" y1="3" x2="14" y2="10"/><line x1="3" y1="21" x2="10" y2="14"/></svg>`;

const LOGO_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 58 20"><circle cx="10" cy="10" r="8.5" fill="none" stroke="#aaa" stroke-width="1.5"/><ellipse cx="10" cy="10" rx="4" ry="8.5" fill="none" stroke="#aaa" stroke-width="1"/><line x1="1.5" y1="10" x2="18.5" y2="10" stroke="#aaa" stroke-width="1"/><text x="23" y="14" font-family="sans-serif" font-size="11" font-weight="700" fill="#aaa" letter-spacing="1">WDA</text></svg>`;

function loadImage(url) {
  return new Promise((resolve) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.src = url;
  });
}

async function downloadChart(block) {
  const svg = [...block.querySelectorAll("svg")].find(
    (s) => parseInt(s.getAttribute("width") || "0") > 100,
  );
  if (!svg) return;

  const svgW = svg.viewBox?.baseVal?.width || svg.clientWidth || 640;
  const svgH = svg.viewBox?.baseVal?.height || svg.clientHeight || 400;

  const titleText =
    block.querySelector(".wda-chart-title")?.textContent?.trim() || "";
  const subtitleText =
    block.querySelector(".wda-chart-subtitle")?.textContent?.trim() || "";
  const sourceEl = block.querySelector(".wda-chart-source");
  const sourceText = sourceEl?.textContent?.trim() || "";

  // Use actual rendered width of source element for the separator line
  const screenSvgW = svg.getBoundingClientRect().width || svgW;
  const domToSvg = svgW / screenSvgW;
  const sourceLineW = sourceEl
    ? sourceEl.getBoundingClientRect().width * domToSvg
    : 0;

  const scale = 2;
  const pad = 20;
  const titleH = titleText ? 26 : 0;
  const subtitleH = subtitleText ? 20 : 0;
  const gapH = titleH || subtitleH ? 10 : 0;
  const sourceH = sourceText ? 28 : 0;
  const totalW = svgW + pad * 2;
  const totalH = pad + titleH + subtitleH + gapH + svgH + sourceH + pad;

  const serializer = new XMLSerializer();
  const svgUrl = URL.createObjectURL(
    new Blob([serializer.serializeToString(svg)], { type: "image/svg+xml" }),
  );
  const logoUrl = URL.createObjectURL(
    new Blob([LOGO_SVG], { type: "image/svg+xml" }),
  );

  const [chartImg, logoImg] = await Promise.all([
    loadImage(svgUrl),
    loadImage(logoUrl),
  ]);
  URL.revokeObjectURL(svgUrl);
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

  ctx.drawImage(chartImg, pad, y, svgW, svgH);

  // WDA logo — top-right, aligned with title row
  const logoW = 58,
    logoH = 20;
  ctx.globalAlpha = 0.5;
  ctx.drawImage(logoImg, totalW - pad - logoW, pad - 4, logoW, logoH);
  ctx.globalAlpha = 1;

  y += svgH;
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
    },
    { once: false },
  );
}

export function initChartActions() {
  document.querySelectorAll(".wda-chart-block").forEach((block) => {
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
      else if (btn.dataset.action === "fullscreen")
        toggleFullscreen(block, btn);
    });

    const source = block.querySelector(".wda-chart-source");
    if (source) block.insertBefore(bar, source);
    else block.appendChild(bar);
  });
}
