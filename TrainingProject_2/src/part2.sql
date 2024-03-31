----------------------------------------------------------------------------
----          ВАЖНО ВАЖНО ВАЖНО ВАЖНО ВАЖНО ВАЖНО ВАЖНО ВАЖНО           ----
----                                                                    ----
----       НЕ ЗАПУСКАТЬ ВЕСЬ ФАЙЛ ЦЕЛИКОМ НА ВЫПОЛНЕНИЕ СКРИПТОВ        ----
----                                                                    ----
----                ВСЕ ЗАПРОСЫ ВЫПОЛНЯТЬ ОТДЕЛЬНО                      ----
----------------------------------------------------------------------------


---- TASK 1 ---- TASK 1 ---- TASK 1 ---- TASK 1 ---- TASK 1 ---- TASK 1 ---- TASK 1 ---- TASK 1 ---- TASK 1 ----
CREATE OR REPLACE PROCEDURE prc_add_p2p_check(checks_checked_peer varchar(128), p2p_checking_peer varchar(128),
                                              name_task varchar(128), status_check check_status, time_check time) AS
$$
DECLARE
    check_id int;
BEGIN
    IF status_check = 'START' THEN
        INSERT INTO checks (peer, task, date) VALUES (checks_checked_peer, name_task, current_date);
        SELECT max(checks.id)
        INTO check_id
        FROM checks;
    ELSE
        SELECT checks.id
        INTO check_id
        FROM checks
                 JOIN p2p on checks.id = p2p."check"
        WHERE checks.peer = checks_checked_peer
          AND checks.task = name_task
          AND p2p.checking_peer = p2p_checking_peer
        GROUP BY checks.id
        HAVING count(p2p.state) = 1;
    END IF;
    INSERT INTO p2p ("check", checking_peer, state, time)
    VALUES (check_id, p2p_checking_peer, status_check, time_check);
END;
$$ LANGUAGE plpgsql;

-- Тестим TASK1
-- добавляем завершение проверка к уже начатой проверке
CALL prc_add_p2p_check('schrader', 'durranha', 'D02_Linux_Network', 'SUCCESS', '01:12:24');

INSERT INTO xp ("check", xp_amount)
VALUES (19, 235);

-- добавляем новую проверку
CALL prc_add_p2p_check('takemiym', 'judgejal', 'C7_SmartCalc_v1.0', 'START', '05:33:17');
-- для корректности данных в таблицах добавляем в таблицу transferred_points пир поинты
INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
VALUES ('judgejal', 'takemiym', 1);
-- добавляем завершение проверки
CALL prc_add_p2p_check('takemiym', 'judgejal', 'C7_SmartCalc_v1.0', 'FAILURE', '05:33:17');

-- Добавляем старт созданной ранее проверки
INSERT INTO p2p ("check", checking_peer, state, time)
VALUES (20, 'takemiym', 'START', '06:19:28');
-- для корректности данных в таблицах добавляем в таблицу transferred_points пир поинты
UPDATE transferred_points
SET points_amount = points_amount + 1
WHERE checking_peer = 'takemiym'
  AND checked_peer = 'schrader';
-- пробуем стартануть проверку, у которой есть дубликат по проверяемому, проверяющему, заданию и тоже не завершенная
CALL prc_add_p2p_check('schrader', 'takemiym', 'D02_Linux_Network', 'START', '07:44:04');
-- для корректности завершаем проверку
CALL prc_add_p2p_check('schrader', 'takemiym', 'D02_Linux_Network', 'FAILURE', '07:58:04');


---- TASK 2 ---- TASK 2 ---- TASK 2 ---- TASK 2 ---- TASK 2 ---- TASK 2 ---- TASK 2 ---- TASK 2 ---- TASK 2 ----
CREATE OR REPLACE PROCEDURE prc_add_verter_check(checks_checked_peer varchar(128), name_task varchar(128),
                                                 status_check check_status, time_check time) AS
$$
DECLARE
    check_id int;
