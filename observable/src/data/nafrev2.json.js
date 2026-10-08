import { runDuckDBLoader, parquetPath } from "./db.js";

const sections = parquetPath("nafrev2", "sections.parquet");
const divisions = parquetPath("nafrev2", "divisions.parquet");
const groupes = parquetPath("nafrev2", "groupes.parquet");
const classes = parquetPath("nafrev2", "classes.parquet");
const sousClasses = parquetPath("nafrev2", "sous_classes.parquet");

await runDuckDBLoader(
  "nafrev2",
  `SELECT ns.section_id, ns.section,
          nd.division_id, nd.division,
          ng.groupe_id,   ng.groupe,
          nc.classe_id,   nc.classe,
          nsc.sous_classe_id, nsc.sous_classe
   FROM read_parquet(${JSON.stringify(sousClasses)}) nsc
   JOIN read_parquet(${JSON.stringify(
     classes,
   )})    nc  ON nsc.classe_id   = nc.classe_id
   JOIN read_parquet(${JSON.stringify(
     groupes,
   )})    ng  ON nsc.groupe_id   = ng.groupe_id
   JOIN read_parquet(${JSON.stringify(
     divisions,
   )})  nd  ON nsc.division_id = nd.division_id
   JOIN read_parquet(${JSON.stringify(
     sections,
   )})   ns  ON nsc.section_id  = ns.section_id
   ORDER BY nsc.sous_classe_id`,
);
