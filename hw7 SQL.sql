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
), ads_monthly as (
    select 
        date_trunc('month', ai.ad_date) as ad_month,
        case 
            when lower(substring(ai.url_parameters, 'utm_campaign=([^&]*)')) = 'nan' then null
            else lower(substring(ai.url_parameters, 'utm_campaign=([^&]*)'))
        end as utm_campaign,
        sum(ai.spend) as ttl_spend,
        sum(ai.impressions) as ttl_impressions,
        sum(ai.clicks) as ttl_clicks,
        sum(ai.value) as ttl_value,
        round(
            case 
                when sum(ai.impressions) = 0 then 0
                else (sum(ai.clicks)::numeric / sum(ai.impressions)::numeric * 100)
            end, 2
        ) as ctr,
        round(
            case 
                when sum(ai.clicks) = 0 then 0
                else (sum(ai.spend)::numeric / sum(ai.clicks)::numeric)
            end, 2
        ) as cpc,
        round(
            case 
                when sum(ai.impressions) = 0 then 0
                else (sum(ai.spend)::numeric / sum(ai.impressions)::numeric * 1000)
            end, 2
        ) as cpm,
        round(
            case 
                when sum(ai.spend) = 0 then 0
                else ((sum(ai.value) - sum(ai.spend))::numeric / sum(ai.spend) * 100)
            end, 2
        ) as romi
    from 
        ads_info ai
    group by 
        ad_month,
        utm_campaign
)
select 
    ad_month,
    utm_campaign,
    ttl_spend,
    ttl_impressions,
    ttl_clicks,
    ttl_value,
    ctr,
    cpc,
    cpm,
    romi,
    round(
        ((cpm - lag(cpm) over (partition by utm_campaign order by ad_month)) / 
         nullif(lag(cpm) over (partition by utm_campaign order by ad_month), 0)) * 100, 2
    ) as cpm_diff_pct,
    round(
        ((ctr - lag(ctr) over (partition by utm_campaign order by ad_month)) / 
         nullif(lag(ctr) over (partition by utm_campaign order by ad_month), 0)) * 100, 2
    ) as ctr_diff_pct,
    round(
        ((romi - lag(romi) over (partition by utm_campaign order by ad_month)) / 
         nullif(lag(romi) over (partition by utm_campaign order by ad_month), 0)) * 100, 2
    ) as romi_diff_pct
from 
    ads_monthly
order by 
    ad_month, 
    utm_campaign;
