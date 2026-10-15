CREATE OR REPLACE VIEW customer_totals AS
SELECT c.customer_id, c.first_name, c.last_name,
       SUM(p.amount) AS total,
       COUNT(*)      AS payments_cnt,
       MAX(p.payment_date::date) AS last_payment_day
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;

--Задание 1 - Квартили клиентов по сумме
with q as (
	select customer_id, total, 
		ntile(4) over(order by total desc) as quartile
	from customer_totals)
select quartile, count(*) as cnt,
	min(total) as min_total, max(total) as max_total
from q
group by quartile;
--Задание 2 -  Децили клиентов
with d as (
	select customer_id, total, 
		ntile(10) over(order by total desc) as decile
	from customer_totals)
select decile, count(*) as cnt,
	min(total) as min_total, max(total) as max_total
from d
group by decile
order by decile;
--Задание 3 -  Сегментация по сумме и частоте
with seg as (
	select customer_id,
		ntile(3) over(order by total desc) as total_seg,
		ntile(3) over(order by payments_cnt desc) as freq_seg
	from customer_totals)
select total_seg, freq_seg, count(*) as customer_cnt
from seg 
group by total_seg, freq_seg
order by total_seg, freq_seg;
--Задание 4 -  PERCENT_RANK и CUME_DIST по сумме
with ranked as (
	select customer_id,
		percent_rank() over(order by total) as pct_rank,
		cume_dist() over(order by total) as cume_dist
	from customer_totals)
select customer_id, pct_rank, cume_dist 
from ranked 
where pct_rank = 0 or pct_rank = 1;
--Задание 5 -  Проверка формул вручную
select v, rank() over (order by v), 
	percent_rank() over (order by v), 
	cume_dist() over (order by v)
from (values (10),(20),(20),(30),(40)) t(v);
--Задание 6 - Топ-10% клиентов через CUME_DIST
with ranked as (
	select customer_id, total,
		cume_dist() over(order by total desc) as cum_dist
	from customer_totals)
select *
from ranked 
where cum_dist <= 0.1
order by total desc;
--Задание 7 - Топ-10% через PERCENTILE_CONT
with ranked as (
	select percentile_cont(0.9) within group(order by total) as p90
	from customer_totals)
select c.customer_id, c.total 
from customer_totals c, ranked r
where c.total >= r.p90 
order by c.total desc;
--Задание 8 - Все метрики одним запросом
select round(avg(total), 2) as avg_total,
	round(percentile_cont(0.5) within group(order by total)::numeric, 2) as median,
	mode() within group(order by total) as mode,
	round(percentile_cont(0.25) within group(order by total)::numeric, 2) as p25,
	round(percentile_cont(0.75) within group(order by total)::numeric, 2) as p75,
	round(percentile_cont(0.90) within group(order by total)::numeric, 2) as p90,
	round(percentile_cont(0.95) within group(order by total)::numeric, 2) as p95
from customer_totals;
--Задание 9 - Медиана платежа по рейтингу фильма
with payment_by_rating as (
	select f.rating, p.amount
	from payment p
	join rental r on p.rental_id = r.rental_id 
	join inventory i on r.inventory_id = i.inventory_id 
	join film f on i.film_id = f.film_id )
select rating, 
	round(avg(amount), 2) as mean,
	round(percentile_cont(0.5) within group(order by amount)::numeric, 2) as median,
	round(avg(amount) - percentile_cont(0.5) within group(order by amount)::numeric,2) as diff
from payment_by_rating  
group by rating;
--Задание 10 - Медиана длины фильма по категориям — CONT vs DISC
with film_length as (
	select f.title, c.name, f.length
	from film f
	join film_category fc on f.film_id = fc.film_id
	join category c on fc.category_id = c.category_id )
select name, 
	PERCENTILE_CONT(0.5) within group(order by length)::numeric as median_cont,
	PERCENTILE_DISC(0.5) within group(order by length) as median_disk
from film_length
group by name;
--Задание 11 -  Выбросы по IQR
with q as (
	select PERCENTILE_CONT(0.25) within group(order by total)::numeric as q1,
		PERCENTILE_CONT(0.75) within group(order by total)::numeric as q3
	from customer_totals ),
bounds as (
	select q1, q3, q3-q1 as iqr,
		q1 - 1.5*(q3-q1) as lower_bound,
		q3 + 1.5*(q3-q1) as upper_bound
	from q )
