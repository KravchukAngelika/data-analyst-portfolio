-- 1) Таблица с дублями для паттерна 3
CREATE TABLE users_dup (id SERIAL PRIMARY KEY, email TEXT, name TEXT, created_at DATE);
INSERT INTO users_dup (email, name, created_at) VALUES
('a@mail.com','Anna','2026-01-10'),('a@mail.com','Anna K','2026-03-05'),
('b@mail.com','Boris','2026-02-01'),
('c@mail.com','Clara','2026-01-20'),('c@mail.com','Clara','2026-01-20'),('c@mail.com','Clara M','2026-04-01'),
('d@mail.com','Denis','2026-02-14'),('d@mail.com','Denis','2026-02-15');

-- 2) Помесячная выручка за два года для паттерна 4
CREATE TABLE monthly_sales AS
SELECT (DATE '2025-01-01' + (i * INTERVAL '1 month'))::date AS month,
       1000 + (i * 137 % 300) + i * 20 AS revenue
FROM generate_series(0, 23) AS i;

-- Топ-N (паттерн 1)
--Задание 1 - Топ-3 самых длинных фильма в каждой категории (ROW_NUMBER)
with ranked as (
	select c.name, f.title, f.length,
		row_number() over(partition by c.name order by f.length desc, f.film_id) as rn  
	from film f
	join film_category fc on f.film_id = fc.film_id 
	join category c on fc.category_id = c.category_id )
select name, title, length, rn  
from ranked
where rn <=3;
--Задание 2 - То же через RANK
with ranked as (
	select c.name, f.title, f.length,
		rank() over(partition by c.name order by f.length desc) as rnk
	from film f
	join film_category fc on f.film_id = fc.film_id 
	join category c on fc.category_id = c.category_id )
select name, title, length, rnk 
from ranked
where rnk <=3;
--Задание 3 - То же через DENSE_RANK
with ranked as (
	select c.name, f.title, f.length,
		dense_rank() over(partition by c.name order by f.length desc) as drnk
	from film f
	join film_category fc on f.film_id = fc.film_id 
	join category c on fc.category_id = c.category_id )
select name, title, length, drnk 
from ranked
where drnk <=3;
--Задание 4 - Топ-3 клиента по сумме в каждой стране
with customer_total as (
	select c.customer_id, c.first_name , c.last_name , co.country, 
		sum(p.amount) as total
	from customer c
	join address a on c.address_id = a.address_id
	join city ci on a.city_id = ci.city_id 
	join country co on ci.country_id = co.country_id
	join payment p on c.customer_id = p.customer_id 
	group by c.customer_id, c.first_name , c.last_name , co.country),
ranked as (
	select country, first_name, last_name, total,
		row_number() over(partition by country order by total desc, customer_id) as rn
	from customer_total )
select country, first_name, last_name, total, rn  
from ranked 
where rn<=3;
--Задание 5 - Три крупнейших платежа каждого клиента
with ranked as (
	select customer_id, payment_date, amount, 
		row_number() over(partition by customer_id order by amount desc, payment_id) as rn  
	from payment)
select *
from ranked 
where rn <= 3;
--Задание 6 - Один лучший фильм в категории — ROW_NUMBER vs DISTINCT ON
with ranked as (
	select c.name, f.title, f.length,
		row_number() over(partition by c.name order by f.length desc, f.film_id) as rn  
	from film f
	join film_category fc on f.film_id = fc.film_id 
	join category c on fc.category_id = c.category_id )
select name, title, length, rn  
from ranked
where rn =1;
select distinct on(c.name) c.name, f.title, f.length 
from film f
join film_category fc on f.film_id = fc.film_id 
join category c on fc.category_id = c.category_id
order by c.name, f.length desc, f.film_id;
-- Первый и последний (паттерн 2)
--Задание 7 - Первый и последний платёж клиента (способ A)
with x as (
	select customer_id, payment_date, amount,
		row_number() over(partition by customer_id order by payment_date, payment_id) as rn_first,
		row_number() over(partition by customer_id order by payment_date desc, payment_id desc) as rn_last
	from payment)
select customer_id, 
	max(amount) filter(where rn_first = 1) as first_amount,
	max(payment_date) filter(where rn_first = 1) as first_date,
	max(amount) filter(where rn_last = 1) as last_amount,
	max(payment_date) filter(where rn_last = 1) as last_date
