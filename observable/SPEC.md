# SERVER LESS

Le but du projet world datas analysis est

- de proposer des datasets au format parquet. utilisable sous forme de github
  release car visiblement github release, n'a pas de limite de taille
- pour une majorité des cas de relier les datasets à d'autres dataset (souvent
  geonames pour les pays ou villes). Afin d'avoir toujours la même informations
- LES PAGES DOIVENT ËTRE ACCESSIBLE DEPUIS UN GITHUB PAGES
- DONC POUR LES SOLUTIONS PROPOSE, TERNIR COMPTE DES CONTRAINTE DE :
  - GITHUB PAGES
  - CORS (CONTRAINTE N°1)
- EN MODE DEPLOYE
  - LES PAGES WEB DOIVENT ËTRE HEBERGE SUR GITHUB PAGES
  - LES FICHIERS TELECHARGEABLE SUR UNE SOLUTION PEU HONEREUSE, ET SI POSSIBLE
    NE PAS DEPENDRE DU TRAFFIC CAR C'EST UN PROJET OPENSOURCE PERSONEL
- EN MODE DEV
  - TROUVER UN EQUIVALENT D'UN GITHUB PAGES
  - PROPOSER PAR UNE VARIABLE OU TELECHARGER LES FICHIER PARQUET (FICHIER
    DISTANT OU LOCAL), UNE URI

# SPEC — World Data Analysis (Observable Framework)

Référence des conventions de développement pour les pages et composants du
projet.

---

## 1. Structure d'une page

Toute page `.md` suit ce squelette :

```
1. page-header  (breadcrumb + titre + sous-titre)
2. stat-grid    (chiffres-clés, optionnel)
3. Sections h2  (avec chart-description avant chaque graphique)
4. source-note  (citation de la source)
5. see-also     (liens vers pages liées)
```

### 1.1 Page header

```html
<div class="page-header">
  <div class="breadcrumb">
    <a href="/">Accueil</a> › <a href="/section">Section</a> › Page courante
  </div>
  <h1>Titre — Identifiant</h1>
  <p class="page-subtitle">Description courte en 1–2 phrases.</p>
</div>
```

### 1.2 Stat cards

```html
<div class="stat-grid">
  <div class="stat-card">
    <div class="stat-value">${valeur.toLocaleString("fr-FR")}</div>
    <div class="stat-label">Libellé</div>
  </div>
</div>
```

### 1.3 Description de graphique

Placer **avant** chaque bloc de visualisation :

```html
<div class="chart-description">
  Texte décrivant ce que montre le graphique et comment l'interpréter.
</div>
```

### 1.4 Source note

```html
<div class="source-note">
  Source : <a href="/dataset/xxx">Dataset X</a> — description courte.
</div>
```

### 1.5 See also

```js
display(
  html`<div class="see-also">
    <h3>Voir aussi</h3>
    <div class="see-also-links">
      <a class="see-also-link" href="/page-parente">← Retour</a>
      <a class="see-also-link" href="/page-liee">Page liée</a>
    </div>
  </div>`,
);
```

---

## 2. Design UI

### Thème

- Config : `theme: ["air", "midnight"]` dans `observablehq.config.js`
- Switcher clair/sombre géré via `localStorage('wda-theme')` et `data-theme` sur
  `<html>`
- Ne pas coder de couleurs en dur — utiliser les variables CSS Observable :
  - `var(--theme-background)` / `var(--theme-background-alt)`
  - `var(--theme-foreground)` / `var(--theme-foreground-muted)` /
    `var(--theme-foreground-faintest)`

### Palette graphiques (`components/theme.js`)

| Rôle             | Valeur                                      |
| ---------------- | ------------------------------------------- |
| Fond             | `#1a1a2e`                                   |
| Surface          | `#252540`                                   |
| Texte principal  | `#e0e0e0`                                   |
| Texte secondaire | `#aaa`                                      |
| Accent principal | `#81c784`                                   |
| Barres (chart1)  | `#2A9D8F`                                   |
| Catégories       | palette 10 couleurs dans `theme.category[]` |

Importer et utiliser :

```js
import { theme, plotStyle } from "../components/theme.js";
```

---

## 3. Composants communs

### 3.1 Popup (`components/popup.js`)

Popup flottant positionné au clic, auto-fermé au clic extérieur.

