-- Silver: cleaned & conformed franchises.
-- Standardizes country (source uses 'US') to the canonical 'USA' so it matches the customers table.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${silver_schema}.franchises (
  CONSTRAINT valid_franchise_id EXPECT (franchise_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_coordinates EXPECT (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
)
COMMENT 'Cleaned franchises with standardized country.'
AS
SELECT
  franchiseID AS franchise_id,
  name AS franchise_name,
  city,
  district,
  zipcode,
  CASE WHEN country = 'US' THEN 'USA' ELSE country END AS country,
  size,
  longitude,
  latitude,
  supplierID AS supplier_id
FROM ${medallion_catalog}.${bronze_schema}.franchises;
