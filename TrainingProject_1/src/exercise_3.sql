-- ЗАДАНИЕ 0
-- напишите SQL-инструкцию, которая возвращает список названий пиццерий, цен на пиццу,
-- названий пиццерий и дат посещения для Кейт и для цен в диапазоне от 800 до 1000 рублей. Пожалуйста,
-- отсортируйте по пицце, цене и названиям пиццерий.
-- | pizza_name      | price | pizzeria_name | visit_date |
-- | ------          | ----- | ------        | ------     |
-- | cheese pizza    | 950   | DinoPizza     | 2022-01-04 |
-- | pepperoni pizza | 800   | Best Pizza    | 2022-01-03 |
-- | pepperoni pizza | 800   | DinoPizza     | 2022-01-04 |
-- | ...             | ...   | ...           | ...        |
SELECT menu.pizza_name AS pizza_name,
       menu.price AS price,
       pizzeria.name AS pizzeria_name,
       person_visits.visit_date AS visit_date
FROM person_visits
         JOIN pizzeria
              ON person_visits.pizzeria_id = pizzeria.id
         JOIN person
              ON person_visits.person_id = person.id AND person.name = 'Kate'
         JOIN menu
              ON person_visits.pizzeria_id = menu.pizzeria_id
                  AND menu.price BETWEEN 800 AND 1000
ORDER BY pizza_name, price, pizzeria_name;

-- ЗАДАНИЕ 1
-- найдите все идентификаторы меню, которые никем не заказаны. Результат должен быть отсортирован по идентификаторам.
-- Запрещено использовать любой тип JOIN.
-- | menu_id |
-- | ------  |
-- | 5       |
-- | 10      |
-- | ...     |
SELECT menu.id AS menu_id
FROM menu
WHERE menu.id NOT IN (SELECT person_order.menu_id
                      FROM person_order)
ORDER BY menu_id;

-- ЗАДАНИЕ 2
-- используйте инструкцию SQL из 1го упражнения и покажите названия пиццерий, которые никто не заказывал,
-- а также соответствующие цены. Результат должен быть отсортирован по названию пиццы и цене.
-- | pizza_name   | price | pizzeria_name |
-- | ------       | ----- | ------        |
-- | cheese pizza | 700   | Papa Johns    |
-- | cheese pizza | 780   | DoDo Pizza    |
-- | ...          | ...   | ...           |
SELECT menu.pizza_name AS pizza_name,
       menu.price AS price,
       (SELECT pizzeria.name
        FROM pizzeria
        WHERE pizzeria.id = menu.pizzeria_id) AS pizzeria_name
FROM menu
WHERE menu.id NOT IN (SELECT person_order.menu_id FROM person_order)
ORDER BY pizza_name, price;

-- ЗАДАНИЕ 3
-- найдите объединение пиццерий, которые посещали либо женщины, либо мужчины. Другими словами,
-- вы должны найти набор названий пиццерий, которые посещали только женщины,
-- и выполнить операцию "UNION" с набором названий пиццерий, которые посещали только мужчины.
-- Обратите внимание на слово “только” для обоих полов. Для любых SQL-операторов с наборами сохраняйте
-- дубликаты (конструкции UNION ALL, EXCEPT ALL, INTERSECT ALL). Отсортируйте результат по названию пиццерии.
-- | pizzeria_name |
-- | ------        |
-- | Best Pizza    |
-- | Dominos       |
-- | ...           |
(SELECT (SELECT pizzeria.name
         FROM pizzeria
         WHERE person_visits.pizzeria_id = pizzeria.id) AS pizzeria_name
 FROM person_visits
          JOIN person
               ON person_visits.person_id = person.id AND person.gender = 'female'
          JOIN pizzeria
               ON person_visits.pizzeria_id = pizzeria.id
 EXCEPT ALL
 SELECT (SELECT pizzeria.name
         FROM pizzeria
         WHERE person_visits.pizzeria_id = pizzeria.id) AS pizzeria_name
 FROM person_visits
          JOIN person
               ON person_visits.person_id = person.id AND person.gender = 'male'
          JOIN pizzeria
               ON person_visits.pizzeria_id = pizzeria.id)

UNION ALL