```js
import { showPopup, hidePopup } from "../components/popup.js";

showPopup(mouseEvent, {
  title: "Nom de l'entité",
  rows: [
    { label: "Champ", value: "valeur" },
    { label: "SIRET", value: p.siret, copyValue: p.siret },
    { label: "Badge", value: "texte", copyValue: false }, // pas de bouton copier
  ],
  href: "/lien/vers/fiche", // optionnel — affiche "Voir la fiche →"
});
```

**Règle** : utiliser `showPopup` pour les clics sur éléments cartographiques
Vigilo. Pour SIRENE, le clic alimente un panneau détail inline — pas de popup.

### 3.2 Carte Vigilo (`components/vigilo-map.js`)

Carte MapLibre avec heatmap + points pour les signalements Vigilo.

### 3.3 Carte SIRENE (`components/sirene-map.js`)

```js
import { createSireneMap } from "../components/sirene-map.js";

createSireneMap(containerEl, apeId, etabs, {
  onEtabSelect(props) {
    // props: { name, address, siret, effectifs_min, is_siege,
    //          date_creation, legal_name, dept }
    // Afficher les détails dans un panneau inline sous la carte
  },
});
```

Format compact `etabs` :
`[lat, lon, name, address, siret, effectifs_min, is_siege, date_creation, legal_name, dept]`

Couches :

- Heatmap visible jusqu'au zoom 13 (`maxzoom: 13`, opacity → 0 à zoom 13)
- Points circle à partir du zoom 12 (`minzoom: 12`)

### 3.4 Panneau détail inline (`.etab-detail-panel`)

Quand un clic sur la carte doit afficher des détails, les afficher **dans la
même page** sous la carte — jamais dans une page dédiée si le volume de données
implique plus de ~5 000 pages dynamiques.

```js
const detailEl = document.createElement("div");
detailEl.className = "etab-detail-panel";
detailEl.style.display = "none";
display(detailEl);
```

### 3.5 Multiselect (`components/wda-multiselect.js`)

Filtre multi-choix custom avec panel déroulant.

### 3.6 Tabs (`components/tabs.js`)

Onglets pour segmenter le contenu d'une page.

---

## 4. Data loaders

### 4.1 Accès base de données (`data/db.js`)

```js
import { createClient, query, toJSON } from "./db.js";
const client = createClient();
await client.connect();
const rows = await query(client, `SELECT ...`, [param]);
await client.end();
process.stdout.write(toJSON(rows));
```

Toujours entourer de `try/catch/finally` avec `client.end()` dans le `finally`.

### 4.2 Format compact pour données cartographiques

Quand un data loader alimente une carte avec potentiellement des milliers de
points, utiliser un **tableau compact** plutôt qu'un tableau d'objets :

```js
// ✓ compact — 726 fichiers × N points
const out = rows.map((r) => [r.lat, r.lon, r.name, r.address, ...]);

// ✗ verbeux — répète les clés pour chaque ligne
const out = rows.map((r) => ({ lat: r.lat, lon: r.lon, name: r.name, ... }));
```

Documenter l'ordre des champs dans un commentaire au-dessus du `.map()`.

---

## 5. Règles de génération de pages (`dynamicPaths`)

### Seuil de pages dynamiques

| Volume estimé | Stratégie                                                              |
| ------------- | ---------------------------------------------------------------------- |
| < 5 000 pages | Pages dynamiques OK (`dynamicPaths`)                                   |
| > 5 000 pages | **Ne pas générer** — afficher les détails en live dans la page parente |

**Exemple concret** : SIRENE compte 2 M établissements avec coordonnées. Générer
une page par SIRET (`/sirene/etablissement/{siret}`) ralentirait le build de
plusieurs heures. Solution : afficher la fiche de l'établissement dans un
panneau inline sous la carte au clic.

### Pages SIRENE actuellement générées

```
/sirene/{section}                              →  21 pages
/sirene/{section}/{division}                   →  87 pages
/sirene/{section}/{division}/{groupe}          → 269 pages
/sirene/{section}/{division}/{groupe}/{classe} → 609 pages
/sirene/{section}/…/{classe}/{ape}             → 726 pages
```

Total : ~1 712 pages. Acceptable.

### Pages SIRENE supprimées

- `/sirene/etablissement/{siret}` — **supprimé** (2 M+ pages, build infini)

