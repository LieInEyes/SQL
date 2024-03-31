---- TASK 1 ---- TASK 1 ---- TASK 1 ---- TASK 1 ---- TASK 1 ---- TASK 1 ---- TASK 1 ---- TASK 1 ---- TASK 1 ----

CREATE OR REPLACE FUNCTION fnc_get_readable_view_transferred_points(OUT peer_1 varchar(128), OUT peer_2 varchar(128),
                                                                    OUT points_amount int) RETURNS SETOF record AS
$$
BEGIN
    RETURN QUERY
        WITH t1 AS
                 (SELECT transferred_points.checking_peer,
                         transferred_points.checked_peer,
                         transferred_points.points_amount
                  FROM transferred_points
                  WHERE checking_peer < checked_peer
                  UNION ALL
                  SELECT transferred_points.checked_peer,
                         transferred_points.checking_peer,
                         transferred_points.points_amount * -1
                  FROM transferred_points
                  WHERE checked_peer < checking_peer)
        SELECT checking_peer, checked_peer, sum(t1.points_amount)::integer
        FROM t1
        GROUP BY checking_peer, checked_peer;
END;
$$ LANGUAGE plpgsql;

SELECT *
FROM fnc_get_readable_view_transferred_points();


---- TASK 2 ---- TASK 2 ---- TASK 2 ---- TASK 2 ---- TASK 2 ---- TASK 2 ---- TASK 2 ---- TASK 2 ---- TASK 2 ----

-- вспомогательная функция возвращающая подстроку номера задания
CREATE OR REPLACE FUNCTION fnc_get_the_task_number(t_task varchar(128)) RETURNS varchar(6) AS
$$
DECLARE
    pos int := (SELECT position('_' in title)
                FROM tasks
                WHERE title = t_task);
BEGIN
    RETURN substring(t_task FROM 1 for pos - 1);
END;
$$ LANGUAGE plpgsql;

-- основная функция
CREATE OR REPLACE FUNCTION fnc_get_peers_success_task_and_amount_xp()
    RETURNS TABLE
            (
                peer varchar(128),
                task varchar(4),
                xp   int
            )
AS
$$
BEGIN
    RETURN QUERY
        SELECT checks.peer, fnc_get_the_task_number(checks.task), xp.xp_amount
        FROM checks
                 JOIN xp ON checks.id = xp."check";
END;
$$ LANGUAGE plpgsql;

SELECT *
FROM fnc_get_peers_success_task_and_amount_xp();


---- TASK 3 ---- TASK 3 ---- TASK 3 ---- TASK 3 ---- TASK 3 ---- TASK 3 ---- TASK 3 ---- TASK 3 ---- TASK 3 ----

CREATE OR REPLACE FUNCTION fnc_get_peers_who_dont_out_campus(set_day date)
    RETURNS TABLE
            (
                peers varchar(128)
            )
AS
$$
BEGIN
    RETURN QUERY
        SELECT peer
        FROM time_tracking
        WHERE date = set_day
        GROUP BY peer
        HAVING count(*) = 2;
END;
$$ LANGUAGE plpgsql;

SELECT *
FROM fnc_get_peers_who_dont_out_campus('2023-08-07');


---- TASK 4 ---- TASK 4 ---- TASK 4 ---- TASK 4 ---- TASK 4 ---- TASK 4 ---- TASK 4 ---- TASK 4 ---- TASK 4 ----

CREATE OR REPLACE PROCEDURE prc_amount_peer_points_for_each_peer(temp refcursor)
AS
$$
BEGIN
    OPEN temp FOR
        WITH TEMP AS
                 (SELECT checking_peer, sum(points_amount) AS points_amount
                  FROM transferred_points
                  GROUP BY checking_peer
                  UNION ALL
                  SELECT checked_peer, sum(points_amount) * -1
                  FROM transferred_points
                  GROUP BY checked_peer)
        SELECT checking_peer AS peer, sum(points_amount)::int AS points_change
        FROM TEMP
        GROUP BY checking_peer
        ORDER BY sum(points_amount) DESC;
END;
$$ LANGUAGE plpgsql;

-- запускать все 4 строки разом
BEGIN;
CALL prc_amount_peer_points_for_each_peer('1');
FETCH ALL IN "1";
END;


