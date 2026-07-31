-- Gold: review sentiment distribution per franchise.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sentiment_by_franchise
COMMENT 'Review sentiment distribution (positive/negative/neutral/mixed) per franchise.'
AS
SELECT
  f.franchise_id,
  f.franchise_name,
  f.country,
  COUNT(*) AS total_reviews,
  SUM(CASE WHEN r.sentiment = 'positive' THEN 1 ELSE 0 END) AS positive_count,
  SUM(CASE WHEN r.sentiment = 'negative' THEN 1 ELSE 0 END) AS negative_count,
  SUM(CASE WHEN r.sentiment = 'neutral' THEN 1 ELSE 0 END) AS neutral_count,
  SUM(CASE WHEN r.sentiment = 'mixed' THEN 1 ELSE 0 END) AS mixed_count,
  SUM(CASE WHEN r.sentiment = 'positive' THEN 1 ELSE 0 END) / COUNT(*) AS positive_pct
FROM ${medallion_catalog}.${silver_schema}.reviews_sentiment r
JOIN ${medallion_catalog}.${silver_schema}.franchises f
  ON r.franchise_id = f.franchise_id
GROUP BY f.franchise_id, f.franchise_name, f.country;
