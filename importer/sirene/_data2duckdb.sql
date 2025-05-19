.mode box

BEGIN TRANSACTION;

-------------------------------------------------------------------------------
-- NAFRev2
-------------------------------------------------------------------------------
SELECT 'import NAFRev2' as mess;
CREATE OR REPLACE TABLE sirene_nafrev2 (
    code VARCHAR,
    description VARCHAR
)
;

INSERT INTO sirene_nafrev2
    FROM read_csv('./downloaded/sirene/NAFRev2.csv',ignore_errors=true)
;

DROP INDEX IF EXISTS idx_sirene_nafrev2_code;
-- CREATE INDEX idx_sirene_nafrev2_code ON sirene_nafrev2 (code);

-------------------------------------------------------------------------------
-- unite legales
-------------------------------------------------------------------------------
SELECT 'import sirene_entreprises' as mess;
CREATE OR REPLACE TABLE sirene_entreprises (
    siren VARCHAR,
    dateCreationUniteLegale DATE,
    sigleUniteLegale VARCHAR,
    identifiantAssociationUniteLegale VARCHAR,
    trancheEffectifsUniteLegale VARCHAR,
    minNbEffectifsUniteLegale BIGINT,
    anneeEffectifsUniteLegale BIGINT,
    dateDernierTraitementUniteLegale TIMESTAMP,
    nombrePeriodesUniteLegale BIGINT,
    categorieEntreprise VARCHAR,
    anneeCategorieEntreprise BIGINT,
    dateDebut DATE,
    denominationUniteLegale VARCHAR,
    denominationUsuelle1UniteLegale VARCHAR,
    denominationUsuelle2UniteLegale VARCHAR,
    denominationUsuelle3UniteLegale VARCHAR,
    activitePrincipaleUniteLegale VARCHAR,
    nomenclatureActivitePrincipaleUniteLegale VARCHAR,
    nicSiegeUniteLegale VARCHAR,
    economieSocialeSolidaireUniteLegale VARCHAR,
)
;

INSERT INTO sirene_entreprises
    SELECT
        siren,
        dateCreationUniteLegale,
        sigleUniteLegale,
        identifiantAssociationUniteLegale,
        trancheEffectifsUniteLegale,
        NULL,
        anneeEffectifsUniteLegale,
        dateDernierTraitementUniteLegale,
        nombrePeriodesUniteLegale,
        categorieEntreprise,
        anneeCategorieEntreprise,
        dateDebut,
        denominationUniteLegale,
        denominationUsuelle1UniteLegale,
        denominationUsuelle2UniteLegale,
        denominationUsuelle3UniteLegale,
        activitePrincipaleUniteLegale,
        nomenclatureActivitePrincipaleUniteLegale,
        nicSiegeUniteLegale,
        economieSocialeSolidaireUniteLegale
    FROM read_csv('./downloaded/sirene/StockUniteLegale_utf8.csv',ignore_errors=true)
    WHERE
        unitePurgeeUniteLegale is not true
        AND categorieJuridiqueUniteLegale!=1000
        AND etatAdministratifUniteLegale!='C'
        AND statutDiffusionUniteLegale='O'
;

DROP INDEX IF EXISTS idx_sirene_entreprises_siren;
-- CREATE INDEX idx_sirene_entreprises_siren ON sirene_entreprises (siren);

