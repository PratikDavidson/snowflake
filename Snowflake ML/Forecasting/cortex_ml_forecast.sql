-- This is your Cortex Project.
-----------------------------------------------------------
-- SETUP
-----------------------------------------------------------
use role ACCOUNTADMIN;
use warehouse SNOWFLAKE_ML_WH;
use database SNOWFLAKE_ML_DB;
use schema SNOWFLAKE_ML_SCHEMA;

-- Inspect the first 10 rows of your training data. This is the data we'll use to create your model.
select * from TRAIN_DATA limit 10;

-- Prepare your training data. Timestamp_ntz is a required format.
CREATE OR REPLACE VIEW TRAIN_DATA_v1 AS SELECT
    * EXCLUDE DATE,
    to_timestamp_ntz(DATE) as DATE_v1
FROM TRAIN_DATA;

-- Prepare your prediction data. Timestamp_ntz is a required format.
CREATE OR REPLACE VIEW TEST_DATA_v1 AS SELECT
    * EXCLUDE DATE,
    to_timestamp_ntz(DATE) as DATE_v1
FROM TEST_DATA;

-----------------------------------------------------------
-- CREATE PREDICTIONS
-----------------------------------------------------------
-- Create your model.
CREATE OR REPLACE SNOWFLAKE.ML.FORECAST mean_temp_forecast_model(
    INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'TRAIN_DATA_v1'),
    TIMESTAMP_COLNAME => 'DATE_v1',
    TARGET_COLNAME => 'MEANTEMP'
);

-- Generate predictions and store the results to a table.
BEGIN
    -- This is the step that creates your predictions.
    CALL mean_temp_forecast_model!FORECAST(
        INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'TEST_DATA_v1'),
        TIMESTAMP_COLNAME => 'DATE_v1',
        -- Here we set your prediction interval.
        CONFIG_OBJECT => {'prediction_interval': 0.95}
    );
    -- These steps store your predictions to a table.
    LET x := SQLID;
    CREATE TABLE mean_temp_forecast AS SELECT * FROM TABLE(RESULT_SCAN(:x));
END;

-- View your predictions.
SELECT * FROM mean_temp_forecast;

-- Union your predictions with your historical data, then view the results in a chart.
SELECT DATE, MEANTEMP AS actual, NULL AS forecast, NULL AS lower_bound, NULL AS upper_bound
    FROM TRAIN_DATA
UNION ALL
SELECT ts as DATE, NULL AS actual, forecast, lower_bound, upper_bound
    FROM mean_temp_forecast;

-----------------------------------------------------------
-- INSPECT RESULTS
-----------------------------------------------------------

-- Inspect the accuracy metrics of your model. 
CALL mean_temp_forecast_model!SHOW_EVALUATION_METRICS();

-- Inspect the relative importance of your features, including auto-generated features. 
CALL mean_temp_forecast_model!EXPLAIN_FEATURE_IMPORTANCE();
