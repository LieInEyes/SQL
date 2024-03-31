----------------------------------------------------------------------------
----          ВАЖНО ВАЖНО ВАЖНО ВАЖНО ВАЖНО ВАЖНО ВАЖНО ВАЖНО           ----
----                                                                    ----
----       НЕ ЗАПУСКАТЬ ВЕСЬ ФАЙЛ ЦЕЛИКОМ НА ВЫПОЛНЕНИЕ СКРИПТОВ        ----
----                                                                    ----
----                ВСЕ ЗАПРОСЫ ВЫПОЛНЯТЬ ОТДЕЛЬНО                      ----
----------------------------------------------------------------------------

-- удаляем схему, если существует и создаем новую
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

------------------------------------------------------------------------------------------------------------------
-- СОЗДАЕМ ТАБЛИЦЫ БЕЗ ПОДРОБНЫХ ОГРАНИЧЕНИЙ. ПРОСТО ПЕРЕЧИСЛЕНЫ ПОЛЯ, ИХ ТИПЫ, И ПЕРВИЧНЫЕ СВЯЗИ ДРУГ С ДРУГОМ --
------------------------------------------------------------------------------------------------------------------

-- создаем таблицу peers
CREATE TABLE IF NOT EXISTS peers
(
    nickname varchar(128) PRIMARY KEY,
    birthday date NOT NULL
);

-- создаем таблицу tasks
CREATE TABLE IF NOT EXISTS tasks
(
    title       varchar(128) PRIMARY KEY,
    parent_task varchar(128) REFERENCES tasks (title),
    max_xp      int check (max_xp > 0) NOT NULL
);

-- создаем таблицу checks
CREATE TABLE IF NOT EXISTS checks
(
    id     serial PRIMARY KEY,
    peer   varchar(128) REFERENCES peers (nickname) NOT NULL,
    task   varchar(128) REFERENCES tasks (title)    NOT NULL,
    "date" date                                     NOT NULL
);

-- создаем таблицу xp
CREATE TABLE IF NOT EXISTS xp
(
    id        serial PRIMARY KEY,
    "check"   int UNIQUE REFERENCES checks (id) NOT NULL,
    xp_amount int check (xp_amount > 0 )        NOT NULL
);

-- создаем тип перечисления для статуса проверки в таблице verter и p2p
CREATE TYPE check_status AS ENUM ('START', 'SUCCESS', 'FAILURE');

-- создаем таблицу verter
CREATE TABLE IF NOT EXISTS verter
(
    id      serial PRIMARY KEY,
    "check" int REFERENCES checks (id) NOT NULL,
    state   check_status               NOT NULL,
    time    time                       NOT NULL
);

-- создаем таблицу p2p
CREATE TABLE IF NOT EXISTS p2p
(
    id            serial PRIMARY KEY,
    "check"       int REFERENCES checks (id)               NOT NULL,
    checking_peer varchar(128) REFERENCES peers (nickname) NOT NULL,
    state         check_status                             NOT NULL,
    time          time                                     NOT NULL
);

-- создаем таблицу time_tracking
CREATE TABLE IF NOT EXISTS time_tracking
(
    id    serial PRIMARY KEY,
    peer  varchar(128) REFERENCES peers (nickname) NOT NULL,
    date  date                                     NOT NULL,
    time  time                                     NOT NULL,
    state int check (state = 1 OR state = 2)       NOT NULL
);

-- создаем таблицу recommendations
CREATE TABLE IF NOT EXISTS recommendations
(
    id               serial PRIMARY KEY,
    peer             varchar(128) REFERENCES peers (nickname) NOT NULL,
    recommended_peer varchar(128) REFERENCES peers (nickname) NOT NULL
);

-- создаем таблицу friends
CREATE TABLE IF NOT EXISTS friends
(
    id     serial PRIMARY KEY,
    peer_1 varchar(128) REFERENCES peers (nickname) NOT NULL,
    peer_2 varchar(128) REFERENCES peers (nickname) NOT NULL
);

