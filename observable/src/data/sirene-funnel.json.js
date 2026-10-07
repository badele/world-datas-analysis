import { runDuckDBLoader } from "./db.js";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const src = process.env.WDA_PUBLIC_DATASET_URL
  ? `${process.env.WDA_PUBLIC_DATASET_URL}/sirene/observable__funnel.parquet`
  : path.resolve(
      __dirname,
      "../../../dataset/sirene/observable/funnel.parquet",
    );

await runDuckDBLoader("sirene-funnel", `SELECT * FROM read_parquet('${src}')`);
