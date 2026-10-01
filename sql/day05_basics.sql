--Задание 1 имена и фамилии всех клиентов
SELECT first_name, last_name from customer;
--Задание 2 уникальные значения рейтингов фильмов
select distinct rating from film;
--Задание 3 фильмы длительностью больше 120 минут
select * from film where length > 120;
--Задание 4 фильмы с рейтингом PG-13
select * from film where rating = 'PG-13';
--Задание 5 клиенты чье имя начинается на А
select *  from customer where first_name like 'A%';
--Задание 6 клиенты, чья фамилия заканчивается на son
select * from customer where last_name like '%son';
--Задание 7 10 самых длинных фильмов по убыванию
select * from film order by length desc limit 10;
--Задание 8 фильмы с годом выпуска 2006 и рейтингом R
select * from film where release_year = 2006 and rating = 'R';
--Задание 9 фильмы, у которых rental_rate больше 4 или length больше 180
select * from film where rental_rate > 4 or length > 180;
--Задание 10 клиенты, у которых не заполнена почта
select * from customer where email is null;
--Задание 11 5 клиентов с самой большой суммой оплаты 
select * from payment order by amount desc limit 5;
--Задание 12 фильмы, у которых рейтинг G или PG
select * from film where rating in('G', 'PG');
--Задание 13 фильмы, у которых длительность между 60 и 90
select * from film where length between 60 and 90;
--Задание 14 список уникальных городов по алфавиту
select distinct city from city order by city asc;
--Задание 15 неактивные клиенты
select * from customer where active = 0;
--Задание 16 топ-5 самых дешевых по rental_rate фильмов (кроме 0)
select * from film 
where rental_rate <> 0
order by rental_rate asc limit 5;
--Задание 17 фильмы, в названии которых есть love (без учета регистра)
select * from film where title ilike '%love%';
--Задание 18 3, 4 и 5 по алфавиту фамилии актеров
select last_name from actor 
order by last_name asc limit 3 offset 2;
--Задание 19 адреса без указанного второго адреса
select * from address where address2 is null;
select * from address where address2 = '';
--Задание 20 имя, фамилия и длина имени (по убыванию длины)
select first_name, last_name, length(first_name) from customer
order by length(first_name) desc;