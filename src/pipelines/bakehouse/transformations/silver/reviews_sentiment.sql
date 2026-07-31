-- Silver: review sentiment scored with the built-in ai_analyze_sentiment AI function.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${silver_schema}.reviews_sentiment (
  CONSTRAINT valid_review EXPECT (franchise_id IS NOT NULL AND review IS NOT NULL) ON VIOLATION DROP ROW
)
COMMENT 'Customer reviews with sentiment labels from ai_analyze_sentiment.'
AS
SELECT
  new_id AS review_id,
  franchiseID AS franchise_id,
  review_date,
  CAST(review_date AS DATE) AS review_date_day,
  date_format(review_date, 'yyyy-MM') AS review_month,
  review,
  ai_analyze_sentiment(review) AS sentiment
FROM ${medallion_catalog}.${bronze_schema}.reviews;