-- создаем таблицу transferred_points
CREATE TABLE IF NOT EXISTS transferred_points
(
    id            serial PRIMARY KEY,
    checking_peer varchar(128) REFERENCES peers (nickname) NOT NULL,
    checked_peer  varchar(128) REFERENCES peers (nickname) NOT NULL,
    points_amount int check ( points_amount > 0 )          NOT NULL
);


---------------------------------------------------------------------------------------
-- СОЗДАЕМ ДОПОЛНИТЕЛЬНЫЕ ОГРАНИЧЕНИЯ ДЛЯ ТАБЛИЦ И ИХ ПОЛЕЙ (ФУНКЦИИ, ИНДЕКСЫ  И ТД) --
---------------------------------------------------------------------------------------

-- TASKS
-- создаем уникальный индекс для таблицы tasks поля parent_task при значении этого поля null
CREATE UNIQUE INDEX idx_tasks_parent_tasks_unique_null ON tasks ((parent_task IS NULL)) WHERE parent_task IS NULL;


-- CHECKS
-- функция для проверки успешно выполненного родительского задания
CREATE OR REPLACE FUNCTION fnc_success_checks_parent_task(cheecks_peer varchar(128), checks_task varchar(128)) RETURNS bool AS
$$
DECLARE
    t_parent_task varchar(128);
BEGIN
    IF checks_task = (SELECT tasks.title FROM tasks WHERE tasks.parent_task IS NULL) THEN
        RETURN true;
    ELSE
        SELECT tasks.parent_task
        INTO t_parent_task
        FROM tasks
        WHERE tasks.title = checks_task;

        RETURN exists(SELECT *
                      FROM checks
                               JOIN p2p on checks.id = p2p."check"
                               FULL JOIN verter on p2p."check" = verter."check"
                      WHERE checks.peer = cheecks_peer
                        AND checks.task = t_parent_task
                        AND p2p.state = 'SUCCESS'
                        AND (verter.state IS NULL
                          OR verter.state = 'SUCCESS'));
    END IF;
END
$$ LANGUAGE plpgsql;

-- добавляем огранчиение в таблицу checks, что попадает на проверку задание недоступное для выполнение пиру
ALTER TABLE checks
    ADD CONSTRAINT chk_checks_correct_task_for_peer
        check (fnc_success_checks_parent_task(checks.peer, checks.task));


-- P2P
-- создаем уникальный комбинированный индекс по колонке p2p."check" и p2p.state
-- это нам гарантирует, что с уникальным "check" могут быть только по одной записи старт, усех, неуспех в колонке state
CREATE UNIQUE INDEX idx_combo_p2p_check_state ON p2p ("check", state);

-- функцция для проверки, был ли старт проверки
CREATE OR REPLACE FUNCTION fnc_check_start_p2p(checks_id int, p2p_state check_status) RETURNS bool AS
$$
BEGIN
    IF (p2p_state = 'START') THEN
        RETURN true;
    ELSE
        RETURN exists(SELECT p2p.state
                      FROM p2p
                      WHERE p2p."check" = checks_id
                        AND p2p.state = 'START');
    END IF;
END
$$ LANGUAGE plpgsql;

-- добавляем огранчиение в таблицу p2p, если проверка не начиналась, то и завершить мы ее не можем
ALTER TABLE p2p
    ADD CONSTRAINT chk_checks_start_p2p
        check (fnc_check_start_p2p(p2p."check", p2p.state));

-- функцция для проверки, была ли уже завершена проверка
CREATE OR REPLACE FUNCTION fnc_check_finish_p2p(checks_id int, p2p_state check_status) RETURNS bool AS
$$
BEGIN
    IF (p2p_state = 'SUCCESS' OR p2p_state = 'FAILURE') THEN
        IF (exists(SELECT p2p.state
                   FROM p2p
                   WHERE p2p."check" = checks_id
                     AND (p2p.state = 'SUCCESS' OR p2p.state = 'FAILURE'))) THEN
            RETURN false;
        ELSE
            RETURN true;
        END IF;
    ELSE
        RETURN true;
    END IF;
