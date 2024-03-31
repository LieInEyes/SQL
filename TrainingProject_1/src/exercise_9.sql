-- ЗАДАНИЕ 0
-- Создайте таблицу "person_audit" с такой же структурой, как у таблицы person, но внесите несколько дополнительных
-- изменений. Взгляните на приведенную ниже таблицу с описаниями для каждого столбца.

-- | Column     | Type                     | Description                                 |
-- | ------     | ------                   | ------                                      |
-- | created    | timestamp with time zone | timestamp when a new event has been created.  Default value is a current timestamp and NOT NULL |
-- | type_event | char(1)                  | possible values I (insert), D (delete), U (update). Default value is ‘I’. NOT NULL. Add check constraint `ch_type_event` with possible values ‘I’, ‘U’ and ‘D’ |
-- | row_id     | bigint                   | copy of person.id. NOT NULL                 |
-- | name       | varchar                  | copy of person.name (no any constraints)    |
-- | age        | integer                  | copy of person.age (no any constraints)     |
-- | gender     | varchar                  | copy of person.gender (no any constraints)  |
-- | address    | varchar                  | copy of person.address (no any constraints) |

-- Создайте тригер для БД с именем `fnc_trg_person_insert_audit`, которая должна обрабатывать `INSERT` DML-трафик и
-- копировать новую строку в таблицу person_audit.
-- Определите триггер базы данных с именем "trg_person_insert_audit" со следующими параметрами:
-- 1) триггер с параметром “FOR EACH ROW”
-- 2) триггер с параметром “AFTER INSERT”
-- 3) триггер вызывает триггерную функцию fnc_trg_person_insert_audit

-- После, выполните инструкцию INSERT INTO person(id, name, age, gender, address) VALUES (10,'Damir', 22, 'male', 'Irkutsk');

CREATE TABLE person_audit (
                              created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
                              type_event CHAR(1) NOT NULL
                                                                        DEFAULT 'I'
                                  CONSTRAINT ch_type_event
                                      CHECK (type_event = 'I'
                                          OR type_event = 'U'
                                          OR type_event = 'D'),
                              row_id BIGINT NOT NULL,
                              name VARCHAR,
                              age BIGINT,
                              gender VARCHAR,
                              address VARCHAR
);

CREATE FUNCTION fnc_trg_person_insert_audit() RETURNS TRIGGER AS $person_audit$
BEGIN
    INSERT INTO person_audit (type_event, row_id, name, age, gender, address)
    VALUES ('I', NEW.id, NEW.name, NEW.age, NEW.gender, NEW.address);
    RETURN NULL;
END;
$person_audit$
    LANGUAGE plpgsql;

CREATE TRIGGER trg_person_insert_audit
    AFTER INSERT ON person
    FOR EACH ROW
EXECUTE FUNCTION fnc_trg_person_insert_audit();

INSERT INTO person(id, name, age, gender, address) VALUES (10,'Damir', 22, 'male', 'Irkutsk');



-- ЗАДАНИЕ 1
-- Определите триггер "trg_person_update_audit" и соответствующую триггерную функцию "fnc_trg_person_update_audit"
-- для обработки всего трафика UPDATE в таблице person. Мы должны сохранить OLD состояния значений всех атрибутов.
-- После, выполните инструкции:
-- UPDATE person SET name = 'Bulat' WHERE id = 10;
-- UPDATE person SET name = 'Damir' WHERE id = 10;

CREATE FUNCTION fnc_trg_person_update_audit() RETURNS TRIGGER AS $person_audit$
BEGIN
    INSERT INTO person_audit (type_event, row_id, name, age, gender, address)
    SELECT 'U', OLD.id, OLD.name, OLD.age, OLD.gender, OLD.address;
    RETURN NULL;
END;
$person_audit$
    LANGUAGE plpgsql;

CREATE TRIGGER trg_person_update_audit
    AFTER UPDATE ON person
    FOR EACH ROW
EXECUTE FUNCTION fnc_trg_person_update_audit();



UPDATE person SET name = 'Bulat' WHERE id = 10;
UPDATE person SET name = 'Damir' WHERE id = 10;



-- ЗАДАНИЕ 2
-- Необходимо обработать инструкции DELETE и создать копию OLD состояний для всех значений атрибута.
-- Создайте триггер `trg_person_delete_audit` и соответствующую триггерную функцию `fnc_trg_person_delete_audit`.
-- После, выполните инструкции:
-- DELETE FROM person WHERE id = 10;
CREATE FUNCTION fnc_trg_person_delete_audit() RETURNS TRIGGER AS $person_audit$
BEGIN
    INSERT INTO person_audit (type_event, row_id, name, age, gender, address)
    SELECT 'D', OLD.id, OLD.name, OLD.age, OLD.gender, OLD.address;
    RETURN NULL;
