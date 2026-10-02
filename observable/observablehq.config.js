import Database from "duckdb";

const datasList = (process.env.DATAS_LIST ?? "")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);

async function* scopePaths() {
  const { parquetPath } = await import("./src/data/db.js");
  const parquet = parquetPath("vigilo", "scopes.parquet");
  const scopes = await new Promise((resolve, reject) => {
    const db = new Database.Database(":memory:");
    db.all(
      `SELECT id FROM read_parquet('${parquet}') ORDER BY id`,
      (err, rows) => {
        db.close();
        err ? reject(err) : resolve(rows);
      },
    );
  }).catch(() => []);
  for (const { id } of scopes) yield `/vigilo/${id}`;
}

export default {
  title: "World Data Analysis",
  root: "src",
  base: process.env.GITHUB_ACTIONS ? "/world-datas-analysis" : "/",
  define: {
    "process.env.WDA_PUBLIC_DATASET_URL": JSON.stringify(
      process.env.WDA_PUBLIC_DATASET_URL ?? "",
    ),
  },
  dynamicPaths: async function* () {
    yield* scopePaths();
  },
  theme: ["air", "midnight"],
  pages: [
    { name: "Accueil", path: "/" },
    {
      name: "Vigilo",
      datasets: ["vigilo"],
      open: false,
      pages: [
        { name: "Vue globale", path: "/vigilo" },
        { name: "Toutes les villes", path: "/vigilo/cities" },
      ],
    },
    {
      name: "NAF Rév. 2",
      datasets: ["nafrev2"],
      open: false,
      pages: [{ name: "Explorer la nomenclature", path: "/nafrev2" }],
    },
    {
      name: "SIRENE",
      datasets: ["sirene"],
      open: false,
      pages: [
        { name: "Recherche par APE", path: "/sirene" },
        {
          name: "Rechercher des établissements",
          path: "/sirene/etablissements",
        },
      ],
    },
  ].filter(
    (p) =>
      !p.datasets ||
      datasList.length === 0 ||
      p.datasets.some((d) => datasList.includes(d)),
  ),
  style: "style.css",
  head: `<link rel="stylesheet" href="https://unpkg.com/maplibre-gl/dist/maplibre-gl.css">
<script>
(function() {
  const saved = localStorage.getItem('wda-theme');
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  const isDark = saved ? saved === 'dark' : prefersDark;
  if (isDark) document.documentElement.dataset.theme = 'dark';
  else document.documentElement.dataset.theme = 'light';

  document.addEventListener('DOMContentLoaded', function() {
    const btn = document.createElement('button');
    btn.id = 'wda-theme-toggle';
    btn.title = 'Basculer le thème clair/sombre';
    function updateBtn(dark) {
      btn.innerHTML = dark
        ? '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>'
        : '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>';
    }
    updateBtn(document.documentElement.dataset.theme === 'dark');
    btn.addEventListener('click', function() {
      const dark = document.documentElement.dataset.theme !== 'dark';
      document.documentElement.dataset.theme = dark ? 'dark' : 'light';
      localStorage.setItem('wda-theme', dark ? 'dark' : 'light');
      updateBtn(dark);
    });
    document.body.appendChild(btn);
  });
})();
</script>`,
};
