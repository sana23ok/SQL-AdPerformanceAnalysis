--Підключись до бази даних, використовуючи отриманi доступи.
--Знайди таблицю facebook_ads_basic_daily та ознайомся з її колонками.
--Напиши SQL запит, що вибере поля ad_date, spend, clicks, а також співвідношення spend/clicks.
--До запиту додай умову, що кількість кліків має бути більшою за нуль.
--Відсортуй результуючу таблицю за полем ad_date за спаданням.
--Завантаж SQL файл з отриманим запитом у форму здачі домашнього завдання.

select 
	ad_date, 
	spend,
	clicks,
	spend / clicks as spend_to_clicks
from 
	facebook_ads_basic_daily
where clicks > 0
order by ad_date desc;

