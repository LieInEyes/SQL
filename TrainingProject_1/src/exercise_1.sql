-- ЗАДАНИЕ 0
-- напишите SQL-инструкцию, которая возвращает идентификатор меню и названия пиццы из таблицы "меню",
-- а также идентификатор пользователя и имя пользователя из таблицы "персона" в одном глобальном списке
-- (с именами столбцов, как показано в примере ниже), упорядоченном по object_id, а затем по столбцам object_name.
-- | object_id | object_name  |
-- | --------- | -----------  |
-- | 1         | Anna         |
-- | 1         | cheese pizza |
-- | ...       | ...          |
SELECT id AS object_id, pizza_name AS object_name
FROM menu
UNION
SELECT id, name
FROM person
ORDER BY object_id, object_name;

-- ЗАДАНИЕ 1
-- измените инструкцию SQL из “упражнения 00”, удалив столбец object_id.
-- Затем измените порядок по object_name для части данных из таблицы "person", а затем из таблицы "menu"
-- (как показано в примере ниже). Пожалуйста, сохраните дубликаты!
-- | object_name     |
-- | ------          |
-- | Andrey          |
-- | Anna            |
-- | ...             |
-- | cheese pizza    |
-- | cheese pizza    |
-- | ...             |
(SELECT name AS object_name
 FROM person
 ORDER BY object_name)
UNION ALL
(SELECT pizza_name
 FROM menu
 ORDER BY pizza_name);

-- ЗАДАНИЕ 2
-- напишите SQL-инструкцию, которая возвращает уникальные названия пицц из таблицы "меню"
-- и заказы по столбцу pizza_name в порядке убывания.
SELECT pizza_name FROM menu
UNION
SELECT pizza_name FROM menu
ORDER BY pizza_name DESC;

-- ЗАДАНИЕ 3
-- напишите инструкцию SQL, которая возвращает общие строки для атрибутов order_date,
-- person_id из таблицы `person_order` с одной стороны и visit_date, person_id из таблицы `person_visits`
-- с другой стороны (пожалуйста, смотрите пример ниже). Другими словами,найдите идентификаторы людей,
-- которые посетили и заказали пиццу в один и тот же день. На самом деле, пожалуйста,
-- добавьте заказ по action_date в режиме возрастания, а затем по person_id в режиме убывания.
-- | action_date | person_id |
-- | ------      | ------    |
-- | 2022-01-01  | 6         |
-- | 2022-01-01  | 2         |
-- | 2022-01-01  | 1         |
-- | 2022-01-03  | 7         |
-- | 2022-01-04  | 3         |
-- | ...         | ...       |
SELECT order_date AS action_date,
       person_id
FROM person_order
INTERSECT
SELECT visit_date,
       person_id
FROM person_visits
ORDER BY action_date, person_id DESC;

-- ЗАДАНИЕ 4
-- напишите SQL-инструкцию, которая возвращает разницу (минус) значений столбца person_id
-- с сохранением дубликатов между таблицами `person_order` и `person_visits` для order_date
-- и visit_date относятся к 7 января 2022 года
SELECT person_id
FROM person_order
WHERE order_date = '2022-01-07'
EXCEPT ALL
SELECT person_id
FROM person_visits
WHERE visit_date = '2022-01-07';

-- ЗАДАНИЕ 5
-- напишите SQL-инструкцию, которая возвращает все возможные комбинации между таблицами "person"
-- и "pizzeria", и, пожалуйста, установите порядок по идентификатору пользователя,
-- а затем по столбцам идентификатора пиццерии.
-- имейте в виду, что названия столбцов могут отличаться для вас.
-- | person.id  | person.name   | age   | gender | address | pizzeria.id | pizzeria.name | rating |
-- | ------     | ------        | ----- | ------ | ------  | ------      | ------        | ------ |
-- | 1          | Anna          | 16    | female | Moscow  | 1           | Pizza Hut     | 4.6    |
-- | 1          | Anna          | 16    | female | Moscow  | 2           | Dominos       | 4.3    |
-- | ...        | ...           | ...   | ...    | ...     | ...         | ...           | ...    |
SELECT person.id, person.name, age, gender, address, pizzeria.id, pizzeria.name, pizzeria.rating
FROM person
         CROSS JOIN pizzeria
