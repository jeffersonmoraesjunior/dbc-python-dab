-- Bronze: raw ingestion of customer reviews from the read-only samples.bakehouse source.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${bronze_schema}.reviews
COMMENT 'Raw customer reviews ingested from samples.bakehouse.media_customer_reviews.'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.media_customer_reviews' AS _source_table
FROM samples.bakehouse.media_customer_reviews;
