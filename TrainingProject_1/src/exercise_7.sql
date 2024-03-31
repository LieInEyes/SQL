-- ЗАДАНИЕ 0
-- Напишите SQL-инструкцию, которая возвращает идентификаторы пользователей и соответствующее количество посещений
-- любых пиццерий, а также сортировку по количеству посещений в режиме убывания и сортировку по "person_id"
-- в режиме возрастания.
-- | person_id | count_of_visits |
-- | ------    | ------          |
-- | 9         | 4               |
-- | 4         | 3               |
-- | ...       | ...             |
SELECT person_id,
       count(person_id) AS count_of_visits
FROM person_visits
GROUP BY person_id
ORDER BY count_of_visits DESC, person_id;

-- ЗАДАНИЕ 1
-- Измените инструкцию SQL из задания 0 и верните имя пользователя (не идентификатор).
-- Дополнительное условие - нам нужно видеть только топ-4 пользователей с максимальным количеством посещений
-- в любых пиццериях и отсортированных по имени пользователя.
-- | name    | count_of_visits |
-- | ------  | ------          |
-- | Dmitriy | 4               |
-- | Denis   | 3               |
-- | ...     | ...             |
SELECT person.name,
       count(person.name) AS count_of_visits
FROM person_visits
         JOIN person
              ON person_visits.person_id = person.id
GROUP BY person.name
ORDER BY count_of_visits DESC, person.name
LIMIT 4;

-- ЗАДАНИЕ 2
-- Напишите SQL-инструкцию, чтобы увидеть 3 любимых ресторана по посещениям и заказам в одном списке
-- (добавьте столбец action_type со значениями "заказать" или "посетить", это зависит от данных из соответствующей
-- таблицы). Результат должен быть отсортирован по столбцу action_type в режиме возрастания и по столбцу count
-- в режиме убывания.
-- | name    | count | action_type |
-- | ------  | ----- | ------      |
-- | Dominos | 6     | order       |
-- | ...     | ...   | ...         |
-- | Dominos | 7     | visit       |
-- | ...     | ...   | ...         |
(SELECT pizzeria.name,
        count(pizzeria_id) AS count,
        'visit' AS action_type
 FROM person_visits
          JOIN pizzeria
               ON person_visits.pizzeria_id = pizzeria.id
 GROUP BY pizzeria.name
 ORDER BY count DESC
 LIMIT 3)
UNION
(SELECT pizzeria.name,
        count(pizzeria_id) AS count,
        'order' AS action_type
 FROM person_order
          JOIN menu
               ON person_order.menu_id = menu.id
          JOIN pizzeria
               ON menu.pizzeria_id = pizzeria.id
 GROUP BY pizzeria.name
 ORDER BY count DESC
 LIMIT 3)
ORDER BY action_type, count DESC;

-- ЗАДАНИЕ 3
-- Напишите инструкцию SQL, чтобы увидеть, как рестораны группируются по посещениям и заказам и объединяются
-- друг с другом с помощью названия ресторана. Вы можете использовать внутренний Sql из задания 2
-- (рестораны по посещениям и заказам) без ограничений по количеству строк.
-- Добавьте следующие правила:
-- 1 - подсчитайте сумму заказов и посещений для соответствующей пиццерии
--      (имейте в виду, что не все ключи от пиццерий представлены в обеих таблицах).
-- 2 - отсортируйте результаты по столбцу "общее количество" в порядке убывания и по "названию" в порядке возрастания.
-- | name      | total_count |
-- | ------    | ------      |
-- | Dominos   | 13          |
-- | DinoPizza | 9           |
-- | ...       | ...         |
WITH temp AS
         (SELECT *
          FROM
              (SELECT pizzeria.name AS visit_name,
                      count(pizzeria_id) AS visit_count,
                      'visit' AS visit_action_type
               FROM person_visits
                        JOIN pizzeria
                             ON person_visits.pizzeria_id = pizzeria.id
               GROUP BY pizzeria.name
               ORDER BY visit_count DESC) AS visit_temp
                  FULL JOIN
              (SELECT pizzeria.name AS order_name,
                      count(pizzeria_id) AS order_count,
                      'order' AS order_action_type
               FROM person_order
                        JOIN menu
                             ON person_order.menu_id = menu.id
                        JOIN pizzeria
                             ON menu.pizzeria_id = pizzeria.id
               GROUP BY pizzeria.name
               ORDER BY order_count DESC) AS order_temp
              ON visit_temp.visit_name = order_temp.order_name)
SELECT (CASE
            WHEN temp.visit_name IS NULL
                THEN temp.order_name
            WHEN temp.order_name IS NULL
                THEN temp.visit_name
            ELSE temp.visit_name
    END) AS name,
       (CASE
            WHEN temp.visit_count IS NULL
                THEN temp.order_count
            WHEN temp.order_count IS NULL
                THEN temp.visit_count
            ELSE temp.visit_count + temp.order_count
           END) AS total_count
FROM temp
ORDER BY total_count DESC, name;