END
$$ LANGUAGE plpgsql;

-- добавляем огранчиение в таблицу p2p, 1 проверка не может быть завершена дважды
ALTER TABLE p2p
    ADD CONSTRAINT chk_checks_finish_p2p check (fnc_check_finish_p2p(p2p."check", p2p.state));

-- функция проверяющая есть ли незвершенная проверка по заданию, пиру и проверяющему
CREATE OR REPLACE FUNCTION fnc_duplicate_checks_not_complited(p2p_checks_id int, p2p_checking_peer varchar(128),
                                                              p2p_state check_status) RETURNS bool AS
$$
DECLARE
    count_start  int;
    count_finish int;
    main_task    varchar(128);
    chcked_peer  varchar(128);
BEGIN
    IF p2p_state != 'START' THEN
        RETURN true;
    END IF;

    SELECT checks.task, checks.peer
    INTO main_task, chcked_peer
    FROM checks
    WHERE checks.id = p2p_checks_id;

    SELECT count(p2p.state)
    INTO count_start
    FROM checks
             FULL JOIN p2p ON checks.id = p2p."check"
    WHERE checks.peer = chcked_peer
      AND p2p.checking_peer = p2p_checking_peer
      AND checks.task = main_task
      AND p2p.state = 'START';

    SELECT count(p2p.state)
    INTO count_finish
    FROM checks
             FULL JOIN p2p ON checks.id = p2p."check"
    WHERE checks.peer = chcked_peer
      AND p2p.checking_peer = p2p_checking_peer
      AND checks.task = main_task
      AND (p2p.state = 'SUCCESS' OR p2p.state = 'FAILURE');

    RETURN count_start = count_finish;
END
$$ LANGUAGE plpgsql;

-- добавляем огранчиение в таблицу p2p, поиск незавершенной P2P проверки,
-- относящейся к конкретному заданию, пиру и проверяющему
ALTER TABLE p2p
    ADD CONSTRAINT chk_duplicate_checks_not_complited check (fnc_duplicate_checks_not_complited(p2p."check",
                                                                                                p2p.checking_peer,
                                                                                                p2p.state));


-- VERTER
-- создаем уникальный комбинированный индекс по колонке verter."check" и verter.state
-- это нам гарантирует, что с уникальным "check" могут быть только по одной записи старт, усех, неуспех в колонке state
CREATE UNIQUE INDEX idx_combo_verter_check_state ON verter ("check", state);

-- функция, которая проверяет была ли успешна проверка p2p по checks.id
CREATE OR REPLACE FUNCTION fnc_check_p2p_success(checks_id int) RETURNS bool AS
$$
BEGIN
    RETURN exists(SELECT *
                  FROM p2p
                  WHERE "check" = checks_id
                    AND state = 'SUCCESS');
END
$$ LANGUAGE plpgsql;

-- добавляем ограничение, была ли успешная проверка p2p по этому checks.id
ALTER TABLE verter
    ADD CONSTRAINT chk_verter_success_state_p2p check (fnc_check_p2p_success(verter."check"));

-- функцция для проверки, был ли старт проверки
CREATE OR REPLACE FUNCTION fnc_check_start_verter(checks_id int, verter_state check_status) RETURNS bool AS
$$
BEGIN
    IF (verter_state = 'START') THEN
        RETURN true;
    ELSE
        RETURN exists(SELECT verter.state
                      FROM verter
                      WHERE verter."check" = checks_id
                        AND verter.state = 'START');
    END IF;
END
$$ LANGUAGE plpgsql;

-- добавляем огранчиение в таблицу verter, если проверка не начиналась, то и завершить мы ее не можем
ALTER TABLE verter
    ADD CONSTRAINT chk_checks_start_verter check (fnc_check_start_verter(verter."check", verter.state));