---- TASK 5 ---- TASK 5 ---- TASK 5 ---- TASK 5 ---- TASK 5 ---- TASK 5 ---- TASK 5 ---- TASK 5 ---- TASK 5 ----

CREATE OR REPLACE PROCEDURE prc_amount_peer_points_for_each_peer_2(temp refcursor)
AS
$$
BEGIN
    OPEN temp FOR
        WITH union_peer1_peer2 AS
                 (SELECT peer_1, points_amount
                  FROM fnc_get_readable_view_transferred_points()
                  UNION ALL
                  SELECT peer_2, points_amount * -1
                  FROM fnc_get_readable_view_transferred_points())
        SELECT peer_1 AS peer, sum(points_amount)::int AS points_change
        FROM union_peer1_peer2
        GROUP BY peer
        ORDER BY points_change DESC;
END;
$$ LANGUAGE plpgsql;

-- запускать все 4 строки разом
BEGIN;
CALL prc_amount_peer_points_for_each_peer_2('1');
FETCH ALL IN "1";
END;


---- TASK 6 ---- TASK 6 ---- TASK 6 ---- TASK 6 ---- TASK 6 ---- TASK 6 ---- TASK 6 ---- TASK 6 ---- TASK 6 ----

CREATE OR REPLACE PROCEDURE prc_most_frequently_checked_task_for_each_day(temp refcursor)
AS
$$
BEGIN
    OPEN temp FOR
        WITH temp_count AS
                 (SELECT checks.date, fnc_get_the_task_number(checks.task) AS task, count(checks.task) AS count_task
                  FROM p2p
                           JOIN checks ON p2p."check" = checks.id AND p2p.state = 'START'
                  GROUP BY checks.date, checks.task),
             temp_max AS
                 (SELECT temp_count.date, max(temp_count.count_task) AS max_task
                  FROM temp_count
                  GROUP BY temp_count.date)
        SELECT temp_count.date AS day, temp_count.task AS task
        FROM temp_count
                 JOIN temp_max ON temp_count.date = temp_max.date
        WHERE temp_count.count_task = temp_max.max_task;
END;
$$ LANGUAGE plpgsql;

-- запускать все 4 строки разом
BEGIN;
CALL prc_most_frequently_checked_task_for_each_day('1');
FETCH ALL IN "1";
END;


---- TASK 7 ---- TASK 7 ---- TASK 7 ---- TASK 7 ---- TASK 7 ---- TASK 7 ---- TASK 7 ---- TASK 7 ---- TASK 7 ----

CREATE OR REPLACE PROCEDURE prc_all_peers_have_completed_all_tasks_block(name_block varchar(6), temp refcursor)
AS
$$
DECLARE
    task_name varchar(128);
BEGIN
    IF name_block = 'C' THEN
        task_name = 'C8_3DViewer_v1.0';
    ELSEIF name_block = 'D' THEN
        task_name = 'D06_CICD';
    ELSEIF name_block = 'CPP' THEN
        task_name = 'CPP9_MonitoringSystem';
    ELSEIF name_block = 'A' THEN
        task_name = 'A8_Algorithmic_trading';
    ELSEIF name_block = 'SQL' THEN
        task_name = 'SQL3_RetailAnalitycs_v1.0';
    END IF;

    OPEN temp FOR
        SELECT checks.peer, checks.date
        FROM checks
                 JOIN p2p on checks.id = p2p."check"
                 FULL JOIN verter on p2p."check" = verter."check"
        WHERE checks.task = task_name
          AND p2p.state = 'SUCCESS'
          AND (verter.state IS NULL
            OR verter.state = 'SUCCESS')
        ORDER BY checks.date DESC;

END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL prc_all_peers_have_completed_all_tasks_block('C', '1');
FETCH ALL IN "1";
END;


---- TASK 8 ---- TASK 8 ---- TASK 8 ---- TASK 8 ---- TASK 8 ---- TASK 8 ---- TASK 8 ---- TASK 8 ---- TASK 8 ----

-- вспомогательная функция собирающая пиров их друзей и рекомендации друзей в одну таблицу
CREATE OR REPLACE FUNCTION fnc_get_table_peer_friend_recommend()
    RETURNS TABLE
            (
                peer             varchar(128),
                friend           varchar(128),
                recommended_peer varchar(128)
            )
