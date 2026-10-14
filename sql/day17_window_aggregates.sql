CREATE OR REPLACE VIEW daily_revenue AS
SELECT payment_date::date AS day,
       SUM(amount)        AS revenue,
       COUNT(*)           AS payments_cnt
FROM payment
GROUP BY payment_date::date;
--Задание 1 - Сумма по клиенту и доля
select customer_id, payment_id, amount,
       sum(amount) over (partition by customer_id) as customer_total,
       round(100.0 * amount / sum(amount) over (partition by customer_id), 2) as pct_of_customer
from payment
order by customer_id, payment_id
limit 30;
--Задание 2 -  Общая выручка и доля
select payment_id, amount,
	sum(amount) over() as total_revenue,
	round(100.0 * amount / sum(amount) over()) as pct_of_total
from payment;
--Задание 3 -  Нарастающий итог по клиенту
select customer_id, payment_date, amount,
	sum(amount) over(partition by customer_id order by payment_date, payment_id rows between unbounded preceding and current row) as running_total 
from payment;
--Задание 4 -  Нарастающая выручка по дням
select day, revenue,
	sum(revenue) over(order by day) as runnig_total
from daily_revenue;
--Задание 5 -  Нарастающий итог с обнулением в начале месяца
select day, revenue,
	sum(revenue) over(partition by date_trunc('month', day) order by day) as runnig_total
from daily_revenue;
--Задание 6 - Скользящее среднее за 3 дня
select day, revenue,
	round(avg(revenue) over(order by day rows between 2 preceding and current row), 2) as ma_3
from daily_revenue;
--Задание 7 - Скользящее среднее только для полного окна
select day, revenue,
	case 
		when count(*) over(order by day rows between 2 preceding and current row) = 3
		then round(avg(revenue) over(order by day rows between 2 preceding and current row), 2)
	end as ma_3_full
from daily_revenue;
--Задание 8 - Скользящее среднее за 7 дней — ROWS vs RANGE
select day, revenue,
	round(avg(revenue) over(order by day rows between 6 preceding and current row), 2) as ma_7_rows,
	round(avg(revenue) over(order by day range between interval '6 days' preceding and current row), 2) as ma_7_range
from daily_revenue;
--Задание 9 - Отклонение от средней
select day, revenue,
	round(avg(revenue) over(), 2) as total_avg,
	round(revenue - avg(revenue) over(), 2) as diff,
	case 
		when revenue > avg(revenue) over() then 'выше среднего'
		else 'ниже среднего'
	end as category
from daily_revenue;
--Задание 10 - Дни-рекорды
with with_max as (
	select day, revenue,
		max(revenue) over(order by day) as running_max
	from daily_revenue)
select *
from with_max 
where revenue = running_max;
--Задание 11 - Платежи выше среднего по клиенту
with with_avg as (
	select customer_id, payment_date, amount,
		avg(amount) over(partition by customer_id) as avg_customer
	from payment)
select customer_id, count(*)
from with_avg 
where amount>avg_customer
group by customer_id;
--Задание 12 - ABC-анализ клиентов
with customer_totals as (
	select customer_id,
		sum(amount) as total
	from payment 
	group by customer_id),
pct_calc as (
	select customer_id, total,
	round(100.0 * total/sum(total) over(), 4) as pct,
	round(100.0 * sum(total) over(order by total desc, customer_id)/sum(total) over(), 4) as cum_pct
	from customer_totals),
group_calc as (
	select customer_id, total, pct, cum_pct,
	case 
		when cum_pct<=80 then 'A'
		when cum_pct<=95 then 'B'
		else 'C'
	end as abc_group
	from pct_calc )
select abc_group,
	COUNT(*) as customer_count,
	sum(total) as group_revenue,
	round(100.0 * sum(total)/(select sum(amount) from payment),2) as pct_of_revenue  
from group_calc 
group by abc_group; 
--Задание 13 - Накопленная доля категорий
with category_revenue as (
	select c.name, 
		sum(p.amount) as revenue
	from payment p
	join rental r on p.rental_id = r.rental_id
	join inventory i on r.inventory_id = i.inventory_id
	join film f on i.film_id = f.film_id
	join film_category fc on f.film_id = fc.film_id
	join category c on fc.category_id = c.category_id
	group by c.name)
select name, revenue,
	round(100.0 * revenue/sum(revenue) over(), 2) as pct_of_total,
	round(100.0 * sum(revenue) over(order by revenue desc, name)/sum(revenue) over(),2) as cum_pct
from category_revenue
order by revenue desc;
--Задание 14 -  Сумма и среднее за 3 последних платежа
select customer_id, payment_date, amount,
	sum(amount) over(partition by customer_id order by payment_date, payment_id rows between 2 preceding and current row) as sum_3,
	round(avg(amount) over(partition by customer_id order by payment_date, payment_id rows between 2 preceding and current row),2) as avg_3
from payment;
--Задание 15 - FILTER — нарастающее число платежей >5
select customer_id, payment_date, amount,
	count(*) filter (where amount>5) over(partition by customer_id order by payment_date, payment_id) as running_count
from payment;
--Задание 16 -  Три способа «сумма по клиенту»
select customer_id, payment_id, amount,
	sum(amount) over(partition by customer_id) as cum_sum, 
	(select sum(amount) from payment p2 where p2.customer_id = p.customer_id) as cum_sum2
from payment p;
-- Способ 3: JOIN с агрегированным CTE
with totals as (
	select customer_id, sum(amount) as cum_sum
	from payment 
	group by customer_id)
select p.customer_id, p.payment_id, p.amount, t.cum_sum
from payment p
join totals t on p.customer_id = t.customer_id;
--Задание 17 - Нарастающий итог без ORDER BY (ловушка)
select customer_id, payment_date, amount,
	sum(amount) over(partition by customer_id) as not_running
from payment;
--Задание 18 - День с максимальной выручкой в каждом месяце
with monthly_daily as (
	select date_trunc('month', day) as month, day, revenue
	from daily_revenue),
ranked as (
	select month, day, revenue,
		row_number() over(partition by month order by revenue desc, day) as rn
	from monthly_daily),
running as (
	select month, day, revenue,
		sum(revenue) over(partition by month order by day) as running_total
	from monthly_daily)
select r.month, r.day as max_day, r.revenue,
	ru.running_total
from ranked r
join running ru on r.month = ru.month and r.day = ru.day
where r.rn = 1;