(SELECT (SELECT pizzeria.name
         FROM pizzeria
         WHERE person_visits.pizzeria_id = pizzeria.id) AS pizzeria_name
 FROM person_visits
          JOIN person
               ON person_visits.person_id = person.id AND person.gender = 'male'
          JOIN pizzeria
               ON person_visits.pizzeria_id = pizzeria.id
 EXCEPT ALL
 SELECT (SELECT pizzeria.name
         FROM pizzeria
         WHERE person_visits.pizzeria_id = pizzeria.id) AS pizzeria_name
 FROM person_visits
          JOIN person
               ON person_visits.person_id = person.id AND person.gender = 'female'
          JOIN pizzeria
               ON person_visits.pizzeria_id = pizzeria.id)
ORDER BY pizzeria_name;

-- ЗАДАНИЕ 4
-- найдите объединение пиццерий, у которых есть заказы либо от женщин, либо от мужчин.
-- Другими словами, вы должны найти набор названий пиццерий, которые были заказаны только женщинами,
-- и выполнить операцию "UNION" с набором названий пиццерий, которые были заказаны только мужчинами.
-- Обратите внимание на слово “только” для обоих полов.
-- Для любых SQL-операторов с наборами не сохраняйте дубликаты (`UNION`, `EXCEPT`, `INTERSECT`).
-- Отсортируйте результат по названию пиццерии.
-- | pizzeria_name |
-- | ------        |
-- | Papa Johns    |
(SELECT pizzeria.name AS pizzeria_name
 FROM person_order
          JOIN person
               ON person_order.person_id = person.id AND person.gender = 'female'
          JOIN menu
               ON person_order.menu_id = menu.id
          JOIN pizzeria
               ON menu.pizzeria_id = pizzeria.id
 EXCEPT
 SELECT pizzeria.name AS pizzeria_name
 FROM person_order
          JOIN person
               ON person_order.person_id = person.id AND person.gender = 'male'
          JOIN menu
               ON person_order.menu_id = menu.id
          JOIN pizzeria
               ON menu.pizzeria_id = pizzeria.id)

UNION ALL

(SELECT pizzeria.name AS pizzeria_name
 FROM person_order
          JOIN person
               ON person_order.person_id = person.id AND person.gender = 'male'
          JOIN menu
               ON person_order.menu_id = menu.id
          JOIN pizzeria
               ON menu.pizzeria_id = pizzeria.id
 EXCEPT
 SELECT pizzeria.name AS pizzeria_name
 FROM person_order
          JOIN person
               ON person_order.person_id = person.id AND person.gender = 'female'
          JOIN menu
               ON person_order.menu_id = menu.id
          JOIN pizzeria
               ON menu.pizzeria_id = pizzeria.id)
ORDER BY pizzeria_name;

-- ЗАДАНИЕ 5
-- напишите SQL-инструкцию, которая возвращает список пиццерий, которые Андрей посетил,
-- но не сделал ни одного заказа. Отсортируйте по названию пиццерии.
-- | pizzeria_name |
-- | ------        |
-- | Pizza Hut     |
(SELECT pizzeria.name AS pizzeria_name
 FROM person_visits
          JOIN pizzeria
               ON person_visits.pizzeria_id = pizzeria.id
 WHERE person_visits.person_id = 2)

EXCEPT

(SELECT pizzeria.name AS pizzeria_name
 FROM person_order
          JOIN menu
               ON person_order.menu_id = menu.id
          JOIN pizzeria
               ON menu.pizzeria_id = pizzeria.id
 WHERE person_order.person_id = 2)
ORDER BY pizzeria_name;

-- ЗАДАНИЕ 6
-- найдите одинаковые названия пиццерий с одинаковой ценой, но из разных пиццерий.
-- Отсортируйте по названию пиццы.
-- | pizza_name   | pizzeria_name_1 | pizzeria_name_2 | price |
-- | ------       | ------          | ------          | ----- |
-- | cheese pizza | Best Pizza      | Papa Johns      | 700   |
-- | ...          | ...             | ...             | ...   |
WITH piz_price AS
         (SELECT pizzeria.id, pizzeria.name, menu.pizza_name, menu.price
          FROM pizzeria
                   JOIN menu
                        ON pizzeria.id = menu.pizzeria_id)
SELECT piz_price_left.pizza_name AS pizza_name,
       piz_price_left.name AS pizzeria_name_1,
       piz_price_right.name AS pizzeria_name_2,
       piz_price_left.price AS price
FROM piz_price AS piz_price_left
         JOIN piz_price AS piz_price_right
              ON piz_price_left.pizza_name = piz_price_right.pizza_name
                  AND piz_price_left.name != piz_price_right.name
                  AND piz_price_left.price = piz_price_right.price
                  AND piz_price_left.id > piz_price_right.id
