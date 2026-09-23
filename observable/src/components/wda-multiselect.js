export function createMultiSelect(
  options,
  {
    label = "",
    format = (d) => String(d),
    keyOf = (d) => d,
    allLabel = "All",
  } = {},
) {
  const root = document.createElement("div");
  root.className = "wda-multiselect";

  const btn = document.createElement("button");
  btn.type = "button";
  btn.className = "wda-multiselect-btn";
  root.appendChild(btn);

  const panel = document.createElement("div");
  panel.className = "wda-multiselect-panel";
  panel.hidden = true;
  root.appendChild(panel);

  const keyMap = new Map(options.map((o) => [keyOf(o), o]));
  const selected = new Set();

  function renderBtn() {
    const n = selected.size;
    let val;
    if (n === 0) {
      val = `<span class="wda-multiselect-val wda-multiselect-val--all">${allLabel}</span>`;
    } else if (n === 1) {
      const opt = keyMap.get([...selected][0]);
      val = `<span class="wda-multiselect-val">${format(opt)}</span>`;
    } else {
      val = `<span class="wda-multiselect-val">${n} sélectionnés</span>`;
    }
    btn.innerHTML =
      `<span class="wda-multiselect-lbl">${label}</span>` +
      val +
      `<span class="wda-multiselect-arrow">${panel.hidden ? "▾" : "▴"}</span>`;
  }

  function makeRow(key, text, checked, onChange) {
    const lbl = document.createElement("label");
    lbl.className =
      "wda-multiselect-item" +
      (key === null ? " wda-multiselect-item--all" : "");
    const cb = document.createElement("input");
    cb.type = "checkbox";
    cb.className = "wda-multiselect-cb";
    cb.checked = checked;
    cb.addEventListener("change", () => onChange(cb.checked));
    const span = document.createElement("span");
    span.textContent = text;
    lbl.appendChild(cb);
    lbl.appendChild(span);
    return lbl;
  }

  function renderPanel() {
    panel.innerHTML = "";
    panel.appendChild(
      makeRow(null, allLabel, selected.size === 0, (checked) => {
        if (checked) {
          selected.clear();
          emit();
        }
      }),
    );
    const sep = document.createElement("div");
    sep.className = "wda-multiselect-sep";
    panel.appendChild(sep);
    for (const opt of options) {
      const k = keyOf(opt);
      panel.appendChild(
        makeRow(k, format(opt), selected.has(k), (checked) => {
          checked ? selected.add(k) : selected.delete(k);
          emit();
        }),
      );
    }
  }

  function emit() {
    renderBtn();
    renderPanel();
    root.dispatchEvent(new Event("input", { bubbles: true }));
  }

  btn.addEventListener("click", (e) => {
    e.stopPropagation();
    panel.hidden = !panel.hidden;
    if (!panel.hidden) renderPanel();
    renderBtn();
  });

  document.addEventListener("click", () => {
    if (!panel.hidden) {
      panel.hidden = true;
      renderBtn();
    }
  });
  panel.addEventListener("click", (e) => e.stopPropagation());

  Object.defineProperty(root, "value", { get: () => [...selected] });

  renderBtn();
  return root;
}
