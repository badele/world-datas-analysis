export function tabInput(options, initial) {
  const el = document.createElement("div");
  el.className = "wda-tabs";
  el.value = initial;
  for (const opt of options) {
    const btn = el.appendChild(document.createElement("button"));
    btn.className = "wda-tab" + (opt === initial ? " wda-tab--active" : "");
    btn.textContent = opt.label;
    btn.addEventListener("click", () => {
      el.querySelectorAll(".wda-tab").forEach((b) =>
        b.classList.remove("wda-tab--active"),
      );
      btn.classList.add("wda-tab--active");
      el.value = opt;
      el.dispatchEvent(new Event("input", { bubbles: true }));
    });
  }
  return el;
}