ORDER BY pizza_name;

-- ЗАДАНИЕ 7
-- зарегистрируйте новую пиццу с названием “греческая пицца” (используйте id = 19)
-- по цене 800 рублей в ресторане “Доминос” (pizzeria_id = 2).
INSERT INTO menu VALUES (19,2,'greek pizza', 800);

-- ЗАДАНИЕ 8
-- зарегистрируйте новую пиццу с названием “сицилийская пицца” (идентификатор которой должен быть рассчитан по формуле
-- “максимальное значение идентификатора + 1”) стоимостью 900 рублей в ресторане “Доминос” (пожалуйста,
-- используйте внутренний запрос, чтобы получить идентификатор пиццерии).
INSERT INTO menu VALUES (
                            (SELECT MAX(menu.id) AS LargestPrice
                             FROM menu) + 1,
                            (SELECT pizzeria.id
                             FROM pizzeria
                             WHERE pizzeria.name = 'Dominos'),
                            'sicilian pizza',
                            900);

-- ЗАДАНИЕ 9
-- зарегистрируйте новые посещения ресторана Dominos Денисом и Ириной 24 февраля 2022 года.
INSERT INTO person_visits VALUES (
                                     (SELECT MAX(person_visits.id) AS new_pv_id
                                      FROM person_visits) + 1,
                                     (SELECT person.id
                                      FROM person
                                      WHERE person.name = 'Denis'),
                                     (SELECT pizzeria.id
                                      FROM pizzeria
                                      WHERE pizzeria.name = 'Dominos'),
                                     '2022-02-24');

INSERT INTO person_visits VALUES (
                                     (SELECT MAX(person_visits.id) AS new_pv_id
                                      FROM person_visits) + 1,
                                     (SELECT person.id
                                      FROM person
                                      WHERE person.name = 'Irina'),
                                     (SELECT pizzeria.id
                                      FROM pizzeria
                                      WHERE pizzeria.name = 'Dominos'),
                                     '2022-02-24');

-- ЗАДАНИЕ 10
-- зарегистрируйте новые заказы от Дениса и Ирины на 24 февраля 2022 года для нового меню с “сицилийской пиццей”.
INSERT INTO person_order VALUES (
                                    (SELECT MAX(person_order.id) AS new_po_id
                                     FROM person_order) + 1,
                                    (SELECT person.id
                                     FROM person
                                     WHERE person.name = 'Denis'),
                                    (SELECT menu.id
                                     FROM menu
                                     WHERE menu.pizza_name = 'sicilian pizza'),
                                    '2022-02-24');

INSERT INTO person_order VALUES (
                                    (SELECT MAX(person_order.id) AS new_po_id
                                     FROM person_order) + 1,
                                    (SELECT person.id
                                     FROM person
                                     WHERE person.name = 'Irina'),
                                    (SELECT menu.id
                                     FROM menu
                                     WHERE menu.pizza_name = 'sicilian pizza'),
                                    '2022-02-24');

-- ЗАДАНИЕ 11
-- измените цену на “греческую пиццу” на -10% от текущей стоимости.
UPDATE menu
SET price = price - price * 0.1
WHERE menu.pizza_name = 'greek pizza';

-- ЗАДАНИЕ 12
-- зарегистрируйте новые заказы от всех пользователей на “греческую пиццу” до 25 февраля 2022 года.
-- Запрещено использовать оконные функции, такие как `ROW_NUMBER( )` и запрещено использовать атомарные операторы `INSERT`
INSERT INTO person_order (id, person_id, menu_id, order_date)
SELECT (SELECT MAX(person_order.id)
        FROM person_order) + new_p_id,
       new_p_id,
       (SELECT menu.id FROM menu WHERE menu.pizza_name = 'greek pizza'),
       '2022-02-25'
FROM GENERATE_SERIES(
             (SELECT MIN(person.id)
              FROM person),
             (SELECT MAX(person.id)
              FROM person)
     ) AS new_p_id;

-- ЗАДАНИЕ 13
-- напишите 2 инструкции SQL (DML), которые удаляют все новые заказы из упражнения № 12
-- на основе даты заказа. Затем удалите “греческую пиццу” из меню.
DELETE FROM person_order WHERE order_date = '2022-02-25';
DELETE FROM menu WHERE pizza_name = 'greek pizza';