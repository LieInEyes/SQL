-- ЗАДАНИЕ 0
-- напишите SQL-инструкцию, которая возвращает список названий пиццерий
-- с соответствующим значением рейтинга, которые не посещались людьми.
SELECT pizzeria.name, pizzeria.rating
FROM pizzeria
         LEFT OUTER JOIN  person_visits
                          ON pizzeria.id = person_visits.pizzeria_id
WHERE person_visits.pizzeria_id ISNULL;

-- ЗАДАНИЕ 1
-- напишите SQL-запрос, который возвращает пропущенные дни с 1 по 10 января 2022 года
-- (включая все дни) для посещений лиц с идентификаторами 1 или 2. Отсортируйте по дням посещения в порядке возрастания.
-- | missing_date |
-- | ------       |
-- | 2022-01-03   |
-- | 2022-01-04   |
-- | 2022-01-05   |
-- | ...          |
SELECT missing_date::DATE
FROM GENERATE_SERIES('2022-01-01'::DATE, '2022-01-10'::DATE, '1 days') AS missing_date
         LEFT OUTER JOIN (SELECT person_visits.visit_date
                          FROM person_visits
                          WHERE person_visits.person_id BETWEEN 1 AND 2) AS visit
                         ON visit.visit_date = missing_date.missing_date
WHERE visit.visit_date ISNULL
ORDER BY missing_date;

-- ЗАДАНИЕ 2
-- напишите SQL-инструкцию, которая возвращает полный список имен людей, посетивших (или не посещенных)
-- пиццерии в период с 1 по 3 января 2022 года, с одной стороны, и полный список названий пиццерий,
-- которые были посещены (или не посещались), с другой стороны.
-- обратите внимание на подстановку значения ‘-’ для значений `NULL` в столбцах `person_name`
-- и `pizzeria_name`. сделайте сортировку для всех 3 столбцов.
-- | person_name | visit_date | pizzeria_name |
-- | ------      | ------     | ------        |
-- | -           | null       | DinoPizza     |
-- | -           | null       | DoDo Pizza    |
-- | Andrey      | 2022-01-01 | Dominos       |
-- | Andrey      | 2022-01-02 | Pizza Hut     |
-- | Anna        | 2022-01-01 | Pizza Hut     |
-- | Denis       | null       | -             |
-- | Dmitriy     | null       | -             |
-- | ...         | ...        | ...           |
SELECT CASE
           WHEN p.name ISNULL
               THEN '-'
           ELSE p.name
           END AS person_name, pv.visit_date AS visit_date,
       CASE
           WHEN piz.name ISNULL
               THEN '-'
           ELSE piz.name
           END AS pizzeria_name
FROM person AS p
         FULL JOIN (SELECT *
                    FROM person_visits
                    WHERE visit_date BETWEEN '2022-01-01' AND '2022-01-03') AS pv
                   ON p.id = pv.person_id
         FULL JOIN  pizzeria piz
                    ON piz.id = pv.pizzeria_id
ORDER BY person_name, visit_date, pizzeria_name;

-- ЗАДАНИЕ 2
-- Дперепишите свой SQL из задания 1, используя шаблон CTE (Common Table Expression).
-- Результат должен быть таким же, как во 2ом задании
-- | missing_date |
-- | ------       |
-- | 2022-01-03   |
-- | 2022-01-04   |
-- | 2022-01-05   |
-- | ...          |
WITH person_1_2 AS
         (SELECT person_visits.visit_date
          FROM person_visits
          WHERE person_visits.person_id BETWEEN 1 AND 2)
SELECT missing_date::DATE
FROM GENERATE_SERIES('2022-01-01'::DATE, '2022-01-10'::DATE, '1 days') AS missing_date
         LEFT OUTER JOIN person_1_2 AS visit
                         ON visit.visit_date = missing_date.missing_date
WHERE visit.visit_date ISNULL
ORDER BY missing_date;

-- ЗАДАНИЕ 3
-- Найдите полную информацию обо всех возможных названиях пиццерий и ценах на пиццу с грибами или пепперони.
-- отсортируйте результат по названию пиццы и названию пиццерии.
-- используйте те же названия столбцов в вашей инструкции SQL.
-- | pizza_name      | pizzeria_name | price |
-- | ------          | ------        | ----- |
-- | mushroom pizza  | Dominos       | 1100  |
-- | mushroom pizza  | Papa Johns    | 950   |
-- | pepperoni pizza | Best Pizza    | 800   |
-- | ...             | ...           | ...   |
SELECT m.pizza_name AS pizza_name, piz.name AS pizzeria_name, m.price AS price
FROM
    (SELECT pizzeria.id, pizzeria.name
     FROM pizzeria) piz
        JOIN
    (SELECT menu.pizzeria_id, menu.pizza_name, menu.price
     FROM menu
     WHERE menu.pizza_name = 'mushroom pizza' OR menu.pizza_name = 'pepperoni pizza') AS m
    ON piz.id = m.pizzeria_id
