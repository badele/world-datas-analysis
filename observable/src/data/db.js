import pg from "pg";

export function createClient() {
  return new pg.Client({
    host: process.env.PGHOST ?? "psql",
    port: parseInt(process.env.PGPORT ?? "5432"),
    database: process.env.PGDATABASE ?? "wda",
    user: process.env.PGUSER ?? "wda",
    password: process.env.PGPASSWORD ?? "wda",
  });
}

export async function query(client, sql, params) {
  const { rows } = await client.query(sql, params);
  return rows;
}

export const toJSON = JSON.stringify.bind(JSON);
