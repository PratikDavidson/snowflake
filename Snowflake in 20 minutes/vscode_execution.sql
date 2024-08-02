//Step-1: Create virtual warehouse
CREATE OR REPLACE WAREHOUSE sf_tuts_wh WITH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 180
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

//Step-2: Create database with default schema
CREATE OR REPLACE DATABASE sf_tuts;

//Step-3: Create table
CREATE OR REPLACE TABLE emp_basic (
    first_name STRING,
    last_name STRING,
    email STRING,
    streetaddess STRING,
    city STRING,
    start_date DATE
);

//Step-4: Stage data files
PUT 'file://D:/Snowflake/Snowflake in 20 minutes/employees0*.csv' @sf_tuts.public.%emp_basic;

LIST @sf_tuts.public.%emp_basic;

//Step-5: Copy data into target tables
COPY INTO emp_basic
  FROM @%emp_basic
  FILE_FORMAT = (type = csv field_optionally_enclosed_by='"')
  PATTERN = '.*employees0[1-5].csv.gz'
  ON_ERROR = 'skip_file';

//Step-6: Query loaded data
SELECT * FROM emp_basic;