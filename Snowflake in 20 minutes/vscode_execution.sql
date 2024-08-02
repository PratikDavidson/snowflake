//Snowflake in 20 minutes

CREATE OR REPLACE WAREHOUSE sf_tuts_wh WITH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 180
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

CREATE OR REPLACE DATABASE sf_tuts;

CREATE OR REPLACE TABLE emp_basic (
    first_name STRING,
    last_name STRING,
    email STRING,
    streetaddess STRING,
    city STRING,
    start_date DATE
);

PUT file://D://Snowflake//'Snowflake in 20 minutes'//employees0*.csv @sf_tuts.public.%emp_basic;