--------------------------------------
-- Dataset
--------------------------------------

DROP TABLE IF EXISTS wda_providers;
CREATE TABLE IF NOT EXISTS wda_providers(
    provider	    TEXT,
    description     TEXT,
    website         TEXT,
    nb_datasets     INTEGER,
    nb_observations INTEGER,
    PRIMARY KEY(provider)
);
--
-- DROP TABLE IF EXISTS wda_datasets;
CREATE TABLE IF NOT EXISTS wda_datasets(
    provider	    TEXT,
    real_provider   TEXT,
    dataset         TEXT,
    scope	    TEXT,
    description	    TEXT,
    source	    TEXT,
    nb_variables   INTEGER,
    nb_observations INTEGER,
    nb_scopes       INTEGER,
    PRIMARY KEY(provider,real_provider,dataset)
);

-- DROP TABLE IF EXISTS wda_scopes;
CREATE TABLE IF NOT EXISTS wda_scopes(
    provider	    TEXT,
    dataset         TEXT,
    scopevalue      TEXT,
    nb_observations INTEGER,
    PRIMARY KEY(provider,dataset,scopevalue)
);

CREATE TABLE IF NOT EXISTS wda_blacklist_ips(
  ip_number BIGINT,
  ip TEXT,
  duggytuxy INTEGER,
  ipsum INTEGER
);
CREATE INDEX IF NOT EXISTS wda_blacklist_ips_idx ON wda_blacklist_ips(ip_number);
