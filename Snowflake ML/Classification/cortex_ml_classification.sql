-- This is your Cortex Project.
-----------------------------------------------------------
-- SETUP
-----------------------------------------------------------
use role ACCOUNTADMIN;
use warehouse SNOWFLAKE_ML_WH;
use database SNOWFLAKE_ML_DB;
use schema SNOWFLAKE_ML_SCHEMA;

-- Inspect the first 10 rows of your training data. This is the data we'll
-- use to create your model.
select * from HEART_ATTACK_CLASSIFICATION_TRAIN_TBL limit 10;

-- Inspect the first 10 rows of your prediction data. This is the data the model
-- will use to generate predictions.
select * from HEART_ATTACK_CLASSIFICATION_TEST_TBL limit 10;

-----------------------------------------------------------
-- CREATE PREDICTIONS
-----------------------------------------------------------
-- Create your model.
CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION heart_attack_classifier(
    INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'HEART_ATTACK_CLASSIFICATION_TRAIN_TBL'),
    TARGET_COLNAME => 'OUTPUT',
    CONFIG_OBJECT => { 'ON_ERROR': 'SKIP' }
);

-- Inspect your logs to ensure training completed successfully. 
CALL heart_attack_classifier!SHOW_TRAINING_LOGS();

-- Generate predictions as new columns in to your prediction table.
CREATE OR REPLACE TABLE classification_prediction_table AS SELECT
    *, 
    heart_attack_classifier!PREDICT(
        OBJECT_CONSTRUCT(*),
        -- This option alows the prediction process to complete even if individual rows must be skipped.
        {'ON_ERROR': 'SKIP'}
    ) as predictions
from HEART_ATTACK_CLASSIFICATION_TEST_TBL;

-- View your predictions.
SELECT * FROM classification_prediction_table;

-- Parse the prediction results into separate columns. 
-- Note: This is a just an example. Be sure to update this to reflect 
-- the classes in your dataset.
SELECT * EXCLUDE predictions,
        predictions:class AS class,
        round(predictions['probability'][class], 3) as probability
FROM classification_prediction_table;

-----------------------------------------------------------
-- INSPECT RESULTS
-----------------------------------------------------------

-- Inspect your model's evaluation metrics.
CALL heart_attack_classifier!SHOW_EVALUATION_METRICS();
CALL heart_attack_classifier!SHOW_GLOBAL_EVALUATION_METRICS();
CALL heart_attack_classifier!SHOW_CONFUSION_MATRIX();

-- Inspect the relative importance of your features, including auto-generated features.  
CALL heart_attack_classifier!SHOW_FEATURE_IMPORTANCE();