-- функцция для проверки, была ли уже завершена проверка
CREATE OR REPLACE FUNCTION fnc_check_finish_verter(checks_id int, verter_state check_status) RETURNS bool AS
$$
BEGIN
    IF (verter_state = 'SUCCESS' OR verter_state = 'FAILURE') THEN
        IF (exists(SELECT verter.state
                   FROM verter
                   WHERE verter."check" = checks_id
                     AND (verter.state = 'SUCCESS' OR verter.state = 'FAILURE'))) THEN
            RETURN false;
        ELSE
            RETURN true;
        END IF;
    ELSE
        RETURN true;
    END IF;
END
$$ LANGUAGE plpgsql;

-- добавляем огранчиение в таблицу p2p, 1 проверка не может быть завершена дважды
ALTER TABLE verter
    ADD CONSTRAINT chk_verter_finish_p2p check (fnc_check_finish_verter(verter."check", verter.state));


-- TRANSFER_POINTS
-- добавляекм комбинированный уникальный индекс, гарантирующий уникальность пары пиров
CREATE UNIQUE INDEX idx_combo_unq_transferred_points_peers ON transferred_points (checking_peer, checked_peer);


---------------------------------------------------
-- СОЗДАЕМ ПРОЦЕДУРЫ ИМПОРТА И ЭКСПОРТА ДЛЯ .CSV --
---------------------------------------------------

-- Процедура которая принимает 2 параметра, таблица куда импортировать, и абсолютный путь до файла *.csv
CREATE OR REPLACE PROCEDURE prc_import_csv(
    table_name_csv varchar,
    path_csv varchar,
    delimiter varchar) AS
$$
BEGIN
    EXECUTE 'COPY ' || table_name_csv || ' FROM ' || '''' || path_csv || '''' || ' DELIMITER ' || '''' || delimiter ||
            '''' || ' CSV HEADER;';
END;
$$ LANGUAGE plpgsql;

-- для удобства копи паста:
-- путь rorgeelp - /home/lieineyes/School21/InWork/SQL2_Info21_v1.0-1/src/data_csv/peers.csv
-- названия таблиц - checks friends p2p peers recommendations tasks time_tracking transferred_points verter xp
CALL prc_import_csv('tasks', '/home/lieineyes/School21/InWork/SQL2_Info21_v1.0-1/src/data_csv/tasks.csv', ',');

-- Создаем процедуру экспорта данных из таблицы в файл .csv. Принимает название таблицы откуда забирать данные,
-- абсолютный путь до конечной директории, куда сохранять и под каким именем сохранитть файл
CREATE OR REPLACE PROCEDURE prc_export_csv(table_name_csv varchar, path_csv varchar, file_name varchar,
                                           delimiter varchar) AS
$$
BEGIN
    EXECUTE 'COPY ' || table_name_csv || ' TO ' || '''' || path_csv || file_name || '.csv' || '''' || ' DELIMITER ' ||
            '''' || delimiter || '''' || ' CSV HEADER;';
END;
$$ LANGUAGE plpgsql;

CALL prc_export_csv('peers', '/home/lieineyes/School21/InWork/SQL2_Info21_v1.0-1/src/', 'new_data', ',');


-------------------------------
--ЗАПОЛНЯЕМ И ТЕСТИМ ТАБЛИЦЫ --
-------------------------------

--*********************************************************************************************
-- заполняем peers
INSERT INTO peers
VALUES ('takemiym', '1990-08-01'),
       ('schrader', '2002-08-02'),
       ('clemenha', '1984-08-10'),
       ('starfigd', '1973-09-21'),
       ('sandorme', '2005-08-12'),
       ('judgejal', '1997-09-12'),
       ('murkybee', '1999-10-09'),
       ('durranha', '2002-05-07'),
       ('rosmertt', '1993-08-21'),
       ('vileplme', '2001-09-12');

