ATTACH 'db/wda.sqlite' AS sqlite (TYPE SQLITE);
USE sqlite;

.read './importer/init_commons.sql'
