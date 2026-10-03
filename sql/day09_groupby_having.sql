--Задание 1 - общее количество клиентов
SELECT COUNT(*) as total_customers
FROM customer;
--Задание 2 - клиенты по значению active
select count(*), active 
from customer
group by active;
--Задание 3 - количество копий каждого фильма в inventory
select f.title, count(i.inventory_id) as copies
from film f
left join inventory i on f.film_id = i.film_id 
group by f.title;
--Задание 4 - средняя длительность фильма по каждому рейтингу
select rating, avg(length) as avg_length
from film
group by rating
order by avg(length) desc;
--Задание 5 - количество фильмов в каждой категории
select c.name, count(fc.film_id) as film_count
from category c
join film_category fc on c.category_id = fc.category_id
group by c.name
order by count(fc.film_id) desc;
--Задание 6 - суммарная выручка по каждому сотруднику
select staff_id, sum(amount)
from payment 
group by staff_id;
--Задание 7 - клиенты с >40 платежами
select customer_id, count(*) 
from payment
group by customer_id 
having count(*) > 40;
--Задание 8 - категории со средней ценой аренды > 3
select c.name, avg(f.rental_rate)
from category c
join film_category fc on c.category_id = fc.category_id
join film f on fc.film_id = f.film_id 
group by c.name 
having avg(f.rental_rate) > 3 ;
--Задание 9 - города с > 1 клиентом
select ci.city, count(*)
from customer c
join address a on c.address_id  = a.address_id
join city ci on a.city_id = ci.city_id
group by ci.city 
having count(*) > 1;
--Задание 10 - сравнение count(*) и count(email)
select count(*) AS all_rows, count(email) AS with_email
FROM customer;
--Задание 11 - min, max суммы платежа
select min(amount), max(amount)
from payment;
-- Задание 12 - min, max, avg суммы платежей для каждого клиента
select customer_id, min(amount), max(amount), avg(amount)
from payment
group by customer_id;
-- Задание 13 - количество уникальных арендованных фильмов 
select count(distinct i.film_id)
from inventory i
join rental r on i.inventory_id = r.inventory_id ;
-- Задание 14 - сотрудники с выручкой > 10000
select staff_id, sum(amount)
from payment
group by staff_id
having sum(amount) > 10000
order by sum(amount) desc;
-- Задание 15 - количество фильмов по паре (категория - рейтинг)
select c.name, f.rating, count(*)
from film f
join film_category fc on f.film_id = fc.film_id 
join category c on fc.category_id = c.category_id 
group by c.name, f.rating;
-- Задание 16 - категории >60 фильмов и средней длиной <115
select c.name, count(*), avg(f.length)
from category c 
join film_category fc on c.category_id = fc.category_id
join film f on fc.film_id = f.film_id 
group by c.name 
having count(*)>60 and avg(f.length) < 115;
-- Задание 17 - платежи по датам
select payment_date::date, count(*)
from payment 
group by payment_date::date
order by payment_date::date;
-- Задание 18 - средняя сумма для клиентов с > 5 платежами
select customer_id, avg(amount)
from payment 
group by customer_id 
having count(*)>5;