END;
$person_audit$
    LANGUAGE plpgsql;

CREATE TRIGGER trg_person_delete_audit
    AFTER DELETE ON person
    FOR EACH ROW
EXECUTE FUNCTION fnc_trg_person_delete_audit();

DELETE FROM person WHERE id = 10;



-- ЗАДАНИЕ 3
-- Необходимо объединить всю нашу логику в один основной триггер с именем "trg_person_audit` и
-- новую соответствующую триггерную функцию `fnc_trg_person_audit`.
-- Весь трафик DML (INSERT ,UPDATE, DELETE) должен обрабатываться из одного функционального блока.
-- Явно определите отдельный блок IF-ELSE для каждого события (I, U, D)

-- Кроме того, пожалуйста, выполните следующие действия.
-- - удалить 3 старых триггера из таблицы person.
-- - удалить 3 старых триггерных функции
-- - выполнить "УСЕЧЕНИЕ" (или "УДАЛЕНИЕ") всех строк в нашей таблице "person_audit".

-- После, выполните инструкции:
-- `INSERT INTO person(id, name, age, gender, address)  VALUES (10,'Damir', 22, 'male', 'Irkutsk');`
-- `UPDATE person SET name = 'Bulat' WHERE id = 10;`
-- `UPDATE person SET name = 'Damir' WHERE id = 10;`
-- `DELETE FROM person WHERE id = 10;`

DROP TRIGGER IF EXISTS trg_person_insert_audit ON person;
DROP TRIGGER IF EXISTS trg_person_update_audit ON person;
DROP TRIGGER IF EXISTS trg_person_delete_audit ON person;

DROP FUNCTION IF EXISTS fnc_trg_person_insert_audit();
DROP FUNCTION IF EXISTS fnc_trg_person_update_audit();
DROP FUNCTION IF EXISTS fnc_trg_person_delete_audit();

TRUNCATE person_audit;

CREATE FUNCTION fnc_trg_person_audit() RETURNS TRIGGER AS $person_audit$
BEGIN
    IF (tg_op = 'INSERT') THEN
        INSERT INTO person_audit (type_event, row_id, name, age, gender, address)
        SELECT 'I', NEW.id, NEW.name, NEW.age, NEW.gender, NEW.address;
    ELSIF (tg_op = 'UPDATE') THEN
        INSERT INTO person_audit (type_event, row_id, name, age, gender, address)
        SELECT 'U', OLD.id, OLD.name, OLD.age, OLD.gender, OLD.address;
    ELSIF (tg_op = 'DELETE') THEN
        INSERT INTO person_audit (type_event, row_id, name, age, gender, address)
        SELECT 'D', OLD.id, OLD.name, OLD.age, OLD.gender, OLD.address;
    END IF;
    RETURN NULL;
END;
$person_audit$
    LANGUAGE plpgsql;

CREATE TRIGGER trg_person_audit
    AFTER INSERT OR UPDATE OR DELETE ON person
    FOR EACH ROW
EXECUTE FUNCTION fnc_trg_person_audit();

INSERT INTO person(id, name, age, gender, address) VALUES (10,'Damir', 22, 'male', 'Irkutsk');
UPDATE person SET name = 'Bulat' WHERE id = 10;
UPDATE person SET name = 'Damir' WHERE id = 10;
DELETE FROM person WHERE id = 10;



-- ЗАДАНИЕ 4
-- В предыдущем задании мы создали 2 представления базы данных, чтобы разделить данные из таблиц person по признаку пола.
-- Создайте 2 SQL-функции (пожалуйста, имейте в виду, не pl/pgsql-функции) с именами
-- - `fnc_persons_female` (должен возвращать данные о лицах женского пола)
-- - `fnc_persons_male` (должен возвращать данные о лицах мужского пола)
-- После, выполните инструкции:
--     SELECT *
--     FROM fnc_persons_male();
--
--     SELECT *
--     FROM fnc_persons_female();

CREATE FUNCTION fnc_persons_male() RETURNS SETOF person AS $$
SELECT *
FROM person
WHERE gender = 'male';
$$
    LANGUAGE sql;

CREATE FUNCTION fnc_persons_female() RETURNS SETOF person AS $$
SELECT *
FROM person
WHERE gender = 'female';
$$
    LANGUAGE sql;


