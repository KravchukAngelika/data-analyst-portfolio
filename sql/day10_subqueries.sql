--Задание 1 - фильмы длиннее среднего
select title, length 
from film
where length > (select avg(length) from film);
--Задание 2 - Клиенты, которые платили больше максимума клиента с ID 1
select distinct customer_id
from payment 
where amount > (select max(amount) from payment where customer_id = 1);
--Задание 3 - Фильмы, которые никогда не брались в аренду
select title
from film 
where film_id not in(select i.film_id from inventory i join rental r on i.inventory_id = r.inventory_id);
-- через not exists
select f.title
from film f
where not exists (select 1 from inventory i 
join rental r on i.inventory_id = r.inventory_id
where i.film_id = f.film_id) ;
--Задание 4 - Клиенты с хотя бы одним платежом >10 (EXISTS)
select c.first_name, c.last_name
from customer c 
where exists(select 1 from payment p 
where c.customer_id = p.customer_id and p.amount > 10);
--Задание 5 - Клиенты без ни одного платежа >10 (NOT EXISTS)
select c.first_name, c.last_name
from customer c 
where not exists(select 1 from payment p 
where c.customer_id = p.customer_id and p.amount > 10);
--Задание 6 - Самый дорогой фильм в каждой категории (коррелированный)
select c.name, f.title, f.rental_rate
from film f
join film_category fc on f.film_id = fc.film_id 
join category c on fc.category_id = c.category_id 
where f.rental_rate = (
select max(f2.rental_rate)
from film f2
join film_category fc2 on f2.film_id = fc2.film_id 
where fc2.category_id = fc.category_id);
--Задание 7 - Актёры, снимавшиеся в 'Academy Dinosaur' (IN)
select a.first_name, a.last_name 
from actor a
where a.actor_id in (
select fa.actor_id
from film_actor fa
join film f on fa.film_id = f.film_id
where f.title = 'Academy Dinosaur');
--Задание 8 - Города без клиентов (NOT EXISTS)
select ci.city
from city ci
where not exists (select 1 from address a
join customer c on a.address_id = c.address_id 
where a.city_id = ci.city_id);
--Задание 9 - Ловушка NULL с NOT IN
select count(*) from address where address2 is null;
select customer_id 
from customer 
where address_id not in (
select address_id from address where address2 is null);
--Задание 10 - Клиенты с суммой платежей больше средней по всем
select customer_id, sum(amount) as total
from payment
group by customer_id 
having sum(amount) > (select avg(total) from (
select sum(amount) as total from payment group by customer_id) as sub);
--Задание 11 - Самый длинный фильм в каждом рейтинге
select f.rating, f.title, f.length
from film f
where f.length = ( select max(f2.length) from film f2
where f2.rating = f.rating);
-- Задание 12 - Фильмы дороже любого фильма категории Horror (ANY)
select title, rental_rate
from film 
where rental_rate > any(
select f.rental_rate 
from film f
join film_category fc on f.film_id = fc.film_id 
join category c on fc.category_id = c.category_id
where c.name = 'Horror');
-- Задание 13 - Фильмы длиннее всех фильмов категории Comedy (ALL)
select title, length
from film 
where length > all(
select f.length 
from film f
join film_category fc on f.film_id = fc.film_id 
join category c on fc.category_id = c.category_id
where c.name = 'Comedy');
-- Задание 14 - Клиенты, которые брали все категории
select c.customer_id, c.first_name, c.last_name
from customer c
where (
select count(distinct fc.category_id) 
from film_category fc
join inventory i on fc.film_id  = i.film_id 
join rental r on i.inventory_id = r.inventory_id 
where r.customer_id = c.customer_id )=(
select count(*) from category);
-- Задание 15 - Переписать задачу 3 через LEFT JOIN
select f.title
from film f
left join inventory i on f.film_id = i.film_id
left join rental r on i.inventory_id = r.inventory_id 
where i.inventory_id is null or r.rental_id is null;