ORDER BY person.id, pizzeria.id;

-- ЗАДАНИЕ 6
-- вернемся к заданию 3 и изменим нашу инструкцию SQL,
-- чтобы она возвращала имена людей вместо идентификаторов лиц, и изменим порядок по action_date в режиме возрастания,
-- а затем по person_name в режиме убывания.
-- | action_date | person_name |
-- | ------      | ------      |
-- | 2022-01-01  | Irina       |
-- | 2022-01-01  | Anna        |
-- | 2022-01-01  | Andrey      |
-- | ...         | ...         |
SELECT order_date AS action_date,
       (SELECT name
        FROM person
        WHERE id = person_order.person_id) AS person_name
FROM person_order
INTERSECT
SELECT visit_date,
       (SELECT name
        FROM person
        WHERE id = person_visits.person_id)
FROM person_visits
ORDER BY action_date, person_name DESC;

-- ЗАДАНИЕ 7
-- напишите SQL-инструкцию, которая возвращает дату заказа из таблицы `person_order` и
-- соответствующее имя человека (имя и возраст отформатированы, как в примере данных ниже),
-- который сделал заказ из таблицы `person`. Добавьте сортировку по обоим столбцам в режиме возрастания.
-- | order_date | person_information |
-- | ------     | ------             |
-- | 2022-01-01 | Andrey (age:21)    |
-- | 2022-01-01 | Andrey (age:21)    |
-- | 2022-01-01 | Anna (age:16)      |
-- | ...        | ...                |
SELECT person_order.order_date,
       concat(person.name, ' (Age:', person.age, ')') AS person_information
FROM person_order
         JOIN person
              ON person_order.person_id = person.id
ORDER BY person_order.order_date, person_information;

-- ЗАДАНИЕ 8
-- перепишите инструкцию SQL из задания 7, используя конструкцию NATURAL JOIN.
-- Результат должен быть таким же, как в предыдущем упражнении.
SELECT person_order.order_date,
       concat(person.name, ' (Age:', person.age, ')') AS person_information
FROM person_order
         NATURAL JOIN
     (SELECT id AS person_id, name, age, gender, address
      FROM person) AS person
ORDER BY person_order.order_date, person_information;

-- ЗАДАНИЕ 9
-- напишите 2 инструкции SQL, которые возвращают список названий пиццерий,
-- которые не посещались людьми, используя IN для 1-й и EXISTS для 2-й.
SELECT name
FROM pizzeria
WHERE id NOT IN
      (SELECT person_visits.pizzeria_id
       FROM person_visits);

SELECT name
FROM pizzeria
WHERE NOT EXISTS
          (SELECT pizzeria_id
           FROM person_visits
           WHERE pizzeria.id = person_visits.pizzeria_id);

-- ЗАДАНИЕ 10
-- напишите SQL-инструкцию, которая возвращает список имен людей, которые сделали заказ пиццы в соответствующей пиццерии.
-- отсортируйте заказ по 3 столбцам в порядке возрастания.
-- | person_name | pizza_name     | pizzeria_name |
-- | ------      | ------         | ------        |
-- | Andrey      | cheese pizza   | Dominos       |
-- | Andrey      | mushroom pizza | Dominos       |
-- | Anna        | cheese pizza   | Pizza Hut     |
-- | ...         | ...            | ...           |
SELECT person.name AS person_name,
       menu.pizza_name AS pizza_name,
       pizzeria.name AS pizzeria_name
FROM person_order
         JOIN person
              ON person.id=person_order.person_id
         JOIN menu
              ON person_order.menu_id=menu.id
         JOIN pizzeria
              ON menu.pizzeria_id = pizzeria.id
ORDER BY person_name, pizza_name, pizzeria_name;