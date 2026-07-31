-- Gold: payment method mix - revenue, orders and share of total revenue per payment method.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sales_by_payment_method
COMMENT 'Revenue, orders and revenue share per payment method.'
AS
SELECT
  payment_method,
  COUNT(*) AS orders_count,
  SUM(total_price) AS revenue,
  SUM(total_price) / SUM(SUM(total_price)) OVER () AS revenue_share
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY payment_method;
