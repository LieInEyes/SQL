-- Посетитель
CREATE ROLE visitor LOGIN;
-- 1ый способ
GRANT USAGE ON SCHEMA public TO visitor;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO visitor;
-- 2ой способ
GRANT pg_read_all_data TO visitor;


-- Администратор
-- 1ый способ
CREATE ROLE administrator LOGIN;
GRANT ALL ON SCHEMA public TO administrator;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO administrator;
-- 2ой способ
-- CREATE ROLE administrator LOGIN SUPERUSER;

-- для проверки
-- SET role visitor;
-- SET role administrator;
-- SET role postgres;
-- SELECT current_user, session_user;
-- create table test (a int);
-- drop table test;
-- select * from public.cards;
-- insert into cards (customer_card_id, customer_id) VALUES (1444, 999);
-- update cards set customer_card_id=1300 where customer_card_id = 1444;
-- delete FROM cards where customer_card_id = 1300;
--
-- CREATE OR REPLACE FUNCTION foo() RETURNS int AS
-- $$BEGIN
--     RETURN (SELECT 2+2 AS result);
-- END
-- $$LANGUAGE plpgsql;
-- SELECT * FROM foo();
-- DROP FUNCTION foo();
--
-- select pg_sleep(5000) from cards;
-- select * from pg_stat_activity;      -- запускать в другой сессии
-- select pg_terminate_backend(24889);  -- запускать в другой сессии
--
-- REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM visitor;
-- REVOKE ALL ON SCHEMA public FROM visitor;
-- DROP ROLE IF EXISTS visitor;
--
-- REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM administrator;
-- REVOKE ALL ON SCHEMA public FROM administrator;
-- DROP ROLE IF EXISTS administrator;


