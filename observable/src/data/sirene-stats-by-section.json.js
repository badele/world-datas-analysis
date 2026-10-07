import { runDuckDBLoader } from "./db.js";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const src = process.env.WDA_PUBLIC_DATASET_URL
  ? `${process.env.WDA_PUBLIC_DATASET_URL}/sirene/observable__stats-by-section.parquet`
  : path.resolve(
      __dirname,
      "../../../dataset/sirene/observable/stats-by-section.parquet",
    );

await runDuckDBLoader(
  "sirene-stats-by-section",
  `SELECT * FROM read_parquet('${src}')`,
);