AS
$$
BEGIN
    RETURN QUERY
        SELECT nickname AS peer, f1.peer_2 AS friend, rec.recommended_peer
        FROM peers
                 FULL JOIN friends f1 ON peers.nickname = f1.peer_1
                 FULL JOIN recommendations rec ON f1.peer_2 = rec.peer AND peers.nickname != rec.recommended_peer
        WHERE peers.nickname IS NOT NULL
          AND f1.peer_2 IS NOT NULL
          AND rec.recommended_peer IS NOT NULL
        UNION ALL
        SELECT nickname AS peer, f2.peer_1, rec.recommended_peer
        FROM peers
                 FULL JOIN friends f2 ON peers.nickname = f2.peer_2
                 FULL JOIN recommendations rec ON f2.peer_1 = rec.peer AND peers.nickname != rec.recommended_peer
        WHERE peers.nickname IS NOT NULL
          AND f2.peer_1 IS NOT NULL
          AND rec.recommended_peer IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- основная функция
CREATE OR REPLACE PROCEDURE prc_recommend_for_all_peer(temp refcursor)
AS
$$
BEGIN
    OPEN temp FOR
        WITH count_peer_friend_rec AS
                 (SELECT all_pfr.peer, all_pfr.recommended_peer, count(all_pfr.recommended_peer) AS count_pfr
                  FROM fnc_get_table_peer_friend_recommend() AS all_pfr
                  GROUP BY all_pfr.peer, all_pfr.recommended_peer),
             max_peer_friend_rec AS
                 (SELECT count_peer_friend_rec.peer, max(count_peer_friend_rec.count_pfr) AS max_pfr
                  FROM count_peer_friend_rec
                  GROUP BY count_peer_friend_rec.peer)
        SELECT count_peer_friend_rec.peer, count_peer_friend_rec.recommended_peer
        FROM count_peer_friend_rec
                 JOIN max_peer_friend_rec ON count_peer_friend_rec.peer = max_peer_friend_rec.peer
        WHERE count_peer_friend_rec.count_pfr = max_peer_friend_rec.max_pfr;

END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL prc_recommend_for_all_peer('1');
FETCH ALL IN "1";
END;


---- TASK 9  ---- TASK 9  ---- TASK 9  ---- TASK 9  ---- TASK 9  ---- TASK 9  ---- TASK 9  ---- TASK 9  ---- TASK 9

-- вспомогательная функция возвращающая полное название стартового задания блока
CREATE OR REPLACE FUNCTION fnc_get_task(name_block varchar(6))
    RETURNS varchar(128) AS
$$
BEGIN
    IF name_block = 'C' THEN
        RETURN 'C2_SimpleBashUtils';
    ELSEIF name_block = 'D' THEN
        RETURN 'D01_Linux';
    ELSEIF name_block = 'CPP' THEN
        RETURN 'CPP1_s21_matrix+';
    ELSEIF name_block = 'A' THEN
        RETURN 'A8_Algorithmic_trading';
    ELSEIF name_block = 'SQL' THEN
        RETURN 'A1_Maze';
    END IF;
END
$$ LANGUAGE plpgsql;

-- вспомогательная функция проверяющая успешность выполненного задания для пира
CREATE OR REPLACE FUNCTION fnc_checked_start_task(name_peer varchar(6), name_task varchar(6)) RETURNS bool
AS
$$
BEGIN
    RETURN exists(SELECT *
                  FROM checks
                           JOIN p2p ON checks.id = p2p."check"
                  WHERE checks.task = name_task
                    AND checks.peer = name_peer
                    AND p2p.state = 'START');
END;
$$ LANGUAGE plpgsql;

-- соновная функция
CREATE OR REPLACE PROCEDURE prc_percentage_peers_started_blocks(name_block_1 varchar(6), name_block_2 varchar(6), temp refcursor)
AS
$$
DECLARE
    name_task_block_1 varchar(128) = (SELECT *
                                      FROM fnc_get_task(name_block_1));
    name_task_block_2 varchar(128) = (SELECT *
                                      FROM fnc_get_task(name_block_2));
    count_peers       int          = (SELECT count(nickname)
                                      FROM peers);
