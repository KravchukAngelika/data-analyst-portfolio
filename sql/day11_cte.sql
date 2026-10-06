--Задание 1 - Фильмы длиннее средней длительности (через CTE)
with avg_length_films as (
select avg(length) as avg_len from film )
select title, length 
from film, avg_length_films
where length > avg_length_films.avg_len;
--Задание 2 - Клиенты с суммой платежей >150
with customer_payments as (
select customer_id, sum(amount) as total, count(*) as number
from payment group by customer_id)
select customer_id, total, number
from customer_payments 
where customer_payments.total > 150;
--Задание 3 - Клиенты с суммой выше среднего (два CTE)
with sum_amount as (
select customer_id, sum(amount) as total from payment
group by customer_id),
avg_sum as (
select avg(total) as avg_s from sum_amount )
select sum_amount.customer_id, sum_amount.total 
from sum_amount, avg_sum
where sum_amount.total > avg_sum.avg_s;
--Задание 4 - Категории с >55 фильмов
with category_counts as (
select c.name as cat_name, count(*) as film_count
from category c
join film_category fc on c.category_id = fc.category_id 
group by c.name)
select cat_name, film_count
from category_counts 
where film_count > 55;
--Задание 5 - Категории с >60 фильмов и средней длиной <115 (через CTE)
with category_counts as (
select c.name as cat_name, count(*) as film_count, avg(f.length) as film_length
from category c
join film_category fc on c.category_id = fc.category_id 
join film f on fc.film_id = f.film_id 
group by c.name
)
select cat_name, film_count, film_length
from category_counts 
where film_count > 60 and film_length < 115
--Задание 6 - Первый и последний платёж клиента + разница в днях
with payment_dates as (
select customer_id, min(payment_date) as min_date, max(payment_date) as max_date 
from payment
group by customer_id)
select customer_id, min_date, max_date, (max_date::date - min_date::date) as days_betweencat_name 
from payment_dates;
--Задание 7 - Топ-5 самых арендуемых фильмов
with rental_counts as (
select f.film_id, f.title, count(*) as film_rentals
from film f
join inventory i on f.film_id = i.film_id 
join rental r on i.inventory_id = r.inventory_id 
group by f.film_id, f.title)
select title, film_rentals
from rental_counts 
order by film_rentals desc limit 5;
--Задание 8 - Сотрудники со средней суммой выше средней по всем
with avg_staff as (
select staff_id, avg(amount) as avg_payment
from payment
group by staff_id),
total_avg as (
select avg(amount) as total_avg_payment
from payment)
select sa.staff_id, sa.avg_payment
from avg_staff sa, total_avg ta
where sa.avg_payment > ta.total_avg_payment;
--Задание 9 - Клиенты, бравшие все категории (через CTE)
with customer_categories as (
select r.customer_id, count(distinct fc.category_id) as cat_count
from rental r 
join inventory i on r.inventory_id  = i.inventory_id  
join film_category fc on i.film_id  = fc.film_id  
group by r.customer_id ),
total_categories as (
select count(*) as total_cat
from category)
select cc.customer_id, cc.cat_count
from customer_categories cc, total_categories tc 
where cc.cat_count = tc.total_cat ;
--Задание 11 - Генерация чисел от 1 до 20
with recursive numbers as (
select 1 as n 
union all 
select n + 1 from numbers where n < 20)
select * from numbers;
-- Задание 12 - Все даты октября 2026
with recursive october as (
select date '2026-10-01' as d 
union all 
select d + 1 from october where d < date '2026-10-31')
select * from october;
-- Задание 13 - Иерархия сотрудников (создать таблицу и вывести)
CREATE TABLE employee_demo (
    employee_id INT PRIMARY KEY,
    first_name TEXT,
    manager_id INT
);
INSERT INTO employee_demo VALUES
(1, 'Ольга', NULL),
(2, 'Игорь', 1),
(3, 'Марина', 1),
(4, 'Денис', 2),
(5, 'Света', 2),
(6, 'Павел', 4);
with recursive hierarchy as (
select employee_id, first_name, manager_id, 1 as level
from employee_demo
where manager_id is null
union all 
select e.employee_id, e.first_name, e.manager_id, h.level+1
from employee_demo e
join hierarchy h on e.manager_id = h.employee_id )
select level, first_name, employee_id
from hierarchy 
order by level, first_name;
-- Задание 14 - Цепочка руководителей Павла (рекурсия вверх)
with recursive managers as (
select employee_id, first_name, manager_id, 1 as level
from employee_demo
where first_name = 'Павел'
union all 
select e.employee_id, e.first_name, e.manager_id, m.level+1
from employee_demo e
join managers m on e.employee_id = m.manager_id  )
select level, first_name, employee_id
from managers 
order by level, first_name;
-- Задание 15 - Количество подчинённых на всех уровнях
with recursive hierarchy as (
select employee_id, first_name, manager_id, employee_id as root_id
from employee_demo
union all 
select e.employee_id, e.first_name, e.manager_id, h.root_id 
from employee_demo e
join hierarchy h on e.manager_id = h.employee_id )
select root_id, (select first_name from employee_demo where employee_id = root_id) as root_name,
count(*) - 1 as total
from hierarchy 
group by root_id 
order by total desc;
