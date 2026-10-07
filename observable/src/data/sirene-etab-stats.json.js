import { runDuckDBLoader } from "./db.js";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const src = process.env.WDA_PUBLIC_DATASET_URL
  ? `${process.env.WDA_PUBLIC_DATASET_URL}/sirene/observable__etab-stats.parquet`
  : path.resolve(
      __dirname,
      "../../../dataset/sirene/observable/etab-stats.parquet",
    );

await runDuckDBLoader(
  "sirene-etab-stats",
  `SELECT * FROM read_parquet('${src}')`,
);