SELECT *
FROM fnc_persons_male();

SELECT *
FROM fnc_persons_female();



-- ЗАДАНИЕ 5
-- Удалите функции из предыдущего задания из базы данных.
-- Напишите общую SQL-функцию с именем `fnc_persons`. У этой функции должен быть параметр pgender `IN` со значением по умолчанию = ‘female’.
--
-- Чтобы проверить себя и вызвать функцию, вы можете сделать заявление, как показано ниже (вау! вы можете работать с функцией, как с виртуальной таблицей, но с большей гибкостью!).
-- После, выполните инструкции:
--     select *
--     from fnc_persons(pgender := 'male');
--
--     select *
--     from fnc_persons();

DROP FUNCTION IF EXISTS fnc_persons_male();
DROP FUNCTION IF EXISTS fnc_persons_female();

CREATE FUNCTION fnc_persons(pgender VARCHAR DEFAULT 'female') RETURNS SETOF person AS $$
SELECT *
FROM person
WHERE gender = pgender;
$$
    LANGUAGE sql;

select *
from fnc_persons(pgender := 'male');

select *
from fnc_persons();



-- ЗАДАНИЕ 6
-- Создайте функцию pl/pgsql `fnc_person_visits_and_eats_on_date` на основе инструкции SQL,
-- которая находит названия пиццерий, которые посетитель (параметр `IN` person, значение по умолчанию - ‘Dmitriy’)
-- посетил и купил пиццу на сумму, меньшую указанной суммы в рублях (параметр `IN` pprice, значение по умолчанию - 500)
-- на конкретную дату (параметр `IN` pdate, значение по умолчанию - 8 января 2022 года).
-- После, выполните инструкции:
--     select *
--     from fnc_person_visits_and_eats_on_date(pprice := 800);
--
--     select *
--     from fnc_person_visits_and_eats_on_date(pperson := 'Anna',pprice := 1300,pdate := '2022-01-01');

CREATE FUNCTION fnc_person_visits_and_eats_on_date(
    pperson VARCHAR DEFAULT 'Dmitriy',
    pprice NUMERIC DEFAULT 500,
    pdate DATE DEFAULT '2022-01-08'
) RETURNS TABLE (pizzeria_name VARCHAR) AS $$
BEGIN
    RETURN QUERY
        SELECT pizzeria.name
        FROM person_visits
                 JOIN pizzeria
                      ON person_visits.pizzeria_id = pizzeria.id
                 JOIN menu
                      ON pizzeria.id = menu.pizzeria_id
                 JOIN person
                      ON person_visits.person_id = person.id
        WHERE person.name = pperson
          AND menu.price < pprice
          AND person_visits.visit_date = pdate;
END;
$$
    LANGUAGE plpgsql;

select *
from fnc_person_visits_and_eats_on_date(pprice := 800);

select *
from fnc_person_visits_and_eats_on_date(pperson := 'Anna',pprice := 1300,pdate := '2022-01-01');



-- ЗАДАНИЕ 7
-- Напишите функцию SQL или pl/pgsql `func_minimum`, входным параметром которой является массив чисел,
-- и функция должна возвращать минимальное значение.

-- После, выполните инструкции:
-- SELECT func_minimum(VARIADIC arr => ARRAY[10.0, -1.0, 5.0, 4.4]);

CREATE FUNCTION func_minimum(VARIADIC arr NUMERIC[]) RETURNS NUMERIC AS $$
SELECT MIN(arr[i])
FROM GENERATE_SUBSCRIPTS(arr, 1) index(i);
$$
    LANGUAGE SQL;

SELECT func_minimum(VARIADIC arr => ARRAY[10.0, -1.0, 5.0, 4.4]);



-- ЗАДАНИЕ 8
-- Напишите функцию SQL или pl/pgsql `fnc_fibonacci`, которая имеет входной параметр pstop
-- с типом integer (по умолчанию - 10), а выходной сигнал функции представляет собой таблицу,
-- в которой все числа Фибоначчи меньше, чем pstop.

-- После, выполните инструкции:
-- select * from fnc_fibonacci(100);
-- select * from fnc_fibonacci();

CREATE FUNCTION fnc_fibonacci(pstop INTEGER DEFAULT 10) RETURNS SETOF NUMERIC AS $$
with recursive fibonacci as (
    select 0 as prev, 1 as next
    union all
    select next as a, prev + next from fibonacci where next < pstop
) select prev from fibonacci
$$
    LANGUAGE SQL;

select * from fnc_fibonacci(100);
select * from fnc_fibonacci();
