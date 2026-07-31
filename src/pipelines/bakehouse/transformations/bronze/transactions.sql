-- Bronze: raw ingestion of sales transactions from the read-only samples.bakehouse source.
-- Catalog and schema are injected via pipeline configuration keys, never hardcoded.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${bronze_schema}.transactions
COMMENT 'Raw sales transactions ingested from samples.bakehouse.sales_transactions.'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.sales_transactions' AS _source_table
FROM samples.bakehouse.sales_transactions;
