import { createClient, query } from "./src/data/db.js";

async function* scopePaths() {
  const client = createClient();
  await client.connect();
  const scopes = await query(
    client,
    `SELECT id AS scopeid FROM vigilo_scopes ORDER BY id`,
  );
  await client.end();
  for (const { scopeid } of scopes) {
    yield `/vigilo/${scopeid}`;
  }
}

export default {
  title: "World Data Analysis",
  root: "src",
  dynamicPaths: async function* () {
    yield* scopePaths();
  },
  theme: ["air", "midnight"],
  pages: [
    { name: "Accueil", path: "/" },
    {
      name: "Vigilo",
      open: false,
      pages: [
        { name: "Vue globale", path: "/vigilo" },
        { name: "Toutes les villes", path: "/vigilo/cities" },
      ],
    },
    {
      name: "NAF Rév. 2",
      open: false,
      pages: [{ name: "Explorer la nomenclature", path: "/nafrev2" }],
    },
    {
      name: "SIRENE",
      open: false,
      pages: [{ name: "Vue d'ensemble", path: "/sirene" }],
    },
  ],
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