-------------------------------------------------------------------------------
-- Etablissements
-------------------------------------------------------------------------------
SELECT 'import sirene_etablissements' as mess;
CREATE OR REPLACE TABLE sirene_etablissements(
    siren VARCHAR,
    nic VARCHAR,
    siret VARCHAR,
    dateCreationEtablissement DATE,
    trancheEffectifsEtablissement VARCHAR,
    minNbEffectifsEtablissement BIGINT,
    anneeEffectifsEtablissement BIGINT,
    activitePrincipaleRegistreMetiersEtablissement VARCHAR,
    dateDernierTraitementEtablissement TIMESTAMP,
    etablissementSiege BOOLEAN,
    nombrePeriodesEtablissement BIGINT,
    complementAdresseEtablissement VARCHAR,
    numeroVoieEtablissement VARCHAR,
    indiceRepetitionEtablissement VARCHAR,
    dernierNumeroVoieEtablissement VARCHAR,
    typeVoieEtablissement VARCHAR,
    libelleVoieEtablissement VARCHAR,
    codePostalEtablissement VARCHAR,
    libelleCommuneEtablissement VARCHAR,
    libelleCommuneEtrangerEtablissement VARCHAR,
    distributionSpecialeEtablissement VARCHAR,
    codeCommuneEtablissement VARCHAR,
    departementEtablissement VARCHAR,
    codePaysEtrangerEtablissement VARCHAR,
    libellePaysEtrangerEtablissement VARCHAR,
    identifiantAdresseEtablissement VARCHAR,
    coordonneeLambertAbscisseEtablissement VARCHAR,
    coordonneeLambertOrdonneeEtablissement VARCHAR,
    dateDebut DATE,
    enseigne1Etablissement VARCHAR,
    enseigne2Etablissement VARCHAR,
    enseigne3Etablissement VARCHAR,
    denominationUsuelleEtablissement VARCHAR,
    activitePrincipaleEtablissement VARCHAR,
    nomenclatureActivitePrincipaleEtablissement VARCHAR,
    geonames_cityid BIGINT,
    geonames_city TEXT,
    longitude DOUBLE,
    latitude DOUBLE
)
;

INSERT INTO sirene_etablissements
    SELECT
        siren,
        nic,
        siret,
        dateCreationEtablissement,
        trancheEffectifsEtablissement,
        NULL,
        anneeEffectifsEtablissement,
        activitePrincipaleRegistreMetiersEtablissement,
        dateDernierTraitementEtablissement,
        etablissementSiege,
        nombrePeriodesEtablissement,
        complementAdresseEtablissement,
        numeroVoieEtablissement,
        indiceRepetitionEtablissement,
        dernierNumeroVoieEtablissement,
        typeVoieEtablissement,
        libelleVoieEtablissement,
        codePostalEtablissement,
        libelleCommuneEtablissement,
        libelleCommuneEtrangerEtablissement,
        distributionSpecialeEtablissement,
        codeCommuneEtablissement,
        substring(codeCommuneEtablissement, 1, 2),
        codePaysEtrangerEtablissement,
        libellePaysEtrangerEtablissement,
        identifiantAdresseEtablissement,
        coordonneeLambertAbscisseEtablissement,
        coordonneeLambertOrdonneeEtablissement,
        dateDebut,
        enseigne1Etablissement,
        enseigne2Etablissement,
        enseigne3Etablissement,
        denominationUsuelleEtablissement,
        activitePrincipaleEtablissement,
        nomenclatureActivitePrincipaleEtablissement,
        NULL,
        NULL,
        NULL,
        NULL
    FROM read_csv('./downloaded/sirene/StockEtablissement_utf8.csv')
    WHERE
            statutDiffusionEtablissement='O'
            AND etatAdministratifEtablissement='A'
            AND caractereEmployeurEtablissement='O'
    ;


DROP INDEX IF EXISTS idx_sirene_etablissements_siren;
-- CREATE INDEX idx_sirene_etablissements_siren ON sirene_etablissements (siren);
--
DROP INDEX IF EXISTS idx_sirene_etablissements_siret;
-- CREATE INDEX idx_sirene_etablissements_siret ON sirene_etablissements (siret);
--
DROP INDEX IF EXISTS idx_tmp_sirene_etablissements_trancheEffectifsEtablissement;
-- CREATE INDEX idx_tmp_sirene_etablissements_trancheEffectifsEtablissement ON sirene_etablissements (trancheEffectifsEtablissement);

-------------------------------------------------------------------------------
-- Etablissements geolocalisation
-------------------------------------------------------------------------------
SELECT 'import sirene_etablissements_geoloc' as mess;
CREATE OR REPLACE TABLE tmp_sirene_etablissements_geoloc(
    siret VARCHAR,
    y_latitude DOUBLE,
    x_longitude DOUBLE
)
;

INSERT INTO tmp_sirene_etablissements_geoloc
SELECT
    siret,
    y_latitude,
    x_longitude
FROM read_csv('./downloaded/sirene/GeolocalisationEtablissement_Sirene_pour_etudes_statistiques_utf8.csv')
;
--
DROP INDEX IF EXISTS idx_tmp_sirene_etablissements_geoloc_siret;
-- CREATE INDEX idx_tmp_sirene_etablissements_geoloc_siret ON tmp_sirene_etablissements_geoloc (siret);