BEGIN
    OPEN temp FOR
        WITH temp AS
                 (SELECT nickname,
                         fnc_checked_start_task(nickname, name_task_block_1)::int       AS start_1,
                         fnc_checked_start_task(nickname, name_task_block_2)::int       AS start_2,
                         (fnc_checked_start_task(nickname, name_task_block_1) AND
                          fnc_checked_start_task(nickname, name_task_block_2))::int     AS start_1_2,
                         (NOT fnc_checked_start_task(nickname, name_task_block_1) AND
                          NOT fnc_checked_start_task(nickname, name_task_block_2))::int AS not_start
                  FROM peers)
        SELECT (sum(temp.start_1) / (count_peers / 100.0))::int   AS started_block_1,
               (sum(temp.start_2) / (count_peers / 100.0))::int   AS started_block_1,
               (sum(temp.start_1_2) / (count_peers / 100.0))::int AS started_both_blocks,
               (sum(temp.not_start) / (count_peers / 100.0))::int AS didnt_start_any_block
        FROM temp;
END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL prc_percentage_peers_started_blocks('C', 'CPP', '1');
FETCH ALL IN "1";
END;


---- TASK 10  ---- TASK 10  ---- TASK 10  ---- TASK 10  ---- TASK 10  ---- TASK 10  ---- TASK 10  ---- TASK 10

CREATE OR REPLACE PROCEDURE prc_percentage_peers_success_fail_task_on_birthday(temp refcursor)
AS
$$
DECLARE
    count_peers int = (SELECT count(nickname)
                       FROM peers);
BEGIN
    OPEN temp FOR
        WITH temp_success AS (SELECT (count(nickname) / (count_peers / 100.0))::int AS count_nickname
                              FROM peers
                                       JOIN checks
                                            ON TO_CHAR(peers.birthday, 'MM-DD') = TO_CHAR(checks.date, 'MM-DD') AND
                                               peers.nickname = checks.peer
                                       JOIN p2p ON checks.id = p2p."check"
                                       FULL JOIN verter ON checks.id = verter."check"
                              WHERE p2p.state = 'SUCCESS'
                                AND (verter.state IS NULL OR verter.state = 'SUCCESS')),
             temp_fail AS (SELECT (count(nickname) / (count_peers / 100.0))::int AS count_nickname
                           FROM peers
                                    JOIN checks ON TO_CHAR(peers.birthday, 'MM-DD') = TO_CHAR(checks.date, 'MM-DD') AND
                                                   peers.nickname = checks.peer
                                    JOIN p2p ON checks.id = p2p."check"
                                    FULL JOIN verter ON checks.id = verter."check"
                           WHERE p2p.state = 'FAILURE'
                              OR (p2p.state = 'SUCCESS' AND (verter.state IS NULL OR verter.state = 'FAILURE')))
        SELECT temp_success.count_nickname AS successful_checks,
               temp_fail.count_nickname    AS unsuccessful_checks
        FROM temp_success
                 CROSS JOIN temp_fail;
END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL prc_percentage_peers_success_fail_task_on_birthday('1');
FETCH ALL IN "1";
END;


---- TASK 11  ---- TASK 11  ---- TASK 11  ---- TASK 11  ---- TASK 11  ---- TASK 11  ---- TASK 11  ---- TASK 11
-- вспомогательная функция, проверяющая успешность выполнения задания в целом
CREATE OR REPLACE FUNCTION fnc_checked_success_task(cheecks_peer varchar(128), checks_task varchar(128)) RETURNS bool AS
$$
BEGIN
    RETURN exists(SELECT *
                  FROM checks
                           JOIN p2p on checks.id = p2p."check"
                           FULL JOIN verter on p2p."check" = verter."check"
                  WHERE checks.peer = cheecks_peer
                    AND checks.task = checks_task
                    AND p2p.state = 'SUCCESS'
                    AND (verter.state IS NULL
                      OR verter.state = 'SUCCESS'));
END
$$ LANGUAGE plpgsql;

-- основная функция
CREATE OR REPLACE PROCEDURE prc_success_two_task_and_fail_third_task(first varchar(128), second varchar(128),
                                                                     third varchar(128), temp refcursor)
AS
$$
BEGIN
    OPEN temp FOR
        SELECT nickname
        FROM peers
        WHERE fnc_checked_success_task(nickname, first)
          AND fnc_checked_success_task(nickname, second)
          AND NOT fnc_checked_success_task(nickname, third);
