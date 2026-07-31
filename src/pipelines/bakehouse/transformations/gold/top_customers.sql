-- Gold: customer spending ranking.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.top_customers
COMMENT 'Per-customer total revenue, orders and average ticket, ordered by spend.'
AS
SELECT
  t.customer_id,
  concat_ws(' ', t.customer_first_name, t.customer_last_name) AS customer_name,
  t.customer_country AS country,
  SUM(t.total_price) AS total_revenue,
  COUNT(*) AS orders_count,
  SUM(t.total_price) / COUNT(*) AS avg_ticket
FROM ${medallion_catalog}.${silver_schema}.transactions t
GROUP BY t.customer_id, t.customer_first_name, t.customer_last_name, t.customer_country;
