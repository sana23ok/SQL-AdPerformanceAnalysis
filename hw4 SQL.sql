with fb_info as (
	select
		fabd.ad_date,
		fc.campaign_name,
		fa.adset_name, 
		fabd.spend, 
		fabd.impressions,
		fabd.reach,
		fabd.clicks,
		fabd.leads, 
		fabd.value 
	from
		facebook_ads_basic_daily fabd
	left join
		facebook_adset fa
	on 
		fabd.adset_id = fa.adset_id
	left join 
		facebook_campaign fc
	on 
		fabd.campaign_id = fc.campaign_id
),
ads_info as(
    select 
        fb.ad_date,
        'Facebook ads' as media_source,
        fb.campaign_name,
        fb.adset_name,
        fb.spend,
        fb.impressions,
        fb.clicks,
        fb.value
    from 
        fb_info as fb

    union all

    select 
        ga.ad_date,
        'Google ads' as media_source,
        ga.campaign_name,
        ga.adset_name,
        ga.spend,
        ga.impressions,
        ga.clicks,
        ga.value
    from 
        google_ads_basic_daily as ga
)
select 
	ai.ad_date,
	ai.media_source, 
	ai.campaign_name, 
	ai.adset_name, 
	sum(spend) as ttl_spend,
    sum(impressions) as ttl_impressions,
    sum(clicks) as ttl_clicks,
    sum(value) as ttl_conversion_val
from 
    ads_info ai
group by 
    ad_date,
    media_source,
    campaign_name,
    adset_name
order by 
    ad_date;
   
   
--Опис додаткового завдання:
--
--1. Обʼєднавши дані з чотирьох таблиць, визнач кампанію з найвищим ROMI 
--серед усіх кампаній з загальною сумою витрат більше 500 000. 
--
--2. В цій кампанії визнач групу оголошень (adset_name) з найвищим ROMI.

   
   
WITH fb_info AS (
    SELECT
        fabd.ad_date,
        fc.campaign_id,
        fc.campaign_name,
        fa.adset_name, 
        fabd.spend, 
        fabd.impressions,
        fabd.clicks,
        fabd.value 
    FROM
        facebook_ads_basic_daily fabd
    LEFT JOIN
        facebook_adset fa ON fabd.adset_id = fa.adset_id
    LEFT JOIN 
        facebook_campaign fc ON fabd.campaign_id = fc.campaign_id
),
ads_info AS (
    SELECT 
        fb.campaign_id,
        fb.campaign_name,
        fb.adset_name,
        SUM(fb.spend) AS ttl_spend,
        SUM(fb.impressions) AS ttl_impressions,
        SUM(fb.clicks) AS ttl_clicks,
        SUM(fb.value) AS ttl_conversion_val,
        ROUND(((SUM(fb.value) - SUM(fb.spend))::numeric / SUM(fb.spend)) * 100, 2) AS ROMI
    FROM 
        fb_info AS fb
    GROUP BY
        fb.campaign_id,
        fb.campaign_name,
        fb.adset_name

    UNION ALL

    SELECT 
        ga.campaign_id,
        ga.campaign_name,
        ga.adset_name,
        SUM(ga.spend) AS ttl_spend,
        SUM(ga.impressions) AS ttl_impressions,
        SUM(ga.clicks) AS ttl_clicks,
        SUM(ga.value) AS ttl_conversion_val,
        ROUND(((SUM(ga.value) - SUM(ga.spend))::numeric / SUM(ga.spend)) * 100, 2) AS ROMI
    FROM 
        google_ads_basic_daily AS ga
    GROUP BY
        ga.campaign_id,
        ga.campaign_name,
        ga.adset_name
),
campaign_with_highest_romi AS (
    SELECT 
        campaign_id,
        campaign_name,
        MAX(ROMI) AS max_romi
    FROM 
        ads_info
    WHERE 
        ttl_spend > 500000
    GROUP BY 
        campaign_id,
        campaign_name
    ORDER BY 
        max_romi DESC
    LIMIT 1
)
SELECT 
    ai.adset_name,
    ai.ROMI
FROM 
    ads_info ai
JOIN 
    campaign_with_highest_romi cwr ON ai.campaign_id = cwr.campaign_id
ORDER BY 
    ai.ROMI DESC
LIMIT 1;


