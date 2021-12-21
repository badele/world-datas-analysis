.head on
.nullvalue NULL

--------------------------------------
-- Dataset
--------------------------------------

--DROP TABLE IF EXISTS wda_provider;
CREATE TABLE IF NOT EXISTS wda_provider(
    provider	    TEXT,
    description     TEXT,
    website         INTEGER,
    nb_datasets     INTEGER,
    max_variables   INTEGER,
    nb_observations INTEGER,
    max_scope       INTEGER,
    PRIMARY KEY(provider)
);


--DROP TABLE IF EXISTS wda_dataset;
CREATE TABLE IF NOT EXISTS wda_dataset(
    provider	    TEXT,
    real_provider	TEXT,
    dataset         TEXT,
    max_variables    INTEGER,
    nb_sobservations INTEGER,
    max_scope       INTEGER,
    PRIMARY KEY(provider,real_provider,dataset)
);

--DROP TABLE IF EXISTS wda_variable;
CREATE TABLE IF NOT EXISTS wda_variable(
    provider        TEXT,
    real_provider	TEXT,
    dataset         TEXT,
    variable        TEXT,
    scope           TEXT,
    source	        TEXT,
    nb_scope        INTEGER,
    nb_variables    INTEGER,
    nb_observations INTEGER,
    PRIMARY KEY(provider,dataset,variable)
);


-- CREATE TABLE IF NOT EXISTS wda_dataset(
--     provider	    TEXT,
--     scope TEXT,
--     nb_scopes INTEGER,
--     nb_variables INTEGER
--     PRIMARY KEY(provider,scope)
-- );

-- --DROP TABLE IF EXISTS db_category;
-- CREATE TABLE IF NOT EXISTS db_category(
--     CAT_ID              INTEGER,
--     SOURCE_ID	        INTEGER,
--     LANG                TEXT,
--     CategoryKey	        INTEGER,
--     Description	        TEXT,
--     PRIMARY KEY(CAT_ID AUTOINCREMENT)
-- );  

-- --DROP TABLE IF EXISTS db_indicator_description;
-- CREATE TABLE IF NOT EXISTS db_indicator_description(
--     SOURCE_ID	            TEXT,
--     LANG                    TEXT,
--     IndicatorKey            TEXT,
--     Description	            TEXT,
--     PRIMARY KEY(SOURCE_ID, LANG, IndicatorKey) 
-- );

-- --DROP TABLE IF EXISTS db_indicator_in_category;
-- CREATE TABLE IF NOT EXISTS db_indicator_in_category(
--     CAT_ID          INTEGER,
--     IndicatorKey    INTEGER,
--     PRIMARY KEY(CAT_ID, IndicatorKey) 
-- );  

-- --DROP TABLE IF EXISTS db_historical_country_value;
-- CREATE TABLE IF NOT EXISTS db_historical_country_value(
--     SOURCE_ID   INTEGER,
--     COUNTRYCODE   TEXT,
--     YEAR          INTEGER,
--     IndicatorKey  TEXT,
--     value         REAL,
--     PRIMARY KEY(SOURCE_ID, YEAR, COUNTRYCODE, IndicatorKey) 
-- );  
-- CREATE INDEX IF NOT EXISTS idx_historical_sourceid ON db_historical_country_value(SOURCE_ID);
-- CREATE INDEX IF NOT EXISTS idx_historical_country_value_year ON db_historical_country_value(SOURCE_ID,YEAR);
-- CREATE INDEX IF NOT EXISTS idx_historical_country_value_sourceid_countrycode_indicatorcode_year ON db_historical_country_value(SOURCE_ID,COUNTRYCODE,IndicatorKey,YEAR);
-- CREATE INDEX IF NOT EXISTS idx_historical_country_value_sourceid_countrycode_indicatorcode ON db_historical_country_value(SOURCE_ID,COUNTRYCODE,IndicatorKey);


-- --DROP TABLE IF EXISTS db_historical_country_summary;
-- CREATE TABLE IF NOT EXISTS db_historical_country_summary (
--   SOURCE_ID INTEGER,
--   COUNTRYCODE TEXT,
--   IndicatorKey TEXT,
--   first_year INTEGER,
--   last_year INTEGER,
--   nbyears INTEGER,
--   first_value REAL,
--   last_value REAL,
--   growth_percent REAL,
--   min_value REAL,
--   max_value REAL,
--   lr_a REAL,
--   lr_b REAL,
--   lr_percent_slope REAL,
--   data_quality REAL,
--   corr REAL,
  
--   PRIMARY KEY (SOURCE_ID, COUNTRYCODE,IndicatorKey)
-- );

-- CREATE INDEX IF NOT EXISTS idx_historical_country_summary_sourceid ON db_historical_country_summary(SOURCE_ID);
-- CREATE INDEX IF NOT EXISTS idx_historical_country_summary_sourceid_countrycode_indicatorcode_firstyear ON db_historical_country_summary(SOURCE_ID,COUNTRYCODE,IndicatorKey,first_year);
