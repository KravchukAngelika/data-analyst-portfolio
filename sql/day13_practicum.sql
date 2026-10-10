--Задание 1 - Выручка и количество аренд по месяцам и категориям
with totals as (
	select date_trunc('month', p.payment_date) as month,
	c.name as category,
	sum(p.amount) as total_sum,
	count(distinct r.rental_id) as film_count
	from payment p
	join rental r on p.rental_id = r.rental_id 
	join inventory i on r.inventory_id = i.inventory_id
	join film f on i.film_id = f.film_id 
	join film_category fc on f.film_id = fc.film_id 
	join category c on fc.category_id = c.category_id 
	group by month, c.name)
select month, category, total_sum, film_count
from totals ;
--Задание 2 - Клиенты без Horror, но с платежами выше среднего
with customer_horror as (
	select distinct r.customer_id
	from rental r
	join inventory i on r.inventory_id = i.inventory_id
	join film f on i.film_id = f.film_id 
	join film_category fc on f.film_id = fc.film_id 
	join category c on fc.category_id = c.category_id
	where c.name = 'Horror'),
customer_total as (
	select customer_id, sum(amount) as total
	from payment
	group by customer_id),
avg_sum as (
	select avg(total) as avg_s
	from customer_total)
select ct.customer_id, ct.total
from customer_total ct, avg_sum av
where ct.total>av.avg_s and ct.customer_id not in (select customer_id from customer_horror );
--Задание 3 - Полный профиль клиента с категорией
with sum_customer as (
	select customer_id, sum(amount) as total_sum,
	min(payment_date)::date as first_payment,
	max(payment_date)::date as last_payment
	from payment
	group by customer_id ),
rental_count as (
	select customer_id, count(*) as count_renta
	from rental
	group by customer_id )
select c.first_name, c.last_name, 
	coalesce(rc.count_renta,0) as count_renta, 
	coalesce(sc.total_sum, 0) as total_sum,
	sc.first_payment, sc.last_payment,
	case 
		when sc.total_sum > 150 then 'VIP'
		when sc.total_sum between 80 and 150 then 'regular'
		else 'low'
		end as customer_category
from customer c
left join sum_customer sc on c.customer_id = sc.customer_id 
left join rental_count rc on c.customer_id = rc.customer_id ;
--Задание 4 - Активность по городам с процентом
with customer_city as (
	select ci.city, c.customer_id
	from city ci
	join address a on ci.city_id = a.city_id 
	join customer c on a.address_id = c.address_id ),
active as (
	select distinct customer_id from payment)
select cc.city, count(*) as customer_count, 
	count(case when a.customer_id is not null then 1 end) as active_count,
	round(100.0 * count(case when a.customer_id is not null then 1 end)/nullif(count(*),0),1) as percent
from customer_city cc
left join active a on cc.customer_id = a.customer_id 
group by cc.city ;
--Задание 5 - Календарный отчёт (рекурсивный CTE)
with recursive dates as(
	select min(payment_date)::date as first_payment
	from payment
union all 
	select first_payment + 1 from dates 
	where first_payment<(select max(payment_date)::date from payment)),
daily as (
	select payment_date::date as d, count(*) as cnt 
	from payment 
	group by d )
select dates.first_payment, coalesce(daily.cnt, 0) as daily_count
from dates 
left join daily on dates.first_payment = daily.d ;