BEGIN
    SELECT max(checks.id)
    INTO check_id
    FROM checks
             JOIN p2p ON checks.id = p2p."check"
    WHERE checks.peer = checks_checked_peer
      AND checks.task = name_task
      AND p2p.state = 'SUCCESS';

    INSERT INTO verter ("check", state, time) VALUES (check_id, status_check, time_check);
END;
$$ LANGUAGE plpgsql;


-- Тестим TASK2
-- добавляем несколько проверок p2p чяерез процедуру реализованную в 1 задании
CALL prc_add_p2p_check('murkybee', 'rosmertt', 'C2_SimpleBashUtils', 'START', '08:44:04');
INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
VALUES ('rosmertt', 'murkybee', 1);
CALL prc_add_p2p_check('murkybee', 'rosmertt', 'C2_SimpleBashUtils', 'SUCCESS', '09:11:03');
INSERT INTO verter ("check", state, time)
VALUES (23, 'START', '09:12:11');
INSERT INTO verter ("check", state, time)
VALUES (23, 'FAILURE', '09:13:21');

CALL prc_add_p2p_check('murkybee', 'rosmertt', 'C2_SimpleBashUtils', 'START', '09:44:04');
UPDATE transferred_points
SET points_amount = points_amount + 1
WHERE checking_peer = 'rosmertt'
  AND checked_peer = 'murkybee';
CALL prc_add_p2p_check('murkybee', 'rosmertt', 'C2_SimpleBashUtils', 'FAILURE', '09:44:04');

CALL prc_add_p2p_check('murkybee', 'rosmertt', 'C2_SimpleBashUtils', 'START', '10:44:04');
UPDATE transferred_points
SET points_amount = points_amount + 1
WHERE checking_peer = 'rosmertt'
  AND checked_peer = 'murkybee';
CALL prc_add_p2p_check('murkybee', 'rosmertt', 'C2_SimpleBashUtils', 'SUCCESS', '10:44:04');

CALL prc_add_p2p_check('murkybee', 'rosmertt', 'C2_SimpleBashUtils', 'START', '11:44:04');
UPDATE transferred_points
SET points_amount = points_amount + 1
WHERE checking_peer = 'rosmertt'
  AND checked_peer = 'murkybee';
CALL prc_add_p2p_check('murkybee', 'rosmertt', 'C2_SimpleBashUtils', 'SUCCESS', '11:44:04');

-- добавляем проверку вертера последней успешно выболненной проверки p2p по проверяемому, проверяющему и заданию
CALL prc_add_verter_check('murkybee', 'C2_SimpleBashUtils', 'START', '11:45:12');
CALL prc_add_verter_check('murkybee', 'C2_SimpleBashUtils', 'SUCCESS', '11:46:02');
INSERT INTO xp ("check", xp_amount)
VALUES (26, 245);

-- добавляем несколько проверок p2p чяерез процедуру реализованную в 1 задании
CALL prc_add_p2p_check('vileplme', 'judgejal', 'C2_SimpleBashUtils', 'START', '12:05:44');
INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
VALUES ('judgejal', 'vileplme', 1);
CALL prc_add_p2p_check('vileplme', 'judgejal', 'C2_SimpleBashUtils', 'FAILURE', '12:44:12');

CALL prc_add_p2p_check('vileplme', 'judgejal', 'C2_SimpleBashUtils', 'START', '12:49:17');
UPDATE transferred_points
SET points_amount = points_amount + 1
WHERE checking_peer = 'judgejal'
  AND checked_peer = 'vileplme';
