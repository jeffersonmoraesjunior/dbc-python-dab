-- Silver: cleaned & conformed customers.
-- Standardizes country to the canonical 'USA' (source already uses 'USA' here, applied for consistency).
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${silver_schema}.customers (
  CONSTRAINT valid_customer_id EXPECT (customer_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_email EXPECT (email_address IS NOT NULL AND email_address LIKE '%@%')
)
COMMENT 'Cleaned customers with standardized country and derived full name.'
AS
SELECT
  customerID AS customer_id,
  first_name,
  last_name,
  concat_ws(' ', first_name, last_name) AS full_name,
  email_address,
  phone_number,
  address,
  city,
  state,
  CASE WHEN country = 'US' THEN 'USA' ELSE country END AS country,
  continent,
  postal_zip_code,
  gender
FROM ${medallion_catalog}.${bronze_schema}.customers;
