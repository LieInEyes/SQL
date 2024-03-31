-- ЗАДАНИЕ 0
-- Создайте простой индекс BTree для каждого внешнего ключа в нашей базе данных.
-- Шаблон имени должен удовлетворять следующему правилу “idx_{имя_таблицы}_{имя_столбца}”.
-- Например, имя индекса BTree для столбца pizzeria_id в таблице "меню" равно "idx_menu_pizzeria_id`.
CREATE INDEX idx_menu_pizzeria_id
    ON menu (pizzeria_id);

CREATE INDEX idx_person_order_person_id
    ON person_order (person_id);
CREATE INDEX idx_person_order_menu_id
    ON person_order (menu_id);

CREATE INDEX idx_person_visits_pizzeria_id
    ON person_visits (pizzeria_id);
CREATE INDEX idx_person_visits_person_id
    ON person_visits (person_id);

-- ЗАДАНИЕ 1
-- напишите инструкцию SQL, которая возвращает названия пицц и соответствующих пиццерий. Сортировка не требуется.
-- | pizza_name   | pizzeria_name |
-- | ------       | ------        |
-- | cheese pizza | Pizza Hut     |
-- | ...          | ...           |
--
-- Примером доказательства является вывод команды "EXPLAIN ANALYZE".
--     ...
--     ->  Index Scan using idx_menu_pizzeria_id on menu m  (...)
--     ...
--
-- **Подсказка**: пожалуйста, подумайте, почему ваши индексы не работают напрямую и что мы должны сделать, чтобы это включить?
SET ENABLE_SEQSCAN = off;
SET ENABLE_SEQSCAN = on;
EXPLAIN ANALYZE SELECT menu.pizza_name AS pizza_name,
                       pizzeria.name AS pizzeria_name
                FROM menu
                         JOIN pizzeria
                              ON menu.pizzeria_id = pizzeria.id;

-- ЗАДАНИЕ 2
-- Создайте функциональный индекс в виде B-дерева с именем "idx_person_name" для имени столбца таблицы `person`.
-- Индекс должен содержать имена пользователей в верхнем регистре.
-- Напишите и предоставьте любой SQL-код с доказательством (EXPLAIN ANALYZE) того, что индекс idx_person_name работает.
CREATE INDEX idx_person_name
    ON person (UPPER(name));

SET ENABLE_SEQSCAN = off;
SET ENABLE_SEQSCAN = on;

EXPLAIN ANALYZE SELECT name
                FROM person
                WHERE UPPER(name) = 'PETER';

-- ЗАДАНИЕ 3
-- Пожалуйста, создайте лучший многоколоночный индекс B-дерева с именем `idx_person_order_multi`
-- для приведенной ниже инструкции SQL.
--     SELECT person_id, menu_id,order_date
--     FROM person_order
--     WHERE person_id = 8 AND menu_id = 19;
-- Команда "EXPLAIN ANALYZE" должна вернуть следующий шаблон. Обратите внимание на сканирование "Index Only Scan"!
-- Index Only Scan using idx_person_order_multi on person_order ...
-- Предоставьте любой SQL-код с доказательством (`EXPLAIN ANALYZE`) того, что индекс `idx_person_order_multi` работает.
CREATE INDEX idx_person_order_multi
    ON person_order (person_id, menu_id) INCLUDE (order_date);

SET ENABLE_SEQSCAN = off;
SET ENABLE_SEQSCAN = on;

EXPLAIN ANALYZE SELECT person_order.person_id, person_order.menu_id, person_order.order_date
                FROM person_order
                WHERE person_id = 8 AND menu_id = 19;

-- ЗАДАНИЕ 4
-- Создайте уникальный индекс BTree с именем `idx_menu_unique` в таблице `меню` для столбцов `pizzeria_id` и `pizza_name`.
-- Напишите и предоставьте любой SQL-код с доказательством (EXPLAIN ANALYZE) того, что индекс "idx_menu_unique" работает.
CREATE UNIQUE INDEX idx_menu_unique
    ON menu (pizzeria_id, pizza_name);

SET ENABLE_SEQSCAN = off;
SET ENABLE_SEQSCAN = on;

EXPLAIN ANALYZE SELECT *
                FROM menu
                WHERE pizzeria_id = 2 OR pizzeria_id = 4
                    AND pizza_name = 'cheese pizza';

