// Pre-build check: verify required R2 parquets exist before Observable build starts.
// Runs automatically via "prebuild" npm script when WDA_PUBLIC_DATASET_URL is set.
// Fails fast with a clear list of missing files instead of silently building with empty data.

const baseUrl = process.env.WDA_PUBLIC_DATASET_URL;
const datasList = (process.env.DATAS_LIST ?? "")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);

if (!baseUrl) process.exit(0);

// Required build-time observable parquets per dataset
const REQUIRED = {
  sirene: [
    "sirene/observable__funnel.parquet",
    "sirene/observable__stats-by-section.parquet",
    "sirene/observable__etab-stats.parquet",
  ],
};

const toCheck =
  datasList.length === 0
    ? Object.values(REQUIRED).flat()
    : datasList.flatMap((d) => REQUIRED[d] ?? []);

if (toCheck.length === 0) process.exit(0);

console.log(
  `[check-r2] Checking ${toCheck.length} required file(s) on ${baseUrl}...`,
);

const missing = [];
for (const file of toCheck) {
  const url = `${baseUrl}/${file}`;
  try {
    const resp = await fetch(url, { method: "HEAD" });
    if (resp.ok) {
      console.log(`  ✓  ${file}`);
    } else {
      console.error(`  ✗  ${file}  (HTTP ${resp.status})`);
      missing.push(file);
    }
  } catch (err) {
    console.error(`  ✗  ${file}  (${err.message})`);
    missing.push(file);
  }
}

if (missing.length > 0) {
  const datasets = [...new Set(missing.map((f) => f.split("/")[0]))];
  console.error(
    `\n[check-r2] ${missing.length} file(s) missing — upload them first:\n` +
      missing.map((f) => `  ✗  ${f}`).join("\n") +
      `\n\nRun: DATAS_LIST="${datasets.join(",")}" just release-cloudflare`,
  );
  process.exit(1);
}

console.log(`[check-r2] All required R2 files present.`);
