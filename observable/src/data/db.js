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

export async function runLoader(name, fn, defaultValue = []) {
  const client = createClient();
  let result = defaultValue;
  try {
    await client.connect();
    result = await fn(client);
  } catch (err) {
    process.stderr.write(`\n${"=".repeat(60)}\n`);
    process.stderr.write(`[LOADER ERROR] ${name}: ${err.message}\n`);
    process.stderr.write(`${"=".repeat(60)}\n\n`);
  } finally {
    await client.end().catch(() => {});
  }
  process.stdout.write(toJSON(result));
}