END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL prc_success_two_task_and_fail_third_task('C2_SimpleBashUtils', 'C3_s21_string+', 'C7_SmartCalc_v1.0', '1');
FETCH ALL IN "1";
END;

---- TASK 12  ---- TASK 12  ---- TASK 12  ---- TASK 12  ---- TASK 12  ---- TASK 12  ---- TASK 12  ---- TASK 12

CREATE OR REPLACE PROCEDURE prc_count_previus_task(name_task varchar(128), temp refcursor)
AS
$$
BEGIN
    OPEN temp FOR
        WITH RECURSIVE count_prev_task AS
                           (SELECT t1.parent_task
                            FROM tasks AS t1
                            WHERE t1.title = name_task
                            UNION
                            SELECT t2.parent_task
                            FROM tasks AS t2
                                     JOIN count_prev_task ON count_prev_task.parent_task = t2.title)
        SELECT fnc_get_the_task_number(name_task) AS task, (count(*) - 1)::int AS prev_count
        FROM count_prev_task;
END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL prc_count_previus_task('A1_Maze', '1');
FETCH ALL IN "1";
END;


---- TASK 13  ---- TASK 13  ---- TASK 13  ---- TASK 13  ---- TASK 13  ---- TASK 13  ---- TASK 13  ---- TASK 13

-- вспомогательная функция по checks.id проверяет успешно выполненую проверку и полученное хп больше 80%
CREATE OR REPLACE FUNCTION fnc_get_bool_check_task_with_xp_amount(check_id int) RETURNS bool AS
$$
BEGIN
    RETURN exists(SELECT *
                  FROM checks
                           JOIN p2p on checks.id = p2p."check"
                           LEFT JOIN verter on p2p."check" = verter."check"
                           JOIN tasks ON checks.task = tasks.title
                           LEFT JOIN xp ON checks.id = xp."check"
                  WHERE checks.id = check_id
                    AND p2p.state = 'SUCCESS'
                    AND (verter.state IS NULL
                      OR verter.state = 'SUCCESS')
                    AND (xp.xp_amount::numeric / tasks.max_xp::numeric * 100.0) >= 80);

end;
$$ LANGUAGE plpgsql;

-- основная функция
CREATE OR REPLACE PROCEDURE prc_good_day_for_check(N int, temp refcursor)
AS
$$
BEGIN
    drop sequence if exists for_good_day;
    CREATE SEQUENCE for_good_day AS int START 1;
    OPEN temp FOR
        WITH temp_1 AS
                 (SELECT checks.id,
                         checks.date,
                         p2p.time,
                         fnc_get_bool_check_task_with_xp_amount(checks.id) AS check_bool
                  FROM checks
                           JOIN p2p ON checks.id = p2p."check"
                           LEFT JOIN verter ON checks.id = verter."check"
                  WHERE NOT p2p.state = 'START'
                    AND (NOT verter.state = 'START' OR verter.state IS NULL)
                  ORDER BY 2, 3, 1),
             temp_2 AS
                 (SELECT temp_1.date,
                         temp_1.check_bool,
                         CASE
                             WHEN (ROW_NUMBER() OVER (ORDER BY temp_1.date, temp_1.time, temp_1.id)) = 1
                                 THEN nextval('for_good_day')
                             WHEN lag(temp_1.date) OVER (ORDER BY temp_1.date, temp_1.time, temp_1.id) = temp_1.date AND
                                  lag(temp_1.check_bool) OVER (ORDER BY temp_1.date, temp_1.time, temp_1.id) =
                                  temp_1.check_bool THEN currval('for_good_day')
                             ELSE nextval('for_good_day')
                             END AS new_group
                  FROM temp_1
                  order by 1, 2)

        SELECT DISTINCT temp_2.date AS day
        FROM temp_2
        WHERE temp_2.check_bool = true
        GROUP BY temp_2.date, temp_2.new_group
        HAVING count(*) >= N
        order by 1;
END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL prc_good_day_for_check(2, '1');
FETCH ALL IN "1";
END;


---- TASK 14  ---- TASK 14  ---- TASK 14  ---- TASK 14  ---- TASK 14  ---- TASK 14  ---- TASK 14  ---- TASK 14