-------------------------------------------------------------------------------
-- Fix
-------------------------------------------------------------------------------
SELECT 'fix trancheEffectifsEtablissement' as mess;
UPDATE sirene_etablissements ets SET minNbEffectifsEtablissement = 0 WHERE ets.trancheEffectifsEtablissement = 'NN';
UPDATE sirene_etablissements ets SET minNbEffectifsEtablissement = 0 WHERE ets.trancheEffectifsEtablissement = '00';
UPDATE sirene_etablissements ets SET minNbEffectifsEtablissement = 1 WHERE ets.trancheEffectifsEtablissement = '01';
UPDATE sirene_etablissements ets SET minNbEffectifsEtablissement = 3 WHERE ets.trancheEffectifsEtablissement = '02';
UPDATE sirene_etablissements ets SET minNbEffectifsEtablissement = 6 WHERE ets.trancheEffectifsEtablissement = '03';
UPDATE sirene_etablissements ets SET minNbEffectifsEtablissement = 10 WHERE ets.trancheEffectifsEtablissement = '11';
UPDATE sirene_etablissements ets SET minNbEffectifsEtablissement = 20 WHERE ets.trancheEffectifsEtablissement = '12';
UPDATE sirene_etablissements ets SET minNbEffectifsEtablissement = 50 WHERE ets.trancheEffectifsEtablissement = '21';
UPDATE sirene_etablissements ets SET minNbEffectifsEtablissement = 100 WHERE ets.trancheEffectifsEtablissement = '22';
UPDATE sirene_etablissements ets SET minNbEffectifsEtablissement = 200 WHERE ets.trancheEffectifsEtablissement = '31';
UPDATE sirene_etablissements ets SET minNbEffectifsEtablissement = 250 WHERE ets.trancheEffectifsEtablissement = '32';
UPDATE sirene_etablissements ets SET minNbEffectifsEtablissement = 500 WHERE ets.trancheEffectifsEtablissement = '41';
UPDATE sirene_etablissements ets SET minNbEffectifsEtablissement = 1000 WHERE ets.trancheEffectifsEtablissement = '42';
UPDATE sirene_etablissements ets SET minNbEffectifsEtablissement = 2000 WHERE ets.trancheEffectifsEtablissement = '51';
UPDATE sirene_etablissements ets SET minNbEffectifsEtablissement = 5000 WHERE ets.trancheEffectifsEtablissement = '52';
UPDATE sirene_etablissements ets SET minNbEffectifsEtablissement = 10000 WHERE ets.trancheEffectifsEtablissement = '53';
-- --
SELECT 'fix geonames_cityid' as mess;
UPDATE sirene_etablissements ets
SET geonames_cityid = (
    SELECT city_id
    FROM geonames_allentries
    WHERE
        country_code = 'FR'
        AND feature_code = 'ADM4'
        AND admin4_code = ets.codeCommuneEtablissement
)
;

SELECT 'fix geonames_city' as mess;
UPDATE sirene_etablissements ets
SET geonames_city = (
    SELECT city_name
    FROM geonames_allentries
    WHERE
        country_code = 'FR'
        AND feature_code = 'ADM4'
        AND admin4_code = ets.codeCommuneEtablissement
)
;

SELECT 'fix geonames_longitude' as mess;
UPDATE sirene_etablissements ets
SET longitude = (
    SELECT x_longitude
    FROM tmp_sirene_etablissements_geoloc
    WHERE siret = ets.siret
)
;

SELECT 'fix geonames_latitude' as mess;
UPDATE sirene_etablissements ets
SET latitude = (
    SELECT y_latitude
    FROM tmp_sirene_etablissements_geoloc
    WHERE siret = ets.siret
)
;

-------------------------------------------------------------------------------
-- export to ./dataset
-------------------------------------------------------------------------------
SELECT 'export sirene to parquet' as mess;

COPY sirene_nafrev2 TO './dataset/sirene/nafrev2.parquet' (FORMAT 'parquet', COMPRESSION 'zstd');
COPY sirene_entreprises TO './dataset/sirene/entreprises.parquet' (FORMAT 'parquet', COMPRESSION 'zstd');
COPY sirene_etablissements TO './dataset/sirene/etablissements.parquet' (FORMAT 'parquet', COMPRESSION 'zstd');

SELECT 'COMMIT' as mess;
COMMIT;