--*********************************************************************************************
--*********************************************************************************************
-- заполняем таблицу tasks
INSERT INTO tasks
VALUES ('C2_SimpleBashUtils', null, 250),
       ('C3_s21_string+', 'C2_SimpleBashUtils', 500),
       ('C4_s21_math', 'C2_SimpleBashUtils', 300),
       ('C5_s21_decimal', 'C2_SimpleBashUtils', 350),
       ('C6_s21_matrix', 'C5_s21_decimal', 200),
       ('C7_SmartCalc_v1.0', 'C6_s21_matrix', 500),
       ('C8_3DViewer_v1.0', 'C7_SmartCalc_v1.0', 750),
       ('D01_Linux', 'C3_s21_string+', 300),
       ('D02_Linux_Network', 'D01_Linux', 250),
       ('D03_LinuxMonitoring_v1.0', 'D02_Linux_Network', 350),
       ('D04_LinuxMonitoring_v2.0', 'D03_LinuxMonitoring_v1.0', 350),
       ('D05_SimpleDocker', 'D03_LinuxMonitoring_v1.0', 300),
       ('D06_CICD', 'D05_SimpleDocker', 300),
       ('CPP1_s21_matrix+', 'C8_3DViewer_v1.0', 300),
       ('CPP2_s21_containers', 'CPP1_s21_matrix+', 350),
       ('CPP3_SmartCalc_v2.0', 'CPP2_s21_containers', 600),
       ('CPP4_3DViewer_v2.0', 'CPP3_SmartCalc_v2.0', 750),
       ('CPP5_3DViewer_v2.1', 'CPP4_3DViewer_v2.0', 600),
       ('CPP6_3DViewer_v2.2', 'CPP4_3DViewer_v2.0', 800),
       ('CPP7_MLP', 'CPP4_3DViewer_v2.0', 700),
       ('CPP8_PhotoLab_v1.0', 'CPP4_3DViewer_v2.0', 450),
       ('CPP9_MonitoringSystem', 'CPP4_3DViewer_v2.0', 1000),
       ('A1_Maze', 'CPP4_3DViewer_v2.0', 300),
       ('A2_SimpleNavigator_v1.0', 'A1_Maze', 400),
       ('A3_Parallels', 'A2_SimpleNavigator_v1.0', 300),
       ('A4_Crypto', 'A2_SimpleNavigator_v1.0', 350),
       ('A5_s21_memory', 'A2_SimpleNavigator_v1.0', 400),
       ('A6_Transactions', 'A2_SimpleNavigator_v1.0', 700),
       ('A7_DNA_Analyzer', 'A2_SimpleNavigator_v1.0', 800),
       ('A8_Algorithmic_trading', 'A2_SimpleNavigator_v1.0', 800),
       ('SQL1_Bootcamp', 'C8_3DViewer_v1.0', 1500),
       ('SQL2_Info21_v1.0', 'SQL1_Bootcamp', 500),
       ('SQL3_RetailAnalitycs_v1.0', 'SQL2_Info21_v1.0', 600);

-- проверка ограничений таблицы tasks
-- max_xp > 0
INSERT INTO tasks
VALUES ('C2_SimpleBashUtils', 'A2_SimpleNavigator_v1.0', -1);
--  несуществующее родительское задание (title)
INSERT INTO tasks
VALUES ('C2_SimpleBashUtils', 'Simple', 250);

--*********************************************************************************************
--*********************************************************************************************
-- заполняем таблицу checks, p2p, verter и transferred_points
---------------------------------------------------------
INSERT INTO checks (peer, task, date)
VALUES ('takemiym', 'C2_SimpleBashUtils', '01-08-2023');

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (1, 'vileplme', 'START', current_time),
       (1, 'vileplme', 'SUCCESS', current_time);

INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
VALUES ('vileplme', 'takemiym', 1);