select c.customer_id, c.total,
	case 
		when c.total > b.upper_bound then 'выше верхней границы'
		when c.total < b.lower_bound then 'ниже нижней границы'
	end as outlier_type
from customer_totals c, bounds b
where c.total>b.upper_bound or c.total<b.lower_bound 
order by c.total desc;
--Задание 12 - Медиана рядом с каждой строкой
with stats as (
	select PERCENTILE_CONT(0.5) within group(order by total)::numeric as median_total
	from customer_totals )
select c.customer_id, c.total, s.median_total,
	round(c.total - s.median_total, 2) as diff
from customer_totals c
cross join stats s
order by c.total desc;
--Задание 13 - Медиана по стране
with customer_country as (
	select c.customer_id, co.country, ct.total
	from customer c
	join address a on c.address_id = a.address_id 
	join city ci on a.city_id = ci.city_id 
	join country co on ci.country_id = co.country_id 
	join customer_totals ct on c.customer_id = ct.customer_id ),
country_median as (
	select country,
		PERCENTILE_CONT(0.5) within group(order by total)::numeric as median_total
	from customer_country 
	group by country)
select cc.customer_id, cc.total, cm.median_total,
	case 
		when cc.total > cm.median_total then 'выше медианы страны'
		when cc.total < cm.median_total then 'ниже медианы страны'
		else 'равно медиане страны'
	end as position
from customer_country cc
join country_median cm on cc.country = cm.country ;
--Задание 14 -  Ловушка NTILE с ничьими
with q as (
	select customer_id, total,
		ntile(4) over(order by total desc) as quartile
	from customer_totals )
select a.customer_id, a.total, a.quartile,
	 b.customer_id, b.total, b.quartile
from q a
join q b on a.total = b.total and a.customer_id < b.customer_id 
where a.quartile <> b.quartile ;
--Задание 15 - Сегментация по порогам
with p as (
	select PERCENTILE_CONT(0.25) within group(order by total)::numeric as p25,
		PERCENTILE_CONT(0.50) within group(order by total)::numeric as p50,
		PERCENTILE_CONT(0.75) within group(order by total)::numeric as p75
		from customer_totals )
select case 
	when c.total > p.p75 then 'топ-25%'
	when c.total > p.p50 then 'выше среднего'
	when c.total > p.p25 then 'ниже среднего'
	else 'отстающие'
end as segment,
	count(*) as cnt
from customer_totals c, p p
group by case 
	when c.total > p.p75 then 'топ-25%'
	when c.total > p.p50 then 'выше среднего'
	when c.total > p.p25 then 'ниже среднего'
	else 'отстающие'
end;
--Задание 16 - RFM-сегментация
with max_date as (
	select max(payment_date::date) as max_d from payment),
rfm_base as (
	select ct.customer_id, ct.total, ct.payments_cnt,
		(select max_d from max_date) - ct.last_payment_day as recency_days
	from customer_totals ct ),
rfm_scores as (
	select customer_id, total, payments_cnt, recency_days,
		ntile(3) over(order by recency_days asc) as r_score,
		ntile(3) over(order by payments_cnt desc) as f_score,
		ntile(3) over(order by total desc) as m_score
	from rfm_base)
select customer_id , total, payments_cnt, recency_days,
	r_score || '-' || f_score || '-' || m_score as rfm_code
from rfm_scores 
order by r_score desc, f_score desc, m_score desc;
--Задание 17 - Накопленная доля выручки по децилям
with d as (
	select customer_id, total, 
		ntile(10) over(order by total desc) as decile
	from customer_totals),
decile_stats as (
	select decile, count(*) as cnt, sum(total) as revenue
	from d 
	group by decile)
select decile, cnt, revenue,
	round(100.0 * sum(revenue) over(order by decile) / sum(revenue) over(), 2) as cum_pct
from decile_stats ;
--Задание 18 - Вторая по величине медиана среди категорий
with category_median as (
	select c.name, 
		PERCENTILE_CONT(0.5) within group(order by f.length)::numeric as median_length
	from film f
	join film_category fc on f.film_id = fc.film_id
	join category c on fc.category_id = c.category_id 
	group by c.name),
ranked as (
	select name, median_length,
		dense_rank() over(order by median_length desc) as drnk
	from category_median )
select name, median_length
from ranked 
where drnk = 2;





	