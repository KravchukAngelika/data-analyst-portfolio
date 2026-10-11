CREATE TABLE users_demo (id INT, email TEXT, created_at DATE);
INSERT INTO users_demo VALUES
(1, 'a@mail.com', '2026-01-10'),
(2, 'a@mail.com', '2026-03-05'),
(3, 'b@mail.com', '2026-02-01'),
(4, 'c@mail.com', '2026-01-20'),
(5, 'c@mail.com', '2026-01-25'),
(6, 'c@mail.com', '2026-04-01');

--Задание 1 - Пронумеровать клиентов по алфавиту
select customer_id, first_name, last_name, 
	row_number() over (order by last_name, first_name) as rn
from customer  ;
--Задание 2 - Номер платежа внутри клиента
select payment_id, customer_id, payment_date, amount,
	row_number() over (partition by customer_id order by payment_date, payment_id) as rn
from payment;
--Задание 3 - Сколько строк имеют RANK ≠ DENSE_RANK
with ranked as (
select film_id, title, length,
	rank() over(order by length desc) as rnk,
	dense_rank() over(order by length desc) as drnk
from film)
select count(*)
from ranked 
where rnk <> drnk;
--Задание 4 -  Топ-3 самых длинных фильма в каждом рейтинге (ROW_NUMBER)
with ranked as (
	select rating, title, length ,
		row_number() over(partition by rating order by length desc, film_id) as rn
	from film)
select rating, title, length
from ranked 
where rn <=3
order by rating, length desc;
--Задание 5 -  То же через RANK
with ranked as (
	select rating, title, length ,
		rank() over(partition by rating order by length desc) as rnk
	from film)
select rating, title, length
from ranked 
where rnk <=3
order by rating, length desc;
--Задание 6 - То же через DENSE_RANK
with ranked as (
	select rating, title, length ,
		dense_rank() over(partition by rating order by length desc) as drnk
	from film)
select rating, title, length
from ranked 
where drnk <=3
order by rating, length desc;
--Задание 7 - Первый платёж каждого клиента
with ranked as (
	select c.first_name, c.last_name, p.payment_date, p.amount,
		row_number() over(partition by p.customer_id order by p.payment_date, p.payment_id  ) as rn
	from payment p 
	join customer c on c.customer_id = p.customer_id )
select first_name, last_name, payment_date, amount
from ranked 
where rn=1;
--Задание 8 - Последний платёж каждого клиента
with ranked as (
	select c.first_name, c.last_name, p.payment_date, p.amount,
		row_number() over(partition by p.customer_id order by p.payment_date desc, p.payment_id desc) as rn
	from payment p 
	join customer c on c.customer_id = p.customer_id )
select first_name, last_name, payment_date, amount
from ranked 
where rn=1;
--Задание 9 - Дедупликация users_demo cамая свежая запись
with ranked as (
	select *, 
		row_number() over(partition by email order by created_at desc, id desc) as rn 
	from users_demo)
select id, email, created_at
from ranked 
where rn = 1;
--Задание 10 - Топ-3 клиента по сумме в каждой стране
with summa as (
	select customer_id, sum(amount) as total_sum
	from payment
	group by customer_id),
ranked as (
	select c.customer_id, c.first_name, c.last_name, 
		s.total_sum, co.country,
		row_number() over(partition by co.country order by s.total_sum desc, c.customer_id asc) as rn
	from customer c
	join address a on c.address_id = a.address_id
	join city ci on a.city_id = ci.city_id
	join country co on ci.country_id = co.country_id
	join summa s on c.customer_id = s.customer_id )
select *
from ranked
where rn <= 3;
--Задание 11 - Фильм со вторым по величине length в категории (DENSE_RANK = 2)
with category_film as (
	select c.name, f.title, f.length,
		dense_rank() over(partition by c.name order by length desc) as drnk 
	from film f
	join film_category fc on f.film_id = fc.film_id 
	join category c on fc.category_id = c.category_id )
select name, title, length
from category_film 
where drnk = 2;
where rn <= 3;
--Задание 12 - Место среди всех и место внутри страны
with customer_totals as (
	select c.customer_id, c.first_name, c.last_name, co.country,
		sum(p.amount) as total_sum
	from customer c
	join payment p on c.customer_id = p.customer_id 
	join address a on c.address_id = a.address_id
	join city ci on a.city_id = ci.city_id
	join country co on ci.country_id = co.country_id
	group by c.customer_id, c.first_name, c.last_name, co.country)
select country, first_name, last_name, total_sum,
	rank() over(order by total_sum desc) as global_rnk,
	rank() over(partition by country order by total_sum desc) as country_rnk
from customer_totals ;
--Задание 13 - Самый дорогой фильм в категории через RANK
with category_ranked as (
	select c.name, f.title, f.rental_rate,
		rank() over(partition by c.name order by f.rental_rate desc) as rnk 
	from film f 
	join film_category fc on f.film_id = fc.film_id 
	join category c on fc.category_id = c.category_id)
select name, title, rental_rate
from category_ranked 
where rnk=1;
--Задание 14 - Самый длинный фильм в категории через RANK 
with category_ranked as (
	select c.name, f.title, f.length,
		rank() over(partition by c.name order by f.length desc) as rnk 
	from film f 
	join film_category fc on f.film_id = fc.film_id 
	join category c on fc.category_id = c.category_id)
select name, title, length
from category_ranked 
where rnk=1;
--Задание 15 - Намеренная ошибка — ROW_NUMBER в WHERE
select *
from payment
where row_number() over (partition by customer_id order by payment_date) = 1;
-- исправление
with ranked as (
	select *,
		row_number() over (partition by customer_id order by payment_date) as rn
	from payment)
select * from ranked where rn = 1;
--Задание 16 - Именованное окно (WINDOW clause)
select payment_id, customer_id, payment_date, amount,
	row_number() over w as rn,
	rank() over w as rnk
from payment
window w as (partition by customer_id order by amount desc)
order by customer_id, rn
limit 20;
--Задание 17 - Третья по величине уникальная сумма платежа
with ranked as (
	select amount,
	dense_rank() over(order by amount desc) as drnk
	from payment)
select distinct amount
from ranked 
where drnk = 3;
select distinct amount
from payment 
order by amount desc 
limit 1 offset 2;
--Задание 18 - Клиенты, у которых первый и последний платёж на одну сумму
with first_payments as (
	select customer_id, amount,
		row_number() over(partition by customer_id order by payment_date, payment_id) as rn  
	from payment),
last_payments as (
	select customer_id, amount,
		row_number() over(partition by customer_id order by payment_date desc, payment_id desc) as rn  
	from payment)
select f.customer_id, f.amount as first_amount,
	l.amount as last_amount
from first_payments f
join last_payments l on f.customer_id = l.customer_id 
where f.rn = 1 and l.rn = 1 and f.amount = l.amount;