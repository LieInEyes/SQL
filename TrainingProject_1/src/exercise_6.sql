-- ЗАДАНИЕ 0
-- Необходимо создать новую реляционную таблицу (пожалуйста, задайте имя "person_discounts") со следующими правилами:
-- 1 - установите атрибут id как первичный ключ (пожалуйста, посмотрите на столбец id в существующих таблицах и
--      выберите тот же тип данных).
-- 2 - установите для атрибутов person_id и pizzeria_id внешние ключи для соответствующих таблиц
--      (типы данных должны быть такими же, как для столбцов id в соответствующих родительских таблицах).
-- 3 - задайте явные имена для ограничений внешних ключей по шаблону fk_{имя_таблицы}_{имя_столбца},
--      например `fk_person_discounts_person_id`
-- 4 - добавьте атрибут скидки, чтобы сохранить значение скидки в процентах. Помните, что
--      величина скидки может быть числом с плавающей точкой (пожалуйста, просто используйте тип данных "numeric").
--      Поэтому выберите соответствующий тип данных, чтобы учесть эту возможность.
CREATE TABLE person_discounts (
                                  id BIGINT PRIMARY KEY,
                                  person_id BIGINT,
                                  pizzeria_id BIGINT,
                                  discount NUMERIC,

                                  CONSTRAINT fk_person_discounts_person_id FOREIGN KEY (person_id) REFERENCES person(id),
                                  CONSTRAINT fk_person_discounts_pizzeria_id FOREIGN KEY (pizzeria_id) REFERENCES pizzeria(id)
);

