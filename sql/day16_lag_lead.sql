CREATE TABLE status_history (user_id INT, status TEXT, changed_at DATE);
INSERT INTO status_history VALUES
(1,'new','2026-01-01'),(1,'active','2026-01-15'),(1,'active','2026-02-10'),(1,'churned','2026-04-01'),
(2,'new','2026-02-01'),(2,'active','2026-02-20'),
(3,'new','2026-03-01'),(3,'new','2026-03-05'),(3,'active','2026-03-20');

--Задание 1 - Предыдущий платёж и разница
select customer_id, payment_date, amount, 
	lag(amount) over(partition by customer_id order by payment_date, payment_id) as prev_amount,
	amount - lag(amount) over(partition by customer_id order by payment_date, payment_id) as diff
from payment;
--Задание 2 - Следующий платёж. Сколько NULL?
with with_next as (
	select customer_id, payment_date, amount, 
		lead(amount) over(partition by customer_id order by payment_date, payment_id) as next_amount
	from payment)
select count(*) as null_count
from with_next 
where next_amount is null;
--Задание 3 - Дни с предыдущего платежа
select customer_id, payment_date, 
	lag(payment_date) over(partition by customer_id order by payment_date, payment_id)::date as prev_date,
	payment_date::date - lag(payment_date::date) over(partition by customer_id order by payment_date, payment_id)::date as days_since_prev
from payment;
--Задание 4 -  Клиенты с паузой >14 дней
with gaps as (
	select customer_id, payment_date,
		payment_date::date - lag(payment_date) over(partition by customer_id order by payment_date, payment_id)::date as diff
	from payment)
select customer_id, max(diff)
from gaps
where diff>14
group by customer_id ;
--Задание 5 -  Выручка по месяцам + предыдущий месяц
with monthly as (
	select date_trunc('month', payment_date) as month,
		sum(amount) as total 
	from payment
	group by month)
select *, lag(total) over(order by month) as prev_total
from monthly;
--Задание 6 - То же + изменение и процент
with monthly as (
	select date_trunc('month', payment_date) as month,
		sum(amount) as total 
	from payment
	group by month)
select *, lag(total) over(order by month) as prev_total,
	total - lag(total) over(order by month) as diff,
	round(100.0 * (total - lag(total) over(order by month))/nullif(lag(total) over(order by month), 0), 1) as growth
from monthly;
--Задание 7 - То же в одном запросе без CTE
select date_trunc('month', payment_date) as month,
	sum(amount) as total ,
	lag(sum(amount)) over(order by date_trunc('month', payment_date)) as prev_total
from payment
group by month;
--Задание 8 - Первый платёж клиента рядом с каждым
select customer_id, payment_date, amount,
	first_value(amount) over(partition by customer_id order by payment_date, payment_id) as first_payment,
	round(amount/nullif(first_value(amount) over(partition by customer_id order by payment_date, payment_id), 0), 2) as ratio_to_first
from payment;
--Задание 9 - Последний платёж двумя способами
--FIRST_VALUE с DESC
select customer_id, payment_date, amount,
	first_value(amount) over(partition by customer_id order by payment_date desc, payment_id desc) as last_payment
from payment;
--LAST_VALUE с расширенной рамкой
select customer_id, payment_date, amount,
	last_value(amount) over(partition by customer_id order by payment_date, payment_id rows between unbounded preceding and unbounded following) as last_payment
from payment;
--Задание 10 - LAST_VALUE без рамки (ловушка)
select customer_id, payment_date, amount,
	last_value(amount) over(partition by customer_id order by payment_date, payment_id) as last_payment
from payment;
--Задание 11 - NTH_VALUE(amount, 2) сумма второго платежа
select customer_id, payment_date, amount,
	nth_value(amount, 2) over(partition by customer_id order by payment_date, payment_id rows between unbounded preceding and unbounded following) as second_payment
from payment;
--Задание 12 - Изменение статуса
with with_prev as (
    select user_id, status, changed_at,
           lag(status) over (
               partition by user_id 
               order by changed_at
           ) as prev_status
    from status_history
)
select *
from with_prev
where status <> prev_status;
--Задание 13 - Дни до следующей смены
select user_id, changed_at,
	lead(changed_at) over(partition by user_id order by changed_at) as next_change,
	lead(changed_at) over(partition by user_id order by changed_at) - changed_at as days
from status_history ;
--Задание 14 - Рост три раза подряд
with with_lags as (
	select customer_id, payment_date, amount,
		lag(amount, 1) over(partition by customer_id order by payment_date, payment_id) as prev1,
		lag(amount, 2) over(partition by customer_id order by payment_date, payment_id) as prev2,
		lag(amount, 3) over(partition by customer_id order by payment_date, payment_id) as prev3
	from payment)
select distinct customer_id 
from with_lags
where amount >prev1 and amount >prev2 and amount >prev3;
--Задание 15 - Длительность фильма и предыдущего по алфавиту
select title, length,
	lag(length) over(order by title asc) as prev_film_length,
	length - lag(length) over(order by title asc) as diff
from film ;
--Задание 16 - Фильм и разница с самым длинным в категории
with ranked as (
	select c.name, f.title, f.length,
		row_number() over(partition by c.name order by f.length desc, f.film_id) as rn,
		first_value(f.length) over(partition by c.name order by f.length desc, f.film_id) as max_length
	from film f
	join film_category fc on f.film_id = fc.film_id
	join category c on fc.category_id = c.category_id)
select name, title, length, rn, 
	max_length - length as diff
from ranked;
--Задание 17 - Средняя пауза между платежами клиента
with gaps as (
	select customer_id,
		payment_date::date - lag(payment_date) over(
			partition by customer_id order by payment_date, payment_id)::date as days_since_prev
	from payment)
select customer_id,
	avg(days_since_prev) as avg_gap,
	max(days_since_prev) as max_gap,
	max(days_since_prev) - avg(days_since_prev) as irregularity
from gaps 
where days_since_prev is not null
group by customer_id;
--Задание 18 - Два платежа в один день
with with_next_date as (
	select customer_id, payment_date, 
		lead(payment_date) over(partition by customer_id order by payment_date, payment_id) as next_date
	from payment)
select customer_id, payment_date, count(*)
from with_next_date 
where payment_date = next_date 
group by customer_id , payment_date ;