-- Bronze: raw ingestion of customers from the read-only samples.bakehouse source.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${bronze_schema}.customers
COMMENT 'Raw customers ingested from samples.bakehouse.sales_customers.'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.sales_customers' AS _source_table
FROM samples.bakehouse.sales_customers;
