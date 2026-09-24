function ensureEl() {
  let el = document.getElementById("wda-popup");
  if (el) return el;
  el = document.createElement("div");
  el.id = "wda-popup";
  document.body.appendChild(el);
  document.addEventListener("click", (e) => {
    if (el.style.display !== "none" && !el.contains(e.target)) {
      el.style.display = "none";
    }
  });
  return el;
}

function esc(s) {
  return String(s ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/**
 * Show the generic WDA popup.
 *
 * @param {{ clientX: number, clientY: number, stopPropagation?: () => void }} coords
 *   A MouseEvent or a plain object with viewport pixel coordinates.
 * @param {{ title: string, rows: Array<{ label: string, id?: any, value?: string, copyValue?: string|false }> }} opts
 *   title   — popup header text
 *   rows    — each row: label (left), id (bold prefix), value (text), copyValue (override copy string, false = no button)
 */
export function showPopup(eventOrCoords, { title, rows, href = null }) {
  if (typeof eventOrCoords.stopPropagation === "function")
    eventOrCoords.stopPropagation();
  const clientX = eventOrCoords.clientX ?? 0;
  const clientY = eventOrCoords.clientY ?? 0;
  const el = ensureEl();

  el.innerHTML = `
    <div class="wda-popup-header">
      <span>${esc(title)}</span>
      <button class="wda-popup-close" onclick="document.getElementById('wda-popup').style.display='none'">✕</button>
    </div>
    <div class="wda-popup-body">
      ${rows
        .map(({ label, id, value, copyValue }) => {
          const cv =
            copyValue === false
              ? null
              : copyValue ??
                (id != null
                  ? String(id) + (value ? " — " + value : "")
                  : String(value ?? ""));
          return `
            <div class="wda-popup-row">
              <span class="wda-popup-label">${esc(label)}</span>
              <span class="wda-popup-value">${
                id != null ? `<strong>${esc(String(id))}</strong> ` : ""
              }${esc(value ?? "")}</span>
              ${
                cv != null
                  ? `<button class="wda-popup-copy" data-copy="${esc(
                      cv,
                    )}">Copier</button>`
                  : `<span></span>`
              }
            </div>`;
        })
        .join("")}
    </div>
    ${
      href
        ? `<div class="wda-popup-footer"><a href="${esc(
            href,
          )}" class="wda-popup-link">Voir la fiche →</a></div>`
        : ""
    }`;

  el.querySelectorAll(".wda-popup-copy").forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.stopPropagation();
      navigator.clipboard.writeText(btn.dataset.copy);
      btn.textContent = "✓";
      setTimeout(() => (btn.textContent = "Copier"), 1500);
    });
  });

  // Affiche d'abord pour mesurer la taille réelle
  el.style.visibility = "hidden";
  el.style.display = "block";
  const W = el.offsetWidth;
  const H = el.offsetHeight;
  el.style.visibility = "";

  let left = clientX;
  let top = clientY + 8;
  if (left + W > window.innerWidth - 12) left = window.innerWidth - W - 12;
  if (left < 8) left = 8;
  if (top + H > window.innerHeight - 12) top = clientY - H - 8;
  el.style.left = left + "px";
  el.style.top = top + "px";
}

export function hidePopup() {
  const el = document.getElementById("wda-popup");
  if (el) el.style.display = "none";
}
