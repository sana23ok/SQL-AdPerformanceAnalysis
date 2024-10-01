SELECT 
    ad_date, 
    campaign_id,
    SUM(spend) AS ttl_spend,
    SUM(impressions) AS ttl_impressions,
    SUM(clicks) AS ttl_clicks,
    SUM(value) AS ttl_conversion_val,
    ROUND(SUM(clicks)::numeric / SUM(impressions)::numeric * 100, 2) AS CTR,
    ROUND(SUM(spend)::numeric / SUM(clicks)::numeric, 2) AS CPC,
    ROUND(SUM(spend)::numeric / SUM(impressions)::numeric * 1000, 2) AS CPM,
    ROUND(((SUM(value) - SUM(spend))::numeric / SUM(spend)) * 100, 2) AS ROMI
FROM 
    facebook_ads_basic_daily
WHERE 
    impressions != 0 
AND 
    clicks != 0
AND 
    spend != 0
GROUP BY
    ad_date,
    campaign_id
ORDER BY 
    ad_date;
