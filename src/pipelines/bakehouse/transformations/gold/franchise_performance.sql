-- Gold: per-franchise performance with geo attributes for the map widget.
-- LEFT JOIN from franchises so all 48 franchises appear, including any with zero sales.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.franchise_performance
COMMENT 'Per-franchise performance (revenue, orders, avg ticket, unique customers) with city, country, latitude and longitude.'
AS
SELECT
  f.franchise_id,
  f.franchise_name,
  f.city,
  f.country,
  f.latitude,
  f.longitude,
  COUNT(t.transaction_id) AS orders_count,
  COALESCE(SUM(t.total_price), 0) AS revenue,
  CASE WHEN COUNT(t.transaction_id) > 0 THEN SUM(t.total_price) / COUNT(t.transaction_id) ELSE 0 END AS avg_ticket,
  COUNT(DISTINCT t.customer_id) AS unique_customers
FROM ${medallion_catalog}.${silver_schema}.franchises f
LEFT JOIN ${medallion_catalog}.${silver_schema}.transactions t
  ON f.franchise_id = t.franchise_id
GROUP BY f.franchise_id, f.franchise_name, f.city, f.country, f.latitude, f.longitude;
