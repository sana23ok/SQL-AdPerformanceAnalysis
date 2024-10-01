with combined_ads as (
	select 
		ad_date,
		'Facebook Ads' as media_source,
		spend,
		impressions,
		reach, 
		clicks,
		leads,
		value
	from
		facebook_ads_basic_daily
		
	union all 
	
	select 
		ad_date,
		'Google Ads' as media_source,
		spend,
		impressions,
		reach, 
		clicks,
		leads,
		value
	from
		google_ads_basic_daily
)
select
	ad_date,
	media_source,
	sum(spend) as ttl_spend,
	sum(impressions) as ttl_impressions,
	sum(clicks) as ttl_clicks, 
	sum(value) as ttl_conversion_val
from
	combined_ads 
group by 
	ad_date,
	media_source
order by 
	ad_date;
	