-----------------------------------------------------------------------------------------------------------------------

-- ЕСЛИ ХОТИТЕ СОЗДАТЬ НОВУЮ БД,
-- ТО ВЫПОЛНИТЕ НИЖЕ ЗАКОММЕНТИРОВАННЫЙ КОД
-- И ПЕРЕКЛЮЧИТЕ СОЕДИНЕНИЕ НА НОВУЮ БД,
-- ЛИБО ПРОПУСТИТЕ ЭТОТ ПУНКТ,
-- ВЫПОЛНЯЙТЕ НИЖЕУКАЗАННЫЕ СКРИПТЫ В ДEФОЛТНОЙ БАЗЕ POSTGRES (СХЕМА PUBLIC)

-- CREATE DATABASE retail_analytics;    -- <<<<<<<<<< ЭТО ТОТ САМЫЙ КОД

-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ --
-----------------------------------------------------------------------------------------------------------------------


-- region удаляем схему, если существует и создаем новую

DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
-- endregion удаляем схему, если существует и создаем новую

-- region personal_data

CREATE TABLE IF NOT EXISTS personal_data
(
    Customer_ID            serial PRIMARY KEY,
    Customer_Name          varchar NOT NULL,
    Customer_Surname       varchar NOT NULL,
    Customer_Primary_Email varchar NOT NULL,
    Customer_Primary_Phone varchar NOT NULL,

    CONSTRAINT chk_personal_data_Customer_Name check (Customer_Name ~
                                                      '^([A-ZА-Я][a-zа-я-]*){1}(\s+[A-ZА-Яa-zа-я][a-zа-я-]*){0,}$'),
    CONSTRAINT chk_personal_data_Customer_Surname check (Customer_Surname ~
                                                         '^([A-ZА-Я][a-zа-я-]*){1}(\s+[A-ZА-Яa-zа-я][a-zа-я-]*){0,}$'),
    CONSTRAINT chk_personal_data_Customer_Primary_Email check (Customer_Primary_Email ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'),
    CONSTRAINT chk_personal_data_Customer_Primary_Phone check (Customer_Primary_Phone ~ '^[+]7[0-9]{10}$')
);
-- endregion personal_data

-- region cards

CREATE TABLE IF NOT EXISTS cards
(
    Customer_Card_ID serial PRIMARY KEY,
    Customer_ID      int NOT NULL,

    FOREIGN KEY (Customer_ID) REFERENCES personal_data (Customer_ID)
);
-- endregion cards

-- region groups_SKU

CREATE TABLE IF NOT EXISTS groups_SKU
(
    Group_ID   serial PRIMARY KEY,
    Group_Name varchar NOT NULL
);

-- endregion groups_SKU

-- region SKU

CREATE TABLE IF NOT EXISTS SKU
(
    SKU_ID   serial PRIMARY KEY,
    SKU_Name varchar NOT NULL,
    Group_ID int     NOT NULL,

    FOREIGN KEY (Group_ID) REFERENCES groups_SKU (Group_ID)
);
-- endregion SKU

-- region stores

CREATE TABLE IF NOT EXISTS stores
(
    Transaction_Store_ID int,
    SKU_ID               int,
    SKU_Purchase_Price   numeric NOT NULL,
    SKU_Retail_Price     numeric NOT NULL,

    CONSTRAINT chk_retail_outlets_SKU_Purchase_Price check ( SKU_Purchase_Price >= 0 ),
    CONSTRAINT chk_retail_outlets_SKU_SKU_Retail_Price check ( SKU_Retail_Price >= 0 ),
    FOREIGN KEY (SKU_ID) REFERENCES SKU (SKU_ID)
);
-- endregion stores

-- region transactions

CREATE TABLE IF NOT EXISTS transactions
(
    Transaction_ID       serial PRIMARY KEY,
    Customer_Card_ID     int     NOT NULL,
    Transaction_Summ     numeric NOT NULL,
    Transaction_DateTime timestamp NOT NULL,
    Transaction_Store_ID int     NOT NULL,

    CONSTRAINT chk_transactions_Transaction_Summ check ( Transaction_Summ >= 0 ),
    FOREIGN KEY (Customer_Card_ID) REFERENCES cards (Customer_Card_ID)
);

-- endregion transactions

-- region checks

CREATE TABLE IF NOT EXISTS checks
(
    Transaction_ID int     NOT NULL,
    SKU_ID         int     NOT NULL,
    SKU_Amount     numeric     NOT NULL,
    SKU_Summ       numeric NOT NULL,
    SKU_Summ_Paid  numeric NOT NULL,
    SKU_Discount   numeric NOT NULL,

    CONSTRAINT chk_receipts_SKU_Amount check ( SKU_Amount > 0 ),
    CONSTRAINT chk_receipts_SKU_Summ check ( SKU_Amount >= 0 ),
    CONSTRAINT chk_receipts_SKU_Summ_Paid check ( SKU_Summ_Paid >= 0 ),
    CONSTRAINT chk_receipts_SKU_Discount check ( SKU_Discount >= 0 ),

    FOREIGN KEY (Transaction_ID) REFERENCES transactions (Transaction_ID),
    FOREIGN KEY (SKU_ID) REFERENCES SKU (SKU_ID)
);
-- endregion checks

-- region date_of_analysis_formation

CREATE TABLE IF NOT EXISTS date_of_analysis_formation
(
    Analysis_Formation timestamp NOT NULL
);
-- endregion date_of_analysis_formation

-- show datestyle;
-- SET datestyle TO dmy;

-- region импорт/экспорт .csv

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

-- для теста импорта .csv
-- CALL prc_import_csv('tasks', '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/src/datasets/ranks_table.csv', ',');

CREATE OR REPLACE PROCEDURE prc_export_csv(table_name_csv varchar, path_csv varchar, file_name varchar,
                                           delimiter varchar) AS
$$
BEGIN
    EXECUTE 'COPY ' || table_name_csv || ' TO ' || '''' || path_csv || file_name || '.csv' || '''' || ' DELIMITER ' ||
            '''' || delimiter || '''' || ' CSV HEADER;';
END;
$$ LANGUAGE plpgsql;

-- для теста экспорта .csv
-- CALL prc_export_csv('ranks_table', '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/src/datasets/', 'new_data', ',');

-- endregion импорт/экспорт .csv

-- region импорт/экспорт .tsv

CREATE OR REPLACE PROCEDURE prc_import_tsv(
    table_name_tsv varchar,
    path_csv varchar) AS
$$
BEGIN
    EXECUTE 'COPY ' || table_name_tsv || ' FROM ' || '''' || path_csv || '''' || ' DELIMITER E' || '''' || '\t' ||
            '''';
END;
$$ LANGUAGE plpgsql;

-- для теста импорта .tsv
-- CALL prc_import_tsv('cards', '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/Cards.tsv');

CREATE OR REPLACE PROCEDURE prc_export_tsv(table_name_tsv varchar, path_csv varchar, file_name varchar) AS
$$
BEGIN
    EXECUTE 'COPY ' || table_name_tsv || ' TO ' || '''' || path_csv || '/' || file_name || '.tsv' || '''' ||
            ' DELIMITER E' || '''' || '\t' ||
            '''';
END;
$$ LANGUAGE plpgsql;

-- для теста экспорта .tsv
-- CALL prc_export_tsv('personal_data', '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/src', 'new_data');

-- endregion импорт/экспорт .tsv

-- region импорт ПОЛНЫХ версий

-- DO
-- $$
--     BEGIN
--         CALL prc_import_tsv('personal_data',
--                             '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/Personal_Data.tsv');
--         CALL prc_import_tsv('cards', '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/Cards.tsv');
--         CALL prc_import_tsv('groups_sku',
--                             '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/Groups_SKU.tsv');
--         CALL prc_import_tsv('sku', '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/SKU.tsv');
--         CALL prc_import_tsv('stores',
--                             '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/Stores.tsv');
--         CALL prc_import_tsv('transactions',
--                             '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/Transactions.tsv');
--         CALL prc_import_tsv('checks',
--                             '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/Checks.tsv');
--         CALL prc_import_tsv('date_of_analysis_formation',
--                             '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/Date_Of_Analysis_Formation.tsv');
--     END;
-- $$

-- endregion импорт ПОЛНЫХ версий

-- region импорт МИНИ версий

DO
$$
    BEGIN
        CALL prc_import_tsv('personal_data',
                            '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/Personal_Data_Mini.tsv');
        CALL prc_import_tsv('cards', '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/Cards_Mini.tsv');
        CALL prc_import_tsv('groups_sku',
                            '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/Groups_SKU_Mini.tsv');
        CALL prc_import_tsv('sku', '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/SKU_Mini.tsv');
        CALL prc_import_tsv('stores',
                            '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/Stores_Mini.tsv');
        CALL prc_import_tsv('transactions',
                            '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/Transactions_Mini.tsv');
        CALL prc_import_tsv('checks',
                            '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/Checks_Mini.tsv');
        CALL prc_import_tsv('date_of_analysis_formation',
                            '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/datasets/Date_Of_Analysis_Formation.tsv');
    END;
$$

-- endregion импорт МИНИ версий