from x 
group by customer_id ;
--Задание 8 - Первый, последний + количество дней + метка
with x as (
	select customer_id, payment_date, amount,
		row_number() over(partition by customer_id order by payment_date, payment_id) as rn_first,
		row_number() over(partition by customer_id order by payment_date desc, payment_id desc) as rn_last,
		count(*) over(partition by customer_id) as payments_cnt
	from payment)
select customer_id, 
	max(amount) filter(where rn_first = 1) as first_amount,
	max(payment_date) filter(where rn_first = 1) as first_date,
	max(amount) filter(where rn_last = 1) as last_amount,
	max(payment_date) filter(where rn_last = 1) as last_date, 
	max(payment_date::date) filter(where rn_last = 1) - max(payment_date::date) filter(where rn_first = 1) as diff,
	max(payments_cnt) as total_payments,
	case 
		when max(payments_cnt) > 1 then 'вернулся'
		else 'разовый'
	end as status
from x 
group by customer_id ;
--Задание 9 -  Клиенты, у которых последний платёж больше первого
with x as (
	select customer_id, payment_date, amount,
		row_number() over(partition by customer_id order by payment_date, payment_id) as rn_first,
		row_number() over(partition by customer_id order by payment_date desc, payment_id desc) as rn_last
	from payment),
first_last as (
	select customer_id, 
	max(amount) filter(where rn_first = 1) as first_amount,
	max(amount) filter(where rn_last = 1) as last_amount
	from x
	group by customer_id )
select customer_id, first_amount, last_amount
from first_last 
where last_amount > first_amount;
-- Дедупликация (паттерн 3)
--Задание 10 - Email с дублями
select email, count(*) as cnt
from users_dup 
group by email
having count(*) > 1;
--Задание 11 - Самая свежая запись на email
with ranked as (
	select id, email, name, created_at,
		row_number() over(partition by email order by created_at desc, id desc) as rn 
	from users_dup)
select * from ranked 
where rn = 1;
--Задание 12 - Самая ранняя запись на email
with ranked as (
	select id, email, name, created_at,
		row_number() over(partition by email order by created_at, id) as rn 
	from users_dup)
select * from ranked 
where rn = 1;
--Задание 13 - Удалить дубли (в транзакции)
begin;
select id, email, created_at,
	row_number() over(partition by email order by created_at desc, id desc) as rn  
from users_dup
where id in (
	select id from (
		select id, row_number() over(partition by email order by created_at desc, id desc) as rn
		from users_dup) t where rn > 1);
delete from users_dup 
where id in (
	select id from (
		select id, row_number() over(partition by email order by created_at desc, id desc) as rn
		from users_dup) t where rn > 1);
select * from users_dup order by email;
rollback;
--Задание 14 - Дубли с разным регистром
INSERT INTO users_dup (email, name, created_at) VALUES
('A@Mail.com', 'Anna New', '2026-05-01'),
(' a@mail.com ', 'Anna Space', '2026-05-02');
with normalized as (
	select id, email, name, created_at,
		lower(trim(email)) as norm_email,
		row_number() over(partition by lower(trim(email)) order by created_at desc, id desc) as rn 
	from users_dup)
select id, email, name, created_at, rn  
from normalized
order by norm_email, rn;
--Периоды (паттерн 4)
--Задание 15 - MoM (Month-over-Month)
select month, revenue,
	lag(revenue) over(order by month) as prev_month,
	revenue - lag(revenue) over(order by month) as diff,
	round(100.0 * (revenue - lag(revenue) over(order by month)) / nullif(lag(revenue) over(order by month), 0), 2) as mom_pct
from monthly_sales;
--Задание 16 - YoY (Year-over-Year)
select month, revenue,
	lag(revenue, 12) over(order by month) as month_last_year,
	revenue - lag(revenue, 12) over(order by month) as diff,
	round(100.0 * (revenue - lag(revenue, 12) over(order by month)) / nullif(lag(revenue, 12) over(order by month), 0), 2) as yoy_pct
from monthly_sales;
--Задание 17 - Удалить месяц и починить YoY
delete from monthly_sales where month = '2025-06-01';
select month, revenue,
	lag(revenue, 12) over(order by month) as broken_prev
from monthly_sales;
select a.month, a.revenue, b.revenue as month_last_year
from monthly_sales a
left join monthly_sales b on b.month = a.month - interval '1 year';
--Задание 18 - YTD (Year-to-Date)
select month, revenue, 
	sum(revenue) over(partition by date_trunc('year', month) order by month) ytd_revenue
from monthly_sales ;