-- Gold: daily revenue, orders and average ticket per franchise.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.daily_sales_by_franchise
COMMENT 'Daily revenue, order count and average ticket per franchise.'
AS
SELECT
  transaction_date AS sale_date,
  franchise_id,
  franchise_name,
  franchise_country AS country,
  SUM(total_price) AS revenue,
  COUNT(*) AS orders_count,
  SUM(total_price) / COUNT(*) AS avg_ticket
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY transaction_date, franchise_id, franchise_name, franchise_country;