-- ЗАДАНИЕ 1
-- есть таблица "person_order", в которой хранится история заказов пользователя.
-- Напишите инструкцию DML ("INSERT INTO ... SELECT ..."),
-- которая вставляет новые записи в таблицу `person_discounts" на основе следующих правил.
-- 1 - берем агрегированное состояние по столбцам person_id и pizzeria_id
-- 2 - рассчитать величину персональной скидки по следующему псевдокоду:
--     `if “amount of orders” = 1 then
--         “discount” = 10.5
--     else if “amount of orders” = 2 then
--         “discount” = 22
--     else
--         “discount” = 30`
-- 3 - - чтобы сгенерировать первичный ключ для таблицы person_discounts, используйте приведенную ниже конструкцию SQL
--      (эта конструкция взята из области SQL WINDOW FUNCTION).
-- `... ROW_NUMBER( ) OVER ( ) AS id ...`
INSERT INTO person_discounts SELECT *
FROM (SELECT row_number() OVER() AS id,
             person_order.person_id,
             menu.pizzeria_id,
             (CASE
                  WHEN count(menu.pizzeria_id) = 1
                      THEN 10.5
                  WHEN count(menu.pizzeria_id) = 2
                      THEN 22
                  WHEN count(menu.pizzeria_id) > 2
                      THEN 30
                 END) AS discount
      FROM person_order
               JOIN menu
                    ON person_order.menu_id = menu.id
      GROUP BY person_order.person_id, menu.pizzeria_id) AS person_discounts_temp;

-- ЗАДАНИЕ 2
-- Напишите инструкцию SQL, которая возвращает заказы с актуальной ценой и ценой с примененной скидкой
-- для каждого человека в соответствующей пиццерии-ресторане и сортирует по имени человека и названию пиццы.
-- | name   | pizza_name     | price | discount_price | pizzeria_name |
-- | ------ | ------         | ----- | ------         | ------        |
-- | Andrey | cheese pizza   | 800   | 624            | Dominos       |
-- | Andrey | mushroom pizza | 1100  | 858            | Dominos       |
-- | ...    | ...            | ...   | ...            | ...           |
SELECT person.name AS name,
       menu.pizza_name AS pizza_name,
       menu.price AS price,
       menu.price - menu.price * (person_discounts.discount / 100) AS discount_price,
       pizzeria.name AS pizzeria_name
FROM person_order
         JOIN person
              ON person_order.person_id = person.id
         JOIN menu
              ON person_order.menu_id = menu.id
         JOIN pizzeria
              ON menu.pizzeria_id = pizzeria.id
         JOIN person_discounts
              ON person_discounts.pizzeria_id = pizzeria.id AND person_discounts.person_id = person.id
ORDER BY name, pizza_name;

-- ЗАДАНИЕ 3
-- Создайте уникальный индекс с несколькими столбцами (с именем `idx_person_discounts_unique`),
-- который предотвращает дублирование парных значений идентификаторов персоны и пиццерии.
-- После создания нового индекса, предоставьте любую простую инструкцию SQL,
-- подтверждающую использование индекса (используя "EXPLAIN ANALYZE").
-- Пример “доказательства”:
--     ...
--     Index Scan using idx_person_discounts_unique on person_discounts
--     ...
CREATE UNIQUE INDEX idx_person_discounts_unique
    ON person_discounts (person_id, pizzeria_id);

SET ENABLE_SEQSCAN = off;
SET ENABLE_SEQSCAN = on;

EXPLAIN ANALYZE SELECT *
                FROM person_discounts
                ORDER BY person_id, pizzeria_id;

-- ЗАДАНИЕ 4
-- Добавьте следующие правила ограничения для существующих столбцов таблицы "person_discounts".
-- 1 - столбец person_id не должен быть пустым (используйте имя ограничения "ch_nn_person_id")
-- 2 - столбец pizzeria_id не должен быть пустым (используйте имя ограничения "ch_nn_pizzeria_id")
-- 3 - столбец скидок не должен быть пустым (используйте имя ограничения `ch_nn_discount`)
-- 4 - по умолчанию значение столбца скидок должно составлять 0 процентов
-- 5 - столбец скидок должен содержать значения в диапазоне от 0 до 100 (используйте имя ограничения `ch_range_discount`).
ALTER TABLE person_discounts ADD CONSTRAINT ch_nn_person_id CHECK (person_id IS NOT NULL);
ALTER TABLE person_discounts ADD CONSTRAINT ch_nn_pizzeria_id CHECK (pizzeria_id IS NOT NULL);
ALTER TABLE person_discounts ADD CONSTRAINT ch_nn_discount CHECK (discount IS NOT NULL);
ALTER TABLE person_discounts ALTER COLUMN discount SET DEFAULT 0;
ALTER TABLE person_discounts ADD CONSTRAINT ch_range_discount CHECK (discount BETWEEN 0 AND 100);

-- ЗАДАНИЕ 5
-- Давайте применим эту политику комментариев к таблице `person_discounts` и ее столбцам, которые объясняют,
-- какова бизнес-цель таблицы и все включенные атрибуты.
COMMENT ON TABLE person_discounts
    IS 'Таблица отражающая накопленную скидку клиентами по пицериям где делали заказы';
COMMENT ON COLUMN person_discounts.id
    IS 'Порядковый номер записи в таблице person_discounts';
COMMENT ON COLUMN person_discounts.person_id
    IS 'Уникальный идентификатор клиента, который делал заказы';
COMMENT ON COLUMN person_discounts.pizzeria_id
    IS 'Уникальный идентификатор пицерии, в которой делал заказ и есть какая то скидка';
COMMENT ON COLUMN person_discounts.discount
    IS 'Размер скидки в %, для клиента в указанной пицерии';

-- ЗАДАНИЕ 6
-- Создадайте последовательность данных с именем `seq_person_discounts` (начиная со значения 1) и
-- установим значение по умолчанию для атрибута id таблицы `person_discounts`,
-- чтобы каждый раз автоматически получать значение из `seq_person_discounts`.
-- Имейте в виду, что ваш следующий порядковый номер равен 1, в этом случае,
-- установите фактическое значение для последовательности базы данных,
-- основанное на формуле “количество строк в таблице person_discounts” + 1.
-- В противном случае вы получите сообщение об ошибке, связанной с нарушением ограничения первичного ключа.
CREATE SEQUENCE seq_person_discounts
    START 1;

SELECT setval('seq_person_discounts',
              (SELECT MAX(person_discounts.id)
               FROM person_discounts) + 1, FALSE);

ALTER TABLE person_discounts ALTER COLUMN id SET DEFAULT (nextval('seq_person_discounts'));