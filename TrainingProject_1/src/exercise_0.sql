-- ЗАДАНИЕ 0
-- вернуть имена и возраст всех пользователей из города ‘Казань’
SELECT name, age
FROM person
WHERE address='Kazan';

-- ЗАДАНИЕ 1
-- сделайте запрос select, который вернет имена и возраст всех женщин из города "Казань".
-- отсортируйте результат по имени.
SELECT name, age
FROM person
WHERE gender='female' AND address='Kazan'
ORDER BY name;

-- ЗАДАНИЕ 2
-- сделайте 2 различных инструкции select, которые возвращают список пиццерий (название пиццерии и рейтинг) с рейтингом
-- от 3,5 до 5 баллов (включая предельные баллы) и упорядоченных по рейтингу пиццерии.
-- 1-й оператор select должен содержать знаки сравнения <=, >=
-- 2-й оператор select должен содержать ключевое слово BETWEEN
SELECT name, rating
FROM pizzeria
WHERE rating >= 3.5 AND rating <= 5
ORDER BY rating;

SELECT name, rating
FROM pizzeria
WHERE rating BETWEEN 3.5 AND 5
ORDER BY rating;

-- ЗАДАНИЕ 3
-- сделайте инструкцию select, которая возвращает идентификаторы лиц (без дублирования),
-- которые посещали пиццерии в период с 6 января 2022 года по 9 января 2022 года (включая все дни)
-- или посещали пиццерию с идентификатором 2.
-- Также включите предложение о заказе по идентификатору пользователя в режиме убывания.
SELECT DISTINCT person_id
FROM person_visits
WHERE pizzeria_id = 2
   OR visit_date BETWEEN '2022-01-06' AND '2022-01-09'
ORDER BY person_id DESC;

-- ЗАДАНИЕ 4
-- сделайте инструкцию select, которая возвращает одно вычисляемое поле с именем ‘person_information’ в одной строке,
-- как описано в следующем примере: `Анна (возраст:16,пол:'женский',адрес:'Москва')`
-- добавьте предложение упорядочения по вычисляемому столбцу в порядке возрастания.
SELECT concat(name, ' (age:', age, ',gender:', quote_literal(gender), ',address:', quote_literal(address), ')') AS person_information
FROM person
ORDER BY person_information;

-- ЗАДАНИЕ 5
-- сделайте запрос select, который вернет имена пользователей (на основе внутреннего запроса в пункте "SELECT"),
-- которые сделали заказы для меню с идентификаторами 13, 14 и 18, а дата заказов должна быть равна 7 января 2022 года.
--     SELECT
-- 	    (SELECT ... ) AS NAME  -- this is an internal query in a main SELECT clause
--     FROM ...
--     WHERE ...
SELECT
    (SELECT name
     FROM person
     WHERE id = person_id)
FROM person_order
WHERE (menu_id = 13
    OR menu_id = 14
    OR menu_id = 18)
  AND order_date = '2022-01-07';

-- ЗАДАНИЕ 6
-- используйте конструкцию SQL из предыдущего задания и добавьте новый вычисляемый столбец
-- (используйте имя столбца ‘check_name’) с инструкцией проверки в предложении `SELECT`.
-- if (person_name == 'Denis') then return true
--         else return false
SELECT
    (SELECT name
     FROM person
     WHERE id = person_id),
    CASE WHEN
             (SELECT name
              FROM person
              WHERE id = person_id) = 'Denis'
             THEN 'true'
         ELSE 'false'
        END AS check_name
FROM person_order
WHERE (menu_id = 13
    OR menu_id = 14
    OR menu_id = 18)
  AND order_date =  '2022-01-07';

-- ЗАДАНИЕ 7
-- создайте SQL-инструкцию, которая возвращает идентификаторы человека, имена людей и интервал возрастов людей
-- (задайте имя нового вычисляемого столбца как ‘interval_info’).
-- if (age >= 10 and age <= 20) then return 'interval #1'
--     else if (age > 20 and age < 24) then return 'interval #2'
--     else return 'interval #3'
-- отсортируйте результат по столбцу ‘interval_info’ в порядке возрастания.
SELECT id, name,CASE
                    WHEN age BETWEEN 10 AND 20
                        THEN 'interval #1'
                    WHEN age BETWEEN 21 AND 23
                        THEN 'interval #2'
                    ELSE 'interval #3'
    END AS interval_info
FROM person
ORDER BY interval_info;

-- ЗАДАНИЕ 8
-- создайте инструкцию SQL, которая возвращает все столбцы из таблицы `person_order` со строками,
-- идентификатор которых является четным числом. Результат должен быть упорядочен по возвращаемому идентификатору.
SELECT *
FROM person_order
WHERE id % 2 = 0
ORDER BY id;

-- ЗАДАНИЕ 9
-- сделайте запрос select, который возвращает имена пользователей и названия пиццерий на основе таблицы `person_visit` с
-- указанием даты посещения в период с 07 по 09 января 2022 года (включая все дни)
-- (на основе внутреннего запроса в предложении `FROM`).
-- шаблон
--     SELECT (...) AS person_name ,  -- this is an internal query in a main SELECT clause
--             (...) AS pizzeria_name  -- this is an internal query in a main SELECT clause
--     FROM (SELECT … FROM person_visits WHERE …) AS pv -- this is an internal query in a main FROM clause
--     ORDER BY ...
-- отсортируйте по имени человека в порядке возрастания и по названию пиццерии в порядке убывания
SELECT
    (SELECT name
     FROM person
     WHERE id = person_id) AS person_name,
    (SELECT name
     FROM pizzeria
     WHERE id = pizzeria_id) AS pizzeria_name
FROM
    (SELECT *
     FROM person_visits
     WHERE visit_date BETWEEN '2022-01-07' AND '2022-01-09') AS pv
ORDER BY person_name, pizzeria_name DESC;