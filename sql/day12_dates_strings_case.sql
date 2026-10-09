--Задание 1 - Сумма платежей по месяцам
select date_trunc('month', payment_date) as month, sum(amount)
from payment 
group by month;
--Задание 2 - Количество платежей по дням недели
select extract(dow from payment_date) as day_num, 
	case extract(dow from payment_date)
	when 0 then 'Воскресенье'
	when 1 then 'Понедельник'
	when 2 then 'Вторник'
	when 3 then 'Среда'
	when 4 then 'Четверг'
	when 5 then 'Пятница'
	when 6 then 'Суббота'
	end as day_name,
count(*)
from payment
group by day_num;
--Задание 3 - Дни между первым и последним платежом клиента
select customer_id, max(payment_date)::date - min(payment_date)::date as days_between
from payment 
group by customer_id;
--Задание 4 - Платежи за последние 30 дней от максимальной даты
select customer_id, amount, payment_date
from payment 
where payment_date>=(select max(payment_date) from payment)-interval '30 days';
--Задание 5 - Имя клиента и домен email
select first_name, last_name, split_part(email, '@', 2) as domain
from customer;
--Задание 6 - Клиенты без '@' в email
select customer_id, first_name, last_name, email 
from customer 
where email !~ '@';
--Задание 7 - Фильмы, начинающиеся на A–C
select title
from film 
where title ~ '^[A-C]';
--Задание 8 - Убрать цифры из названий фильмов
select title, regexp_replace(title, '[0-9]', '', 'g') as title_without_digits
from film ;
--Задание 9 - Категоризация фильмов по длительности
select  
	case
	when length<60 then 'short'
	when length>120 then 'long'
	else 'medium'
	end as cat_length,
	count(*)
from film 
group by cat_length;
--Задание 10 - Активные и неактивные клиенты одним запросом (условная агрегация)
select count(case when active = 1 then 1 end) as active,
count(case when active = 0 then 1 end) as inactive
from customer ;
--Задание 11 - Pivot — количество фильмов по рейтингам
select count(case when rating = 'G' then 1 end) as g_count,
count(case when rating = 'PG' then 1 end) as pg_count,
count(case when rating = 'PG-13' then 1 end) as pg13_count,
count(case when rating = 'R' then 1 end) as r_count,
count(case when rating = 'NC-17' then 1 end) as nc17_count
from film;
-- Задание 12 - Замена address2 через COALESCE
select address_id, address, address2, coalesce(address2, 'не указан') as filled_address2
from address;
-- Задание 13 - Средняя сумма платежа с защитой от деления на ноль
with customer_totals as (
	select customer_id, sum(amount) as total_sum, count(*) as payment_count
	from payment
	group by customer_id)
select customer_id, total_sum, payment_count,
total_sum/nullif(payment_count, 0) as avg_sum
from customer_totals ;
-- Задание 14 - Полное имя клиента одной строкой
select concat(first_name, ', ', last_name) as full_name
from customer;
-- Задание 15 - Фильмы со словом 'Drama' в описании (без учёта регистра)
select title, description 
from film
where description ~* 'drama';
-- Задание 16 - Платежи по кварталам
select date_trunc('quarter', payment_date) as quater_date, count(*), sum(amount)
from payment 
group by quater_date ;
-- Задание 17 - Половина месяца последней оплаты клиента
with last_payments as (
	select customer_id, extract(day from max(payment_date)) as last_day
	from payment
	group by customer_id)
select customer_id, last_day, 
	case when last_day between 1 and 15 then 'first_part'
	else 'second_part'
	end as part_of_month
from last_payments ;
-- Задание 18 - Первые 3 буквы фамилии в верхнем регистре
select last_name, upper(substring(last_name from 1 for 3)) as code
from customer;
-- Задание 19 - Фамилии только из букв
select last_name
from customer 
where last_name ~ '^[A-Za-z]+$';
-- Задание 20 - Комплексный отчёт по месяцам
select date_trunc('month', payment_date) as month, 
	sum(amount) as total,
	count(*),
	round(avg(amount), 2) as avg_sum
from payment 
group by month 
order by month asc;