INSERT INTO verter ("check", state, time)
VALUES (1, 'START', current_time),
       (1, 'SUCCESS', current_time);
---------------------------------------------------------
INSERT INTO checks (peer, task, date)
VALUES ('schrader', 'C2_SimpleBashUtils', '02-08-2023');

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (2, 'clemenha', 'START', current_time),
       (2, 'clemenha', 'FAILURE', current_time);

INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
VALUES ('clemenha', 'schrader', 1);
---------------------------------------------------------
INSERT INTO checks (peer, task, date)
VALUES ('takemiym', 'C3_s21_string+', '02-08-2023');

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (3, 'rosmertt', 'START', current_time),
       (3, 'rosmertt', 'SUCCESS', current_time);

INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
VALUES ('rosmertt', 'takemiym', 1);


INSERT INTO verter ("check", state, time)
VALUES (3, 'START', current_time),
       (3, 'SUCCESS', current_time);
---------------------------------------------------------
INSERT INTO checks (peer, task, date)
VALUES ('schrader', 'C2_SimpleBashUtils', '03-08-2023');

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (4, 'durranha', 'START', current_time),
       (4, 'durranha', 'SUCCESS', current_time);

INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
VALUES ('durranha', 'schrader', 1);

INSERT INTO verter ("check", state, time)
VALUES (4, 'START', current_time),
       (4, 'SUCCESS', current_time);
---------------------------------------------------------
INSERT INTO checks (peer, task, date)
VALUES ('takemiym', 'C5_s21_decimal', '04-08-2023');

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (5, 'murkybee', 'START', current_time),
       (5, 'murkybee', 'SUCCESS', current_time);

INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
VALUES ('murkybee', 'takemiym', 1);

INSERT INTO verter ("check", state, time)
VALUES (5, 'START', current_time),
       (5, 'SUCCESS', current_time);
---------------------------------------------------------
INSERT INTO checks (peer, task, date)
VALUES ('schrader', 'C3_s21_string+', '05-08-2023');

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (6, 'takemiym', 'START', current_time),
       (6, 'takemiym', 'SUCCESS', current_time);

INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
VALUES ('takemiym', 'schrader', 1);

INSERT INTO verter ("check", state, time)
VALUES (6, 'START', current_time),
       (6, 'SUCCESS', current_time);
---------------------------------------------------------
INSERT INTO checks (peer, task, date)
VALUES ('schrader', 'D01_Linux', '07-08-2023');

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (7, 'judgejal', 'START', current_time),
       (7, 'judgejal', 'SUCCESS', current_time);

INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
VALUES ('judgejal', 'schrader', 1);
---------------------------------------------------------
INSERT INTO checks (peer, task, date)
VALUES ('schrader', 'D02_Linux_Network', '09-08-2023');

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (8, 'takemiym', 'START', current_time),
       (8, 'takemiym', 'SUCCESS', current_time);

UPDATE transferred_points
SET points_amount = points_amount + 1
WHERE checking_peer = 'takemiym'
  AND checked_peer = 'schrader';
---------------------------------------------------------
INSERT INTO checks (peer, task, date)
VALUES ('takemiym', 'C6_s21_matrix', '10-08-2023');

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (9, 'schrader', 'START', current_time),
       (9, 'schrader', 'SUCCESS', current_time);

INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
VALUES ('schrader', 'takemiym', 1);

INSERT INTO verter ("check", state, time)
VALUES (9, 'START', current_time),
       (9, 'SUCCESS', current_time);
---------------------------------------------------------
INSERT INTO checks (peer, task, date)
VALUES ('sandorme', 'C2_SimpleBashUtils', '12-08-2023');

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (10, 'clemenha', 'START', current_time),
       (10, 'clemenha', 'SUCCESS', current_time);

INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
VALUES ('clemenha', 'sandorme', 1);

INSERT INTO verter ("check", state, time)
VALUES (10, 'START', current_time),
       (10, 'FAILURE', current_time);
