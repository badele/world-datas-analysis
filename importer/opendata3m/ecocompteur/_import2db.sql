BEGIN TRANSACTION;

-------------------------------------------------------------------------------
-- Download datas
-------------------------------------------------------------------------------
CREATE OR REPLACE TABLE opendata3m_ecocompteur_list AS
    SELECT * FROM read_csv('./dataset/opendata3m/ecocompteur/list.csv');

CREATE OR REPLACE TABLE opendata3m_observations AS
    SELECT * FROM read_csv('./dataset/opendata3m/ecocomtpeur/observations.csv');

COMMIT;

.read './importer/opendata3m/ecocompteur/_commons.sql'