---

## 6. Conventions de nommage

| Type                  | Convention                        | Exemple                                |
| --------------------- | --------------------------------- | -------------------------------------- |
| Data loader JSON      | `kebab-case.json.js`              | `sirene-stats-by-section.json.js`      |
| Data loader paramétré | `[param].json.js` dans un dossier | `sirene-etabs/[ape].json.js`           |
| Composant JS          | `kebab-case.js`                   | `sirene-map.js`                        |
| Page statique         | `kebab-case.md`                   | `vigilo.md`                            |
| Page dynamique        | `[param].md` dans un dossier      | `[scope].md`                           |
| Classes CSS           | `.kebab-case` préfixé par scope   | `.etab-detail-panel`, `.wda-popup-row` |

---

## 7. Hébergement des parquets — Cloudflare R2

GitHub releases n'a pas de support CORS → les parquets ne peuvent pas être
chargés directement depuis le navigateur. La solution retenue est **Cloudflare
R2** : stockage objet gratuit (10 GB, 10 M req/mois, 10 GB egress/mois) avec
CORS natif.

### 7.1 Créer le bucket R2

1. Créer un compte sur [cloudflare.com](https://cloudflare.com) (gratuit)
2. **Activer R2** :
   - Dashboard → menu gauche → **R2 Object Storage**
   - Première fois : entrer une carte bancaire (vérification identité, pas de
     débit sur le free tier)
3. **Créer le bucket** :
   - Bouton **Create bucket**
   - Nom : `world-datas-analysis`
   - Location : **Europe (WEUR)** — recommandé pour données françaises
   - Valider
4. **Activer l'accès public** :
   - Onglet **Settings** du bucket
   - Section **Public access** → **Allow Access**
   - Cloudflare fournit une URL publique : `https://pub-6526c18d68154746a16baf2f76a38544.r2.dev`
5. **Configurer CORS** :
   - Onglet **Settings** → section **CORS Policy**
   - Ajouter la règle suivante :
   ```json
   [
     {
       "AllowedOrigins": ["*"],
       "AllowedMethods": ["GET", "HEAD"],
       "AllowedHeaders": ["*"],
       "MaxAgeSeconds": 3600
     }
   ]
   ```
6. **Créer un API Token** (pour uploader depuis le pipeline) :
   - Dashboard → **My Profile** → **API Tokens** → **Create Token**
   - Template : **Edit Cloudflare Workers** ou custom avec permissions
     **R2:Edit** sur le bucket
   - Noter : **Account ID**, **Access Key ID**, **Secret Access Key**

### 7.2 Utilisation dans le code Observable

```js
const IS_LOCAL = ["localhost", "127.0.0.1"].includes(window.location.hostname);
const R2_BASE = "https://pub-6526c18d68154746a16baf2f76a38544.r2.dev/sirene";

function sectionParquetUrls(sectionIds) {
  return [...new Set(sectionIds)].map((s) =>
    IS_LOCAL
      ? `/dataset/sirene/raw/section_id=${s}/data_0.parquet`
      : `${R2_BASE}/raw__section_id.${s}__data_0.parquet`,
  );
}
```

- **Mode local** : parquets servis via le volume mount Docker
  (`./dataset:/app/src/dataset`) — même origine, pas de CORS
- **Mode déployé** (GitHub Pages) : parquets servis depuis R2 avec CORS natif

### 7.3 Upload vers R2 (pipeline de release)

L'upload se fait avec le CLI `rclone` ou `aws s3` (R2 est compatible S3) :

```bash
AWS_ACCESS_KEY_ID=<Access Key ID> \
AWS_SECRET_ACCESS_KEY=<Secret Access Key> \
aws s3 sync dataset/sirene/raw/ s3://world-datas-analysis/sirene/ \
  --endpoint-url https://<ACCOUNT_ID>.r2.cloudflarestorage.com
```

---

## 8. Map tiles

- Style : `https://tiles.openfreemap.org/styles/positron`
- Centre France par défaut : `[2.35, 46.5]`, zoom 5
- Worker MapLibre :
  `maplibregl.setWorkerUrl("https://unpkg.com/maplibre-gl/dist/maplibre-gl-worker.mjs")`
- CSS MapLibre chargé dans `observablehq.config.js` via `head:`