---------------------------------------------------------
INSERT INTO checks (peer, task, date)
VALUES ('sandorme', 'C2_SimpleBashUtils', '16-08-2023');

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (11, 'starfigd', 'START', current_time),
       (11, 'starfigd', 'SUCCESS', current_time);

INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
VALUES ('starfigd', 'sandorme', 1);

INSERT INTO verter ("check", state, time)
VALUES (11, 'START', current_time),
       (11, 'SUCCESS', current_time);
---------------------------------------------------------
INSERT INTO checks (peer, task, date)
VALUES ('sandorme', 'C2_SimpleBashUtils', '16-08-2023');

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (12, 'starfigd', 'START', current_time),
       (12, 'starfigd', 'FAILURE', current_time);

UPDATE transferred_points
SET points_amount = points_amount + 1
WHERE checking_peer = 'starfigd'
  AND checked_peer = 'sandorme';

---------------------------------------------------------
INSERT INTO checks (peer, task, date)
VALUES ('sandorme', 'C3_s21_string+', '17-08-2023');

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (13, 'starfigd', 'START', current_time),
       (13, 'starfigd', 'SUCCESS', current_time);

UPDATE transferred_points
SET points_amount = points_amount + 1
WHERE checking_peer = 'starfigd'
  AND checked_peer = 'sandorme';

INSERT INTO verter ("check", state, time)
VALUES (13, 'START', current_time),
       (13, 'SUCCESS', current_time);


-- проверка ограничений таблицы checks, p2p, verter
-- добавление записи с несуществующим пиром
INSERT INTO checks (peer, task, date)
VALUES ('fdghfgh', 'SimpleBashUtils', '18-08-2023');

-- добавление записи с несуществующим заданием
INSERT INTO checks (peer, task, date)
VALUES ('schrader', 'SimpleBash', '18-08-2023');

-- добавление записи с заданием, у которого не выполнен родитель
INSERT INTO checks (peer, task, date)
VALUES ('schrader', 'C6_s21_matrix', '22-09-2023');

-- добавляем запись в таблицу p2p где уже существует завершенная проверка
INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (13, 'starfigd', 'SUCCESS', current_time);

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (13, 'starfigd', 'FAILURE', current_time);

-- добавляем запись в таблицу verter где уже существует завершенная проверка
INSERT INTO verter ("check", state, time)
VALUES (13, 'SUCCESS', current_time);

INSERT INTO verter ("check", state, time)
VALUES (13, 'FAILURE', current_time);

-- добавляем корректную запись в таблицу checks
INSERT INTO checks (peer, task, date)
VALUES ('takemiym', 'C7_SmartCalc_v1.0', '17-08-2023');

-- пробуем завершить проверку p2p без старта
INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (17, 'starfigd', 'SUCCESS', current_time);

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (17, 'starfigd', 'FAILURE', current_time);

-- пробуем завершить проверку verter без старта
INSERT INTO verter ("check", state, time)
VALUES (17, 'SUCCESS', current_time);

INSERT INTO verter ("check", state, time)
VALUES (17, 'FAILURE', current_time);

-- добавляем старт проверки p2p
INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (17, 'starfigd', 'START', current_time);

INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
VALUES ('starfigd', 'takemiym', 1);

-- добавляем фейл проверки p2p
INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (17, 'starfigd', 'FAILURE', current_time);

-- пробуем стартануть проверку verter, где p2p проверка не прошла
INSERT INTO verter ("check", state, time)
VALUES (17, 'START', current_time);

-- пробуем создать общую проверку в таблице checks, где не выполнен родитель
INSERT INTO checks (peer, task, date)
VALUES ('takemiym', 'C8_3DViewer_v1.0', '17-08-2023');

-- создаем проверку, у которой будет начата проверка p2p, но не завершена.
INSERT INTO checks (peer, task, date)
VALUES ('schrader', 'D02_Linux_Network', '19-08-2023');

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (19, 'durranha', 'START', current_time);

