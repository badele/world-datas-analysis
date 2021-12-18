-- continent
SELECT *
INTO OUTFILE '/exported/continent.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM country_name_tool_continent;

-- country
SELECT *
INTO OUTFILE '/exported/country.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM country_name_tool_countrydata;

-- country latest data
SELECT *
INTO OUTFILE '/exported/country_latest_data.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM country_latest_data;


-- datasets
SELECT *
INTO OUTFILE '/exported/datasets.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM datasets;

-- data values
SELECT *
INTO OUTFILE '/exported/data_values.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM data_values;

-- data tags
SELECT *
INTO OUTFILE '/exported/dataset_tags.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM dataset_tags;

-- entities 
SELECT *
INTO OUTFILE '/exported/entities.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM entities;

-- namespaces
SELECT *
INTO OUTFILE '/exported/namespaces.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM namespaces;

-- sources
SELECT *
INTO OUTFILE '/exported/sources.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM sources;

-- tags 
SELECT *
INTO OUTFILE '/exported/tags.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM tags;

-- variables
SELECT *
INTO OUTFILE '/exported/variables.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM variables;