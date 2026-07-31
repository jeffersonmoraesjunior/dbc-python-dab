-- Silver: typed, conformed and enriched transactions.
-- Casts prices to DECIMAL, derives day/month columns, and enriches with franchise and customer attributes.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${silver_schema}.transactions (
  CONSTRAINT valid_keys EXPECT (transaction_id IS NOT NULL AND customer_id IS NOT NULL AND franchise_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT positive_amounts EXPECT (quantity > 0 AND total_price >= 0) ON VIOLATION DROP ROW,
  CONSTRAINT valid_payment_method EXPECT (payment_method IN ('visa', 'mastercard', 'amex'))
)
COMMENT 'Cleaned transactions enriched with franchise and customer dimensions.'
AS
SELECT
  t.transactionID AS transaction_id,
  t.customerID AS customer_id,
  t.franchiseID AS franchise_id,
  t.dateTime AS transaction_timestamp,
  CAST(t.dateTime AS DATE) AS transaction_date,
  day(t.dateTime) AS transaction_day,
  date_format(t.dateTime, 'yyyy-MM') AS transaction_month,
  t.product,
  t.quantity,
  CAST(t.unitPrice AS DECIMAL(10, 2)) AS unit_price,
  CAST(t.totalPrice AS DECIMAL(10, 2)) AS total_price,
  t.paymentMethod AS payment_method,
  f.franchise_name,
  f.city AS franchise_city,
  f.country AS franchise_country,
  c.first_name AS customer_first_name,
  c.last_name AS customer_last_name,
  c.country AS customer_country
FROM ${medallion_catalog}.${bronze_schema}.transactions t
LEFT JOIN ${medallion_catalog}.${silver_schema}.franchises f
  ON t.franchiseID = f.franchise_id
LEFT JOIN ${medallion_catalog}.${silver_schema}.customers c
  ON t.customerID = c.customer_id;
