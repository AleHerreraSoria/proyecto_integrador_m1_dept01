-- 1. Ver el entorno de configuración para la carga de archivos locales
SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';

-- 2. Carga de los archivos *.csv a sales_company db
LOAD DATA LOCAL INFILE 'D:\\SoyHenry\\Proyecto Integrador\\data\\categories.csv'
INTO TABLE categories
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:\\SoyHenry\\Proyecto Integrador\\data\\cities.csv'
INTO TABLE cities
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:\\SoyHenry\\Proyecto Integrador\\data\\countries.csv'
INTO TABLE countries
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:\\SoyHenry\\Proyecto Integrador\\data\\customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:\\SoyHenry\\Proyecto Integrador\\data\\employees.csv'
INTO TABLE employees
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:\\SoyHenry\\Proyecto Integrador\\data\\products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:\\SoyHenry\\Proyecto Integrador\\data\\sales.csv'
INTO TABLE sales
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
