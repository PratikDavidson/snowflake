
-- Create virtual warehouse
CREATE WAREHOUSE IF NOT EXISTS rag_chatbot_wh WITH
    WAREHOUSE_SIZE='X-SMALL'
    AUTO_SUSPEND = 180
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED=TRUE;

-- Create database
CREATE DATABASE IF NOT EXISTS rag_chatbot_db;

-- Create schema
CREATE SCHEMA IF NOT EXISTS rag_chatbot_db.rag_chatbot_schema;

-- Create stage
CREATE STAGE IF NOT EXISTS rag_chatbot_db.rag_chatbot_schema.wikipedia_mountain_assets
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- List files
LS @wikipedia_mountain_assets;

-- Create and insert data to vector database
CREATE OR REPLACE TABLE vector_db AS
SELECT file_name, url_link, func.chunk AS chunk, SNOWFLAKE.CORTEX.EMBED_TEXT_768('e5-base-v2',chunk) AS chunk_vec 
FROM file_url_info, TABLE(pdf_text_chunker(build_scoped_file_url(@wikipedia_mountain_assets, file_name ))) AS func;

-- Test
WITH results AS 
(SELECT url_link, VECTOR_COSINE_SIMILARITY(vector_db.chunk_vec,
SNOWFLAKE.CORTEX.EMBED_TEXT_768('e5-base-v2', 'What is snowflake?')) AS similarity, chunk
FROM vector_db
ORDER BY similarity DESC
LIMIT 3)
SELECT chunk, similarity, url_link FROM results; 

-- Clean resources
DROP WAREHOUSE rag_chatbot_wh;
DROP DATABASE rag_chatbot_db;
