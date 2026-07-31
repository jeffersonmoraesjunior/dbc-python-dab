-- Bronze: raw ingestion of franchises from the read-only samples.bakehouse source.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${bronze_schema}.franchises
COMMENT 'Raw franchises ingested from samples.bakehouse.sales_franchises.'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.sales_franchises' AS _source_table
FROM samples.bakehouse.sales_franchises;
