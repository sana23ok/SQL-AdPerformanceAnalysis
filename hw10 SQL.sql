--Завдання 1. Підготовка даних для побудови звітів у BI системах

SELECT 
  timestamp_micros(event_timestamp) as event_dttm,
  user_pseudo_id, 
  (select value.int_value from ge.event_params where key = 'ga_session_id') as session_id,
  event_name,
  geo.country as country,
  device.category as category,
  traffic_source.source as sourse,
  traffic_source.medium as medium,
  traffic_source.name as campaign
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` as ge
where EXTRACT(YEAR FROM TIMESTAMP_MICROS(event_timestamp)) = 2021
and  event_name in(
  'session_start',
  'view_item',
  'add_to_cart',
  'begin_checkout',
  'add_shipping_info',
  'add_payment_info',
  'purchase'
);


-- Завдання 2. Розрахунок конверсій в розрізі дат та каналів трафіку

WITH session_data AS (
  SELECT
    DATE(TIMESTAMP_MICROS(event_timestamp)) AS event_date,
    user_pseudo_id,
    (select value.int_value from ge.event_params where key = 'ga_session_id') as session_id,
    traffic_source.source AS source,
    traffic_source.medium AS medium,
    traffic_source.name AS campaign,
    event_name
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` as ge
  WHERE
    event_name IN ('session_start', 'add_to_cart', 'begin_checkout', 'purchase')
), 
session_metrics as(
  SELECT
    event_date,
    source,
    medium,
    campaign,
    COUNT(DISTINCT CONCAT(user_pseudo_id, session_id)) AS unique_sessions,
    COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN CONCAT(user_pseudo_id, session_id) END) AS add_to_cart_count,
    COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout' THEN CONCAT(user_pseudo_id, session_id) END) AS checkout_count,
    COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN CONCAT(user_pseudo_id, session_id) END) AS purchase_count
  FROM
    session_data
  GROUP BY
    event_date, source, medium, campaign
)select 
  event_date,
  source,
  medium,
  campaign,
  unique_sessions as user_sessions_count,
  round(add_to_cart_count/unique_sessions, 2) as visit_to_cart,
  round(checkout_count/unique_sessions, 2) as visit_to_checkout,
  round(purchase_count/unique_sessions, 2) as visit_to_purchase
FROM
  session_metrics
ORDER BY
  event_date, source, medium, campaign;


-- Завдання 3. Порівняння конверсії між різними посадковими сторінками

with sessions_events as (
  select
    timestamp_micros(event_timestamp) event_dttm
    ,user_pseudo_id || (select value.int_value from ge.event_params where key = 'ga_session_id') user_session_id
    ,event_name
    ,regexp_extract(
      (select value.string_value from ge.event_params where key = 'page_location'),
      r'(?:\w+\:\/\/)?[^\/]+\/([^\?#]*)') as page_path
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` ge
  where EXTRACT(YEAR FROM TIMESTAMP_MICROS(event_timestamp)) = 2020
),
sessions_w_start as (
select
  user_session_id
  ,max(case when event_name = 'session_start' then page_path end) start_page
  ,case when sum(case when event_name = 'session_start' then 1 end) > 0 then 1 else 0 end as has_start
  ,case when sum(case when event_name = 'purchase' then 1 end) > 0 then 1 else 0 end as has_purchase
from sessions_events
group by user_session_id
)
select 
  start_page
  ,count(*) sessions_cnt
  ,sum(has_purchase) sales_cnt
  ,case when sum(has_start) > 0 then
  1.00 * sum(has_purchase) / sum(has_start) 
  end conversion
from sessions_w_start
group by start_page;


-- Завдання 4. Перевірка кореляції між залученістю користувачів та здійсненням покупок

WITH session_data AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM ge.event_params WHERE key = 'ga_session_id') AS session_id,
    MAX(CASE WHEN (SELECT value.string_value FROM ge.event_params WHERE key = 'session_engaged') = '1' THEN 1 ELSE 0 END) AS engaged,
    SUM(CASE WHEN (SELECT key FROM ge.event_params WHERE key = 'engagement_time_msec') IS NOT NULL 
             THEN (SELECT value.int_value FROM ge.event_params WHERE key = 'engagement_time_msec') ELSE 0 END) AS total_engagement_time,
    MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS ge
  GROUP BY
    user_pseudo_id, session_id
)
SELECT 
  CORR(engaged, has_purchase) AS engagement_purchase_corr,
  CORR(total_engagement_time, has_purchase) AS time_purchase_corr
FROM 
  session_data;

