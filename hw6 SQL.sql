with ads_info as(
	select 
		fabd.ad_date ,
		fabd.url_parameters ,
		coalesce (fabd.spend, 0) as spend ,
		coalesce (fabd.impressions, 0) as impressions ,
		coalesce (fabd.reach, 0) as reach ,
		coalesce (fabd.clicks, 0) as clicks ,
		coalesce (fabd.leads, 0) as leads ,
		coalesce (fabd.value, 0) as value
	from 
		facebook_ads_basic_daily fabd
	left join 
		facebook_adset fa using(adset_id)
	left join 
		facebook_campaign fc using(campaign_id)
		
	union all
	
	select 
		gabl.ad_date ,
		gabl.url_parameters ,
		coalesce (gabl.spend, 0) as spend ,
		coalesce (gabl.impressions, 0) as impressions ,
		coalesce (gabl.reach, 0) as reach ,
		coalesce (gabl.clicks, 0) as clicks ,
		coalesce (gabl.leads, 0) as leads ,
		coalesce (gabl.value, 0) as value
	from 
		google_ads_basic_daily gabl
)
select 
	ai.ad_date,
	case 
        when lower(substring(url_parameters, 'utm_campaign=([^&]*)')) = 'nan' then null
        else lower(substring(url_parameters, 'utm_campaign=([^&]*)'))
   	end utm_campaign,
   	sum(ai.spend) as ttl_spend,
   	sum(ai.impressions) as ttl_impressions,
   	sum(ai.clicks) as ttl_clicks,
	sum(ai.value) as ttl_value,
   	round(
   		case 
   			when sum(impressions)::numeric = 0 then 0
   			else sum(clicks)::numeric / sum(impressions)::numeric * 100
   		end, 2
   	) as ctr,
	round(
		case 
			when sum(clicks)::numeric = 0 then 0
			else sum(spend)::numeric / sum(clicks)::numeric
		end, 2
	) as cpc,
	round(
		case 
			when sum(impressions)::numeric = 0 then 0
			else sum(spend)::numeric / sum(impressions)::numeric * 1000
		end, 2
	) as cpm,
	round(
		case 
			when sum(spend) = 0 then 0
			else ((sum(value) - sum(spend))::numeric / sum(spend)) * 100
		end, 2
	) as romi
from 
	ads_info ai
group by 
	ai.ad_date,
	utm_campaign;
	
	