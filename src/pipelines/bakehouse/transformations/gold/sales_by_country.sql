-- Gold: revenue and activity aggregated per country.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sales_by_country
COMMENT 'Revenue, orders, average ticket, franchise count and customer count per country.'
AS
SELECT
  franchise_country AS country,
  SUM(total_price) AS revenue,
  COUNT(*) AS orders_count,
  SUM(total_price) / COUNT(*) AS avg_ticket,
  COUNT(DISTINCT franchise_id) AS franchise_count,
  COUNT(DISTINCT customer_id) AS customer_count
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY franchise_country;