ORDER BY pizza_name, pizzeria_name;

-- ЗАДАНИЕ 4
-- Найдите имена всех женщин старше 25 лет и упорядочите результат по имени.
-- | name   |
-- | ------ |
-- | Elvira |
-- | ...    |
SELECT name
FROM person
WHERE age > '25' AND gender = 'female'
ORDER BY name;

-- ЗАДАНИЕ 5
-- найдите все названия пиццы (и соответствующие названия пиццерий, используя таблицу "меню"),
-- которые заказывали Денис или Анна. Отсортируйте результат по обоим столбцам.
-- | pizza_name   | pizzeria_name |
-- | ------       | ------        |
-- | cheese pizza | Best Pizza    |
-- | cheese pizza | Pizza Hut     |
-- | ...          | ...           |
SELECT menu.pizza_name AS pizza_name, pizzeria.name AS pizzeria_name
FROM person_order
         JOIN person
              ON person_order.person_id = person.id
         JOIN menu
              ON person_order.menu_id = menu.id
         JOIN pizzeria
              ON menu.pizzeria_id = pizzeria.id
WHERE person.name = 'Denis' OR person.name = 'Anna'
ORDER BY  pizza_name, pizzeria_name;

-- ЗАДАНИЕ 6
-- найдите название пиццерии, которую Дмитрий посетил 8 января 2022 года и смог съесть пиццу менее чем за 800 рублей.
SELECT pizzeria.name
FROM person_visits
         JOIN pizzeria
              ON person_visits.pizzeria_id = pizzeria.id
         JOIN menu
              ON pizzeria.id = menu.pizzeria_id
         JOIN person
              ON person_visits.person_id = person.id
WHERE person.name = 'Dmitriy'
  AND menu.price < 800
  AND person_visits.visit_date = '2022-01-08';

-- ЗАДАНИЕ 7
-- найдите имена всех мужчин из Москвы или Самары, которые заказывают пиццу с пепперони или грибами
-- (или и то, и другое). Отсортируйте результат по имени человека в порядке убывания.
-- | name    |
-- | ------  |
-- | Dmitriy |
-- | ...     |
SELECT DISTINCT person.name
FROM person
         JOIN person_order
              ON person.id = person_order.person_id
         JOIN menu
              ON person_order.menu_id = menu.id
WHERE
    (person.address = 'Moscow' OR person.address = 'Samara')
  AND person.gender = 'male'
  AND (menu.pizza_name = 'mushroom pizza' OR menu.pizza_name = 'pepperoni pizza')
ORDER BY person.name DESC;

-- ЗАДАНИЕ 8
-- найдите имена всех женщин, которые заказывали пиццу с пепперони и сыром
-- (в любое время и в любых пиццериях). Отсортируйте по имени человека.
-- | name   |
-- | ------ |
-- | Anna   |
-- | ...    |
SELECT person.name
FROM person
         JOIN person_order
              ON person.id = person_order.person_id
         JOIN menu
              ON person_order.menu_id = menu.id
WHERE
    person.gender = 'female'
  AND (menu.pizza_name = 'cheese pizza' OR menu.pizza_name = 'pepperoni pizza')
GROUP BY person.name
HAVING count(menu.pizza_name) = 2
ORDER BY person.name;

-- ЗАДАНИЕ 9
-- найдите имена людей, проживающих по одному и тому же адресу.
-- Отсортируйте по имени 1-го человека, имени 2-го человека и общему адресу.
-- | person_name1 | person_name2 | common_address |
-- | ------       | ------       | ------         |
-- | Andrey       | Anna         | Moscow         |
-- | Denis        | Kate         | Kazan          |
-- | Elvira       | Denis        | Kazan          |
-- | ...          | ...          | ...            |
SELECT p_left.name AS person_name1,
       p_right.name AS person_name2,
       p_left.address AS common_address
FROM person AS p_left
         JOIN person AS p_right
              ON p_left.address = p_right.address AND p_left.name != p_right.name AND p_left.id > p_right.id
ORDER BY person_name1, person_name2, common_address;