-- ЗАДАНИЕ 4
-- Напишите SQL-запрос, который возвращает имя посетителя и соответствующее количество посещений любых пиццерий,
-- если этот человек посещал их более 3 раз (> 3).
-- Запрещено использовать WHERE
-- | name    | count_of_visits |
-- | ------  | ------          |
-- | Dmitriy | 4               |
WITH temp AS
         (SELECT person_id,
                 count(person_id) AS count_of_visits
          FROM person_visits
          GROUP BY person_id
          ORDER BY count_of_visits DESC, person_id)
SELECT person.name,
       temp.count_of_visits
FROM temp
         JOIN person
              ON temp.person_id = person.id
ORDER BY count_of_visits DESC
LIMIT 1;

-- ЗАДАНИЕ 5
-- Напишите простой SQL-запрос, который возвращает список уникальных имен пользователей,
-- которые делали заказы в любых пиццериях. Результат должен быть отсортирован по имени пользователя.
-- Запрещено использовать GROUP BY, любые типы UNION
-- | name   |
-- | ------ |
-- | Andrey |
-- | Anna   |
-- | ...    |
SELECT DISTINCT person.name
FROM person_order
         JOIN person
              ON person_order.person_id = person.id
ORDER BY person.name;

-- ЗАДАНИЕ 6
-- Напишите SQL-запрос, который возвращает количество заказов, среднюю цену, максимальную и минимальную цены
-- на проданную пиццу в соответствующей пиццерии-ресторане. Результат должен быть отсортирован по названию пиццерии.
-- Округлите вашу среднюю цену до 2 чисел с плавающей запятой.
-- | name       | count_of_orders | average_price | max_price | min_price |
-- | ------     | ------          | ------        | ------    | ------    |
-- | Best Pizza | 5               | 780           | 850       | 700       |
-- | DinoPizza  | 5               | 880           | 1000      | 800       |
-- | ...        | ...             | ...           | ...       | ...       |
SELECT count.name,
       count.count AS count_of_orders,
       round(price.average_price, 2) AS average_price,
       price.max_price,
       price.min_price
FROM
    (SELECT pizzeria.name,
            count(pizzeria_id) AS count
     FROM person_order
              JOIN menu
                   ON person_order.menu_id = menu.id
              JOIN pizzeria
                   ON menu.pizzeria_id = pizzeria.id
     GROUP BY pizzeria.name
     ORDER BY pizzeria.name) AS count
        JOIN
    (SELECT pizzeria.name,
            MAX(menu.price) AS max_price,
            MIN(menu.price) AS min_price,
            AVG(menu.price) AS average_price
     FROM person_order
              JOIN menu
                   ON person_order.menu_id = menu.id
              JOIN pizzeria
                   ON menu.pizzeria_id = pizzeria.id
     GROUP BY pizzeria.name
     ORDER BY pizzeria.name) AS price
    ON count.name = price.name
ORDER BY count.name;

-- ЗАДАНИЕ 7
-- Напишите SQL-инструкцию, которая возвращает общий средний рейтинг (имя выходного атрибута - global_rating)
-- для всех ресторанов. Округлите ваш средний рейтинг до 4 чисел с плавающей запятой.
SELECT round(AVG(pizzeria.rating), 4) AS global_rating
FROM pizzeria;

-- ЗАДАНИЕ 8
-- Конкретный человек посещает пиццерии только в своем городе.
-- Напишите SQL-запрос, который возвращает адрес, название пиццерии и количество заказов людей.
-- Результат должен быть отсортирован по адресу, а затем по названию ресторана.
-- | address | name       |count_of_orders |
-- | ------  | ------     |------          |
-- | Kazan   | Best Pizza |4               |
-- | Kazan   | DinoPizza  |4               |
-- | ...     | ...        | ...            |
SELECT person.address, pizzeria.name, count(pizzeria.name) AS count_of_orders
FROM person_order
         JOIN person
              ON person_order.person_id = person.id
         JOIN menu
              ON person_order.menu_id = menu.id
         JOIN pizzeria
              ON menu.pizzeria_id = pizzeria.id
GROUP BY person.address, pizzeria.name
ORDER BY person.address, pizzeria.name;

-- ЗАДАНИЕ 9
-- Напишите SQL-инструкцию, которая возвращает агрегированную информацию по адресу человека,
-- результат “Максимальный возраст - (Минимальный возраст / Максимальный возраст максимума)”,
-- который представлен в виде столбца формулы, следующий - средний возраст по адресу и
-- результат сравнения столбцов формулы и среднего значения (другими словами, если формула больше среднего значения,
-- тогда значение True, в противном случае значение False).
-- Результат должен быть отсортирован по столбцу адреса.
-- | address | formula |average | comparison |
-- | ------  | ------  |------  |------      |
-- | Kazan   | 44.71   |30.33   | true       |
-- | Moscow  | 20.24   | 18.5   | true       |
-- | ...     | ...     | ...    | ...        |
SELECT address,
       round(MAX(age) - (MIN(age)::numeric / MAX(age)), 2) AS formula,
       round(AVG(age), 2) AS average,
       round(MAX(age) - (MIN(age)::numeric / MAX(age)), 2) > round(AVG(age), 2) AS comparison
FROM person
GROUP BY address
ORDER BY address;