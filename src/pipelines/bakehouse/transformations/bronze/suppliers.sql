-- Bronze: raw ingestion of suppliers from the read-only samples.bakehouse source.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${bronze_schema}.suppliers
COMMENT 'Raw suppliers ingested from samples.bakehouse.sales_suppliers.'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.sales_suppliers' AS _source_table
FROM samples.bakehouse.sales_suppliers;
