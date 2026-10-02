--Задание 1 - имя и фамилия клиента, город
SELECT c.first_name, c.last_name, ci.city
FROM customer c
JOIN address a  ON c.address_id = a.address_id
join city ci on a.city_id = ci.city_id;
--Задание 2 - название фильма и категория
select f.title, c.name 
from film f
join film_category fc on f.film_id = fc.film_id
join category c on fc.category_id = c.category_id;
--Задание 3 - клиенты, которые ни разу не совершили оплату
select c.first_name, c.last_name
from customer c
left join payment p on c.customer_id = p.customer_id 
where p.payment_id is null;
--Задание 4 - имя сотрудника и количество обработанных им платежей (без агрегации)
select s.first_name, s.last_name, p.amount
from staff s
join payment p on s.staff_id = p.staff_id 
order by s.first_name, s.last_name;
--Задание 5 - название фильма, рейтинг, категория
select f.title, f.rating, c.name 
from film f
join film_category fc on f.film_id = fc.film_id
join category c on fc.category_id = c.category_id
order by c.name, f.title;
--Задание 6 - фильмы без записи в inventory
select f.title
from film f
left join inventory i on f.film_id = i.film_id 
where i.inventory_id is null;
--Задание 7 - имя актера и фильм
select a.first_name, a.last_name, f.title 
from actor a
join film_actor fa on a.actor_id = fa.actor_id
join film f on fa.film_id = f.film_id ;
--Задание 8 - пары актре-актер, которые снимались в одном и том же фильме
select fa1.actor_id as actor1, fa2.actor_id as actor2, fa1.film_id
from film_actor fa1
join film_actor fa2 on fa1.film_id = fa2.film_id 
and fa1.actor_id < fa2.actor_id ;
--Задание 9 - город и страна для каждого адреса клиента
select ci.city, co.country, a.address
from address a
join city ci on a.city_id = ci.city_id 
join country co on ci.country_id = co.country_id ;
--Задание 10 - клиенты, которые брали в аренду фильсы экшен
select distinct c.first_name, c.last_name
from customer c 
join rental r on c.customer_id = r.customer_id 
join inventory i on r.inventory_id = i.inventory_id 
join film f on i.film_id = f.film_id 
join film_category fc on f.film_id = fc.film_id 
join category ca on fc.category_id = ca.category_id 
where ca.name = 'Action';
--Задание 11 - количество строк для customer LEFT/INNER JOIN payment (без агрегации)
select count(*)
from customer c
left join payment p on c.customer_id = p.customer_id;
--
select count(*)
from customer c
inner join payment p on c.customer_id = p.customer_id;
-- Задание 12
-- Неправильно (WHERE убивает LEFT)
SELECT count(*)
FROM customer c
LEFT JOIN payment p ON c.customer_id = p.customer_id
WHERE p.amount > 5;
-- Правильно (условие в ON)
SELECT count(*)
FROM customer c
LEFT JOIN payment p ON c.customer_id = p.customer_id AND p.amount > 5;
-- Задание 13
SELECT f1.title, f2.title, f1.length
FROM film f1
JOIN film f2 ON f1.length = f2.length AND f1.film_id < f2.film_id;
-- Задание 14
SELECT s.first_name, s.last_name, a.address
FROM store st
JOIN staff s ON st.manager_staff_id = s.staff_id
JOIN address a ON st.address_id = a.address_id;
-- Задание 15
SELECT c.name AS category, l.name AS language
FROM category c
CROSS JOIN language l;