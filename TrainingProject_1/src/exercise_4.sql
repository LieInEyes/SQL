-- ЗАДАНИЕ 0
--создайте 2 представления базы данных (с аналогичными атрибутами, как в исходной таблице)
-- на основе простой фильтрации по полу лиц.
-- Задайте соответствующие имена для представлений базы данных: `v_persons_female` и `v_persons_male`.
CREATE VIEW v_persons_female AS
SELECT *
FROM person
WHERE gender = 'female';

CREATE VIEW v_persons_male AS
SELECT *
FROM person
WHERE gender = 'male';

-- ЗАДАНИЕ 1
-- используйте 2 представления базы данных из предыдущего упражнения и напишите SQL,
-- чтобы получить женские и мужские имена людей в одном списке. Отсортируйте по имени человека.
-- | name   |
-- | -----  |
-- | Andrey |
-- | Anna   |
-- | ...    |
SELECT v_persons_female.name AS name
FROM v_persons_female
UNION ALL
SELECT v_persons_male.name
FROM v_persons_male
ORDER BY name;

-- ЗАДАНИЕ 2
-- создайте представление базы данных (с именем `v_generated_dates`),
-- которое должно “хранить” сгенерированные даты с 1 по 31 января 2022 года в типе DATE.
-- Не забудьте о порядке для столбца generated_date.
-- разрешено использовать generate_series(...)
-- | generated_date |
-- | ------         |
-- | 2022-01-01     |
-- | 2022-01-02     |
-- | ...            |
CREATE VIEW v_generated_dates AS
SELECT generated_date::DATE
FROM GENERATE_SERIES('2022-01-01'::DATE, '2022-01-31'::DATE, '1 days') AS generated_date
ORDER BY generated_date;

-- ЗАДАНИЕ 3
-- напишите SQL-инструкцию, которая возвращает пропущенные дни для посещений людей в январе 2022 года.
-- Используйте представление `v_generated_dates` для этой задачи и отсортируйте результат по столбцу missing_data.
-- | missing_date |
-- | ------       |
-- | 2022-01-11   |
-- | 2022-01-12   |
-- | ...          |
SELECT v_generated_dates.generated_date AS missing_date
FROM v_generated_dates
EXCEPT
SELECT person_visits.visit_date
FROM person_visits
ORDER BY missing_date;

-- ЗАДАНИЕ 4
-- напишите инструкцию SQL, которая удовлетворяет формуле `(R - S)=(SR)` .
-- Где R - таблица "person_visits" с фильтром ко 2 января 2022 года, S - также таблица "person_visits",
-- но с другим фильтром к 6 января 2022 года. Пожалуйста, произведите свои вычисления с наборами в столбце "person_id",
-- и этот столбец будет единственным в результате. Результат отсортируйте по столбцу "person_id",
-- а ваш окончательный SQL, пожалуйста, представьте в представлении базы данных `v_symmetric_union` (*).
CREATE VIEW v_symmetric_union AS
(SELECT person_visits.person_id
 FROM person_visits
 WHERE visit_date = '2022-01-02'
 EXCEPT
 SELECT person_visits.person_id
 FROM person_visits
 WHERE visit_date = '2022-01-06')
UNION
(SELECT person_visits.person_id
 FROM person_visits
 WHERE visit_date = '2022-01-06'
 EXCEPT
 SELECT person_visits.person_id
 FROM person_visits
 WHERE visit_date = '2022-01-02')
ORDER BY person_id;

-- ЗАДАНИЕ 5
-- создайте представление базы данных "v_price_with_discount", которое возвращает заказы пользователя с именами людей,
-- названиями пицц, реальной ценой и рассчитанным столбцом `discount_price`
-- (с примененной скидкой 10% и удовлетворяет формуле `цена - прайс*0.1`).
-- Результат отсортируйте по имени человека и названию пиццы и приведите столбец "discount_price" к целочисленному типу.
-- | name   |  pizza_name    | price | discount_price |
-- | ------ | ------         | ----- | ------         |
-- | Andrey | cheese pizza   | 800   | 720            |
-- | Andrey | mushroom pizza | 1100  | 990            |
-- | ...    | ...            | ...   | ...            |
CREATE VIEW v_price_with_discount AS
(SELECT person.name AS name,
        menu.pizza_name AS pizza_name,
        menu.price AS price,
        (m.discount_price - m.discount_price * 0.1)::INT AS discount_price
FROM person_order
         JOIN person
              ON person_order.person_id = person.id
         JOIN menu
              ON person_order.menu_id = menu.id
         JOIN (SELECT menu.id, menu.price AS discount_price
               FROM menu) AS m
              ON person_order.menu_id = m.id)
ORDER BY 1, 2;

-- ЗАДАНИЕ 6
-- создайте материализованное представление "mv_dmitriy_visits_and_eats" (с включенными данными) на основе инструкции SQL,
-- которая находит название пиццерии, которую Дмитрий посетил 8 января 2022 года и
-- мог съесть пиццу менее чем за 800 рублей.
-- Чтобы проверить себя, вы можете записать SQL в материализованное представление `mv_dmitriy_visits_and_eats` и
-- сравнить результаты с вашим предыдущим запросом.
CREATE MATERIALIZED VIEW mv_dmitriy_visits_and_eats AS
(SELECT pizzeria.name
FROM person_visits
         JOIN pizzeria
              ON person_visits.pizzeria_id = pizzeria.id
         JOIN menu
              ON pizzeria.id = menu.pizzeria_id
         JOIN person
              ON person_visits.person_id = person.id
WHERE person.name = 'Dmitriy'
  AND menu.price < 800
  AND person_visits.visit_date = '2022-01-08');

-- ЗАДАНИЕ 7
-- обновите данные в нашем материализованном представлении `mv_dmitriy_visits_and_eats` из предыдущего упражнения.
-- Перед этим действием, сгенерируйте еще один визит Дмитрия, который удовлетворяет SQL-предложению Materialized View,
-- за исключением пиццерии, которую мы можем видеть в результате задания 6.
-- После добавления нового посещения, пожалуйста, обновите состояние данных для `mv_dmitriy_visits_and_eats`.
INSERT INTO person_visits VALUES (
                                     (SELECT MAX(person_visits.id)
                                      FROM person_visits) + 1,
                                     (SELECT person.id
                                      FROM person
                                      WHERE person.name = 'Dmitriy'),
                                     5,
                                     '2022-01-08');

REFRESH MATERIALIZED VIEW mv_dmitriy_visits_and_eats;

-- ЗАДАНИЕ 8
-- удалите все созданные материальные представления
DROP VIEW IF EXISTS v_generated_dates, v_persons_female, v_persons_male, v_price_with_discount, v_symmetric_union;
DROP MATERIALIZED VIEW IF EXISTS mv_dmitriy_visits_and_eats;