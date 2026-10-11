--Задание 1 - Клиенты и сумма их платежей, только у кого больше 25 платежей.
select c.first_name, c.last_name, sum(p.amount) as total
from customer c 
join payment p on c.customer_id = p.customer_id 
group by c.first_name , c.last_name 
having count(*)>25
order by total desc;
--Задание 2 - Фильмы, которых нет ни в одной записи inventory
select f.film_id, f.title
from film f
where not exists(select 1 from inventory i where f.film_id = i.film_id );
--Задание 3 - Выручка по месяцам и доля каждого месяца от общей выручки в процентах
with monthly as (
	select date_trunc('month', payment_date) as month,
	sum(amount) as total
	from payment
	group by month), 
total_sum as (
	select sum(amount) as summa
	from payment)
select m.month, m.total,
	round(100.0 * m.total/ts.summa, 1) as percent
from monthly m, total_sum ts;
--Задание 4 -  категории фильмов, у которых средняя длительность выше средней по всем фильмам
with category_length as (
	select c.name as category, avg(f.length) as avg_film
	from category c 
	join film_category fc on c.category_id = fc.category_id 
	join film f on fc.film_id = f.film_id 
	group by category),
film_length as (
	select avg(length) as avg_length 
	from film )
select cl.category, cl.avg_film
from category_length cl, film_length fl
where cl.avg_film > fl.avg_length;
--Задание 5 - сколько фильмов с rental_rate 0.99, 2.99, 4.99 (три столбца)
select count(case when rental_rate = 0.99 then 1 end) as rate99,
	count(case when rental_rate = 2.99 then 1 end) as rate299,
	count(case when rental_rate = 4.99 then 1 end) as rate499
from film;
--Задание 6 - Клиенты, у которых нет ни одного платежа больше 8
select c.first_name, c.last_name
from customer c 
where not exists( select 1 from payment p where p.customer_id = c.customer_id and p.amount > 8);
--Задание 7 - Для каждой категории — самый длинный фильм (название, длительность)
select c.name, f.title, f.length 
from film f
join film_category fc on f.film_id = fc.film_id 
join category c on fc.category_id = c.category_id 
where f.length = (select max(f2.length)
	from film f2
	join film_category fc2 on f2.film_id = fc2.film_id 
	join category c2 on fc2.category_id = c2.category_id);
--Задание 8 - Для каждого клиента: имя, количество платежей, сумма, дата последнего платежа, метка через CASE
select c.first_name, c.last_name, 
	count(*) as payment_cnt,
	sum(p.amount) as total_sum,
	max(p.payment_date)::date as last_payment,
	case 
		when max(p.payment_date)::date >= (select max(payment_date)::date - interval '60 days' from payment) then 'активный'
		else 'спящий'
	end as category
from customer c
join payment p on c.customer_id = p.customer_id 
group by c.customer_id, c.first_name, c.last_name;