CREATE OR REPLACE PROCEDURE prc_peer_with_the_most_xp(temp refcursor)
AS
$$
BEGIN
    OPEN temp FOR
        SELECT checks.peer, sum(xp.xp_amount)::int AS xp
        FROM xp
                 JOIN checks ON xp."check" = checks.id
        GROUP BY checks.peer
        ORDER BY xp DESC
        LIMIT 1;
END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL prc_peer_with_the_most_xp('1');
FETCH ALL IN "1";
END;


---- TASK 15  ---- TASK 15  ---- TASK 15  ---- TASK 15  ---- TASK 15  ---- TASK 15  ---- TASK 15  ---- TASK 15

CREATE OR REPLACE PROCEDURE prc_peers_who_came_earlier_entrance_no_less_than_count(t_time time, count int, temp refcursor) AS
$$
BEGIN
    OPEN temp FOR
        WITH temp AS (SELECT peer
                      FROM time_tracking
                      WHERE time_tracking.time < t_time
                        AND time_tracking.state = 1
                      GROUP BY date, peer)
        SELECT peer AS nickname
        FROM temp
        GROUP BY peer
        HAVING count(peer) >= count;
END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL prc_peers_who_came_earlier_entrance_no_less_than_count('12:00:00', 1, '1');
FETCH ALL IN "1";
END;


---- TASK 16  ---- TASK 16  ---- TASK 16  ---- TASK 16  ---- TASK 16  ---- TASK 16  ---- TASK 16  ---- TASK 16

CREATE OR REPLACE PROCEDURE prc_peers_who_came_period_date_exit_more_than_count(count_day int, count int, temp refcursor) AS
$$
BEGIN
    OPEN temp FOR
        SELECT DISTINCT peer AS nickname
        FROM time_tracking
        WHERE (time_tracking.date BETWEEN current_date - count_day AND current_date)
          AND time_tracking.state = 2
        GROUP BY peer, date
        HAVING count(date) - 1 > count;
END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL prc_peers_who_came_period_date_exit_more_than_count(50, 1, '1');
FETCH ALL IN "1";
END;


---- TASK 17  ---- TASK 17  ---- TASK 17  ---- TASK 17  ---- TASK 17  ---- TASK 17  ---- TASK 17  ---- TASK 17
-- вспомогательная общее входы
CREATE OR REPLACE FUNCTION fnc_total_number_inputs(month int)
    RETURNS TABLE
            (
                peer varchar(128)
            )
AS
$$
BEGIN
    RETURN QUERY
        SELECT time_tracking.peer
        FROM time_tracking
                 JOIN peers ON time_tracking.peer = peers.nickname
        WHERE state = 1
          AND TO_CHAR(peers.birthday, 'MM')::int = month
          AND TO_CHAR(time_tracking.date, 'MM')::int = month
        GROUP BY time_tracking.peer, time_tracking.date;
END
$$ LANGUAGE plpgsql;

-- вспомогательная ранние входы
CREATE OR REPLACE FUNCTION fnc_total_number_inputs_early_time(month int)
    RETURNS TABLE
            (
                peer varchar(128)
            )
AS
$$
BEGIN
    RETURN QUERY
        SELECT time_tracking.peer
        FROM time_tracking
                 JOIN peers ON time_tracking.peer = peers.nickname
        WHERE state = 1
          AND TO_CHAR(peers.birthday, 'MM')::int = month
          AND TO_CHAR(time_tracking.date, 'MM')::int = month
          AND time_tracking.time < '12:00:00'
        GROUP BY time_tracking.peer, time_tracking.date;
END;
$$ LANGUAGE plpgsql;

-- основная функция
CREATE OR REPLACE PROCEDURE prc_percentage_early_input_relative_total_number_of_admissions(temp refcursor)
AS
$$
BEGIN
    FOR i IN 1..12
        LOOP
            IF ((SELECT count(*) FROM fnc_total_number_inputs(i)) = 0) THEN
                continue;
            END IF;
            OPEN temp FOR
                SELECT to_char(to_date(i::text, 'MM'), 'Month')                                  AS month,
                       ((SELECT count(*) FROM fnc_total_number_inputs_early_time(i))::numeric /
                        (SELECT count(*) FROM fnc_total_number_inputs(i))::numeric * 100.0)::int AS early_entries;

        END LOOP;
END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL prc_percentage_early_input_relative_total_number_of_admissions('1');
FETCH ALL IN "1";
END;