UPDATE transferred_points
SET points_amount = points_amount + 1
WHERE checking_peer = 'durranha'
  AND checked_peer = 'schrader';

-- Создаем такую же проверку. Тот же проверяемый, то же задание и пробуем для него стартануть проверку p2p с тем же проверяющим
INSERT INTO checks (peer, task, date)
VALUES ('schrader', 'D02_Linux_Network', '22-08-2023');

INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (20, 'durranha', 'START', current_time);


--*********************************************************************************************
--*********************************************************************************************
-- заполняем таблицу xp
INSERT INTO xp ("check", xp_amount)
VALUES (1, 238),
       (3, 475),
       (4, 250),
       (5, 300),
       (6, 500),
       (7, 276),
       (8, 221),
       (9, 200),
       (11, 250),
       (13, 455);

-- проверяем на отсутствующее или некореектроне значение xp.'check'
INSERT INTO xp ("check", xp_amount)
VALUES (299, 238);

-- проверяем на отсутствующее или некорректное значение xp.xp_amount
INSERT INTO xp ("check", xp_amount)
VALUES (13, -1);

--*********************************************************************************************
--*********************************************************************************************
-- заполняем таблицу friends
INSERT INTO friends (peer_1, peer_2)
VALUES ('takemiym', 'schrader'),
       ('clemenha', 'starfigd'),
       ('sandorme', 'judgejal'),
       ('rosmertt', 'vileplme'),
       ('judgejal', 'takemiym');


--*********************************************************************************************
--*********************************************************************************************
-- заполняем таблицу recommendations
INSERT INTO recommendations (peer, recommended_peer)
VALUES ('takemiym', 'vileplme'),
       ('schrader', 'clemenha'),
       ('takemiym', 'murkybee'),
       ('schrader', 'takemiym'),
       ('sandorme', 'clemenha'),
       ('takemiym', 'starfigd');


--*********************************************************************************************
--*********************************************************************************************
-- проверяем таблицу transferred_points
-- проверяем с несуществующими или некорректными пирами, а также кривым значением points_amount
INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
VALUES ('takemiym', 'clemenha', -1);

-- пробуем создать дубликат пары пиров
INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
VALUES ('vileplme', 'takemiym', 1);

--*********************************************************************************************
--*********************************************************************************************
-- заполняем таблицу time_tracking
INSERT INTO time_tracking (peer, date, time, state)
VALUES ('takemiym', '2023-08-01', '10:15:25', 1),
       ('takemiym', '2023-08-01', '12:21:35', 2),
       ('takemiym', '2023-08-01', '12:29:44', 1),
       ('takemiym', '2023-08-01', '17:01:15', 2),

       ('schrader', '2023-08-03', '16:12:59', 1),
       ('schrader', '2023-08-03', '18:07:31', 2),

       ('judgejal', '2023-08-07', '09:17:43', 1),
       ('judgejal', '2023-08-07', '16:36:14', 2),

       ('murkybee', '2023-08-10', '09:32:18', 1),
       ('takemiym', '2023-08-10', '10:07:12', 1),
       ('takemiym', '2023-08-10', '12:02:47', 2),
       ('takemiym', '2023-08-10', '12:17:24', 1),
       ('murkybee', '2023-08-10', '13:03:23', 2),
       ('murkybee', '2023-08-10', '14:00:11', 1),
       ('takemiym', '2023-08-10', '14:09:12', 2),
       ('takemiym', '2023-08-10', '15:02:31', 1),
       ('takemiym', '2023-08-10', '17:31:14', 2),
       ('murkybee', '2023-08-10', '18:29:59', 2),

       ('sandorme', '2023-08-17', '08:39:55', 1),
       ('sandorme', '2023-08-17', '08:39:55', 2),

       ('durranha', '2023-08-19', '18:39:55', 1),
       ('durranha', '2023-08-19', '21:42:53', 2);