-- ЗАДАНИЕ 5
-- Создайте частично уникальный индекс BTree с именем "idx_person_order_order_date" в таблице "person_order"
-- для атрибутов "person_id" и "menu_id" с частичной уникальностью для столбца "order_date" для даты ‘2022-01-01’.
-- Команда EXPLAIN ANALYZE должна вернуть следующий шаблон
-- Index Only Scan using idx_person_order_order_date on person_order …
CREATE UNIQUE INDEX idx_person_order_order_date
    ON person_order (person_id, menu_id)
    WHERE order_date = '2022-01-01';

SET ENABLE_SEQSCAN = off;
SET ENABLE_SEQSCAN = on;

EXPLAIN ANALYZE SELECT person_id, menu_id
                FROM person_order
                WHERE order_date = '2022-01-01';

-- ЗАДАНИЕ 6
-- Взгляните на приведенный ниже SQL с технической точки зрения (не обращайте внимания на логический пример этого оператора SQL).
--     SELECT
--         m.pizza_name AS pizza_name,
--         max(rating) OVER (PARTITION BY rating ORDER BY rating ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS k
--     FROM  menu m
--     INNER JOIN pizzeria pz ON m.pizzeria_id = pz.id
--     ORDER BY 1,2;
-- Создайте новый индекс BTree с именем “idx_1”, который должен улучшить показатель "Execution Time" этого SQL.
-- Предоставьте доказательства (EXPLAIN ANALYZE) того, что SQL был улучшен.
--
-- ** Подсказка **: это упражнение похоже на задачу “brute force”, чтобы найти хороший индекс покрытия,
-- поэтому перед новым тестированием удалите индекс `idx_1`.

-- ДО:
--     Sort  (cost=26.08..26.13 rows=19 width=53) (actual time=0.247..0.254 rows=19 loops=1)
--     "  Sort Key: m.pizza_name, (max(pz.rating) OVER (?))"
--     Sort Method: quicksort  Memory: 26kB
--     ->  WindowAgg  (cost=25.30..25.68 rows=19 width=53) (actual time=0.110..0.182 rows=19 loops=1)
--             ->  Sort  (cost=25.30..25.35 rows=19 width=21) (actual time=0.088..0.096 rows=19 loops=1)
--                 Sort Key: pz.rating
--                 Sort Method: quicksort  Memory: 26kB
--                 ->  Merge Join  (cost=0.27..24.90 rows=19 width=21) (actual time=0.026..0.060 rows=19 loops=1)
--                         Merge Cond: (m.pizzeria_id = pz.id)
--                         ->  Index Only Scan using idx_menu_unique on menu m  (cost=0.14..12.42 rows=19 width=22) (actual time=0.013..0.029 rows=19 loops=1)
--                             Heap Fetches: 19
--                         ->  Index Scan using pizzeria_pkey on pizzeria pz  (cost=0.13..12.22 rows=6 width=15) (actual time=0.005..0.008 rows=6 loops=1)
--     Planning Time: 0.711 ms
--     Execution Time: 0.338 ms
--
-- ПОСЛЕ:
--     Sort  (cost=26.28..26.33 rows=19 width=53) (actual time=0.144..0.148 rows=19 loops=1)
--     "  Sort Key: m.pizza_name, (max(pz.rating) OVER (?))"
--     Sort Method: quicksort  Memory: 26kB
--     ->  WindowAgg  (cost=0.27..25.88 rows=19 width=53) (actual time=0.049..0.107 rows=19 loops=1)
--             ->  Nested Loop  (cost=0.27..25.54 rows=19 width=21) (actual time=0.022..0.058 rows=19 loops=1)
--                 ->  Index Scan using idx_1 on …
--                 ->  Index Only Scan using idx_menu_unique on menu m  (cost=0.14..2.19 rows=3 width=22) (actual time=0.004..0.005 rows=3 loops=6)
--     …
--     Planning Time: 0.338 ms
--     Execution Time: 0.203 ms
CREATE INDEX idx_1
    ON pizzeria (rating);

SET ENABLE_SEQSCAN = off;
SET ENABLE_SEQSCAN = on;

EXPLAIN ANALYZE SELECT
                    m.pizza_name AS pizza_name,
                    max(rating) OVER (PARTITION BY rating ORDER BY rating ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS k
                FROM  menu m
                          INNER JOIN pizzeria pz
                                     ON m.pizzeria_id = pz.id
                ORDER BY 1,2;