CALL prc_add_p2p_check('vileplme', 'judgejal', 'C2_SimpleBashUtils', 'FAILURE', '12:51:16');
-- пытаемся стартануть вертер для завершенных проверок без статуса успех (не сможет сделать вставку, так как не найдет нужного ай ди и не пройдет по условию нот нул
CALL prc_add_verter_check('vileplme', 'C2_SimpleBashUtils', 'START', '12:51:18');


---- TASK 3 ---- TASK 3 ---- TASK 3 ---- TASK 3 ---- TASK 3 ---- TASK 3 ---- TASK 3 ---- TASK 3 ---- TASK 3 ----

-- создаем функцию для обработки добавления/обновления записи в таблице transferred_points
CREATE OR REPLACE PROCEDURE prc_add_or_update_transferred_points(transferred_points_checking_peer varchar(128),
                                                                 transferred_points_checked_peer varchar(128)) AS
$$
BEGIN
    IF exists(SELECT *
              FROM transferred_points
              WHERE checking_peer = transferred_points_checking_peer
                AND checked_peer = transferred_points_checked_peer) THEN
        UPDATE transferred_points
        SET points_amount = points_amount + 1
        WHERE checking_peer = transferred_points_checking_peer
          AND checked_peer = transferred_points_checked_peer;
    ELSE
        INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
        VALUES (transferred_points_checking_peer, transferred_points_checked_peer, 1);
    END IF;
END
$$ LANGUAGE plpgsql;

-- создаем функцию для тригера
CREATE OR REPLACE FUNCTION fnc_trg_update_transferred_points_after_insert_p2p() RETURNS TRIGGER AS
$$
DECLARE
    t_checked_peer varchar(128);
BEGIN
    SELECT checks.peer
    INTO t_checked_peer
    FROM checks
             JOIN p2p ON checks.id = p2p."check"
    WHERE p2p."check" = NEW."check";

    IF (NEW.state = 'START') THEN
        CALL prc_add_or_update_transferred_points(NEW.checking_peer, t_checked_peer);
    END IF;

    RETURN NEW;
END
$$ LANGUAGE plpgsql;

-- создаем тригер, отрабатывающий после вставки проверки p2p
CREATE OR REPLACE TRIGGER trg_update_transferred_points_after_insert_p2p
    AFTER INSERT
    ON p2p
    FOR EACH ROW
EXECUTE PROCEDURE fnc_trg_update_transferred_points_after_insert_p2p();

-- Тестим TASK3
-- Стартуем проверку p2p через prc_add_p2p_check с уже существующей парой пиров
CALL prc_add_p2p_check('takemiym', 'vileplme', 'C7_SmartCalc_v1.0', 'START', '13:05:18');
CALL prc_add_p2p_check('takemiym', 'vileplme', 'C7_SmartCalc_v1.0', 'SUCCESS', '13:25:37');
INSERT INTO xp ("check", xp_amount)
VALUES (29, 500);

-- Стартуем проверку p2p через prc_add_p2p_check для несуществующей пары пиров в transferred_points
CALL prc_add_p2p_check('schrader', 'rosmertt', 'D02_Linux_Network', 'START', '14:15:18');
CALL prc_add_p2p_check('schrader', 'rosmertt', 'D02_Linux_Network', 'FAILURE', '14:16:18');


---- TASK 4 ---- TASK 4 ---- TASK 4 ---- TASK 4 ---- TASK 4 ---- TASK 4 ---- TASK 4 ---- TASK 4 ---- TASK 4 ----

-- функция для проверки полученного хр относительного максимально возможного по текущему заданию
CREATE OR REPLACE FUNCTION fnc_check_xp_amount(xp_check int, xp_xp_amount int) RETURNS bool AS
$$
BEGIN
    IF xp_xp_amount <= (SELECT tasks.max_xp
                        FROM checks
                                 JOIN tasks ON checks.task = tasks.title
                        WHERE checks.id = xp_check) THEN
        RETURN true;
    ELSE
        RETURN false;
    END IF;
END
$$ LANGUAGE plpgsql;

-- функция для проверки успешности задания по checks_id
CREATE OR REPLACE FUNCTION fnc_check_succes_task(xp_check int) RETURNS bool AS
$$
BEGIN
    RETURN exists(SELECT p2p.state, verter.state
                  FROM checks
                           JOIN p2p on checks.id = p2p."check"
                           FULL JOIN verter on p2p."check" = verter."check"
                  WHERE checks.id = xp_check
                    AND p2p.state = 'SUCCESS'
                    AND (verter.state IS NULL
                      OR verter.state = 'SUCCESS'));
END
$$ LANGUAGE plpgsql;

-- создаем функцию для тригера
CREATE OR REPLACE FUNCTION fnc_trg_before_insert_xp() RETURNS TRIGGER AS
$$
BEGIN
    IF (fnc_check_xp_amount(NEW."check", NEW.xp_amount) AND fnc_check_succes_task(NEW."check")) THEN
        RETURN NEW;
    END IF;
    RETURN null;
END
$$ LANGUAGE plpgsql;

-- создаем тригер, отрабатывающий перед вставкой в таблицу хр
CREATE OR REPLACE TRIGGER trg_update_transferred_points_after_insert_p2p
    BEFORE INSERT
    ON xp
    FOR EACH ROW
EXECUTE PROCEDURE fnc_trg_before_insert_xp();

-- Тестим TASK4
-- стартуем и успешно завршаем проверку p2p
CALL prc_add_p2p_check('sandorme', 'clemenha', 'D01_Linux', 'START', '15:19:12');
CALL prc_add_p2p_check('sandorme', 'clemenha', 'D01_Linux', 'SUCCESS', '15:21:13');
-- добавляем в хр запись о начисленных хр
INSERT INTO xp ("check", xp_amount)
VALUES (31, 267);

-- стартуем и успешно завршаем проверку p2p удачно
CALL prc_add_p2p_check('sandorme', 'clemenha', 'D02_Linux_Network', 'START', '15:23:41');
CALL prc_add_p2p_check('sandorme', 'clemenha', 'D02_Linux_Network', 'SUCCESS', '15:25:16');
-- добавляем в хр запись с некорректным начислением хр
INSERT INTO xp ("check", xp_amount)
VALUES (32, 1111);
-- и корректную
INSERT INTO xp ("check", xp_amount)
VALUES (32, 250);

-- стартуем и успешно завршаем проверку p2p неудачно
CALL prc_add_p2p_check('sandorme', 'clemenha', 'D03_LinuxMonitoring_v1.0', 'START', '15:23:41');
CALL prc_add_p2p_check('sandorme', 'clemenha', 'D03_LinuxMonitoring_v1.0', 'FAILURE', '15:25:16');
-- добавляем в хр запись корректную запись начисляемых хр, но проверка p2p фейл
INSERT INTO xp ("check", xp_amount)
VALUES (33, 100);

-- стартуем и успешно завршаем проверку p2p удачно, но проверка вертера неудачна
CALL prc_add_p2p_check('sandorme', 'clemenha', 'C4_s21_math', 'START', '15:23:41');
CALL prc_add_p2p_check('sandorme', 'clemenha', 'C4_s21_math', 'SUCCESS', '15:25:16');
CALL prc_add_verter_check('sandorme', 'C4_s21_math', 'START', '15:27:04');
CALL prc_add_verter_check('sandorme', 'C4_s21_math', 'FAILURE', '15:29:11');
-- добавляем в хр запись корректную запись начисляемых хр, но проверка verter фейл
INSERT INTO xp ("check", xp_amount)
VALUES (34, 100);

-- стартуем и успешно завршаем проверку p2p удачно, и вертер тоже удачно
CALL prc_add_p2p_check('sandorme', 'clemenha', 'C5_s21_decimal', 'START', '15:31:14');
CALL prc_add_p2p_check('sandorme', 'clemenha', 'C5_s21_decimal', 'SUCCESS', '15:33:51');
CALL prc_add_verter_check('sandorme', 'C5_s21_decimal', 'START', '15:35:40');
CALL prc_add_verter_check('sandorme', 'C5_s21_decimal', 'SUCCESS', '15:37:01');
-- добавляем в хр запись корректную запись начисляемых хр, и вертер тоже успешен
INSERT INTO xp ("check", xp_amount)
VALUES (35, 100);


-- понадобится для Парт3 Таск8
CALL prc_add_p2p_check('takemiym', 'sandorme', 'C8_3DViewer_v1.0', 'START', '16:01:18');
CALL prc_add_p2p_check('takemiym', 'sandorme', 'C8_3DViewer_v1.0', 'SUCCESS', '16:17:27');
INSERT INTO xp ("check", xp_amount)
VALUES (36, 700);
