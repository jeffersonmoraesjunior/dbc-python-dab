-- Gold: product mix - revenue, quantity and share of total revenue per product.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sales_by_product
COMMENT 'Revenue, quantity sold, orders and revenue share per product.'
AS
SELECT
  product,
  SUM(total_price) AS revenue,
  SUM(quantity) AS quantity_sold,
  COUNT(*) AS orders_count,
  SUM(total_price) / SUM(SUM(total_price)) OVER () AS revenue_share
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY product;
