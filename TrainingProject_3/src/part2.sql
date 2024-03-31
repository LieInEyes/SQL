CREATE TABLE IF NOT EXISTS ranks_table
(
    rank                           int,
    Customer_Average_Check_Segment varchar(24),
    Customer_Frequency_Segment     varchar(24),
    Customer_Churn_Segment         varchar(24)
);

CALL prc_import_csv('ranks_table',
                    '/home/lieineyes/school21/in_work/SQL3_RetailAnalitycs_v1.0-1/src/datasets/ranks_table.csv', ',');

-- region ПОКУПАТЕЛИ

CREATE OR REPLACE VIEW customers AS
WITH date_analysis AS
         (SELECT analysis_formation AS last_date_analysis
          FROM date_of_analysis_formation
          ORDER BY last_date_analysis DESC
          LIMIT 1),
     all_table AS
         (SELECT pd.customer_id,
                 c.customer_card_id,
                 tr.transaction_summ::numeric,
                 tr.transaction_datetime,
                 tr.transaction_store_id
          FROM personal_data AS pd
                   LEFT JOIN cards AS c ON pd.customer_id = c.customer_id
                   LEFT JOIN (SELECT transactions.transaction_id,
                                     transactions.customer_card_id,
                                     transactions.transaction_summ,
                                     transactions.transaction_datetime,
                                     transactions.transaction_store_id
                              FROM transactions) AS tr
                             ON c.customer_card_id = tr.customer_card_id
          WHERE tr.transaction_datetime <= (SELECT last_date_analysis FROM date_analysis)),
     column_1_2 AS
         (SELECT customer_id,
                 (CASE
                      WHEN avg(all_table.transaction_summ) IS NULL THEN 0
                      ELSE avg(all_table.transaction_summ) END) AS Customer_Average_Check
          FROM all_table
          GROUP BY customer_id
          ORDER BY Customer_Average_Check DESC),
     temp_count_customers AS
         (SELECT count(*) AS all_count
          FROM column_1_2),
     column_1_2_3 AS
         (SELECT Customer_id,
                 Customer_Average_Check,
                 (CASE
                      WHEN
                          temp_count_customers.all_count * 0.1 >= row_number() over () THEN 'High'
                      WHEN temp_count_customers.all_count * 0.35 >= row_number() over () AND
                           temp_count_customers.all_count * 0.1 < row_number() over ()
                          THEN 'Medium'
                      ELSE 'Low'
                     END) AS Customer_Average_Check_Segment
          FROM column_1_2,
               temp_count_customers),
     column_4 AS
         (SELECT customer_id,
                 (extract(epoch from (max(transaction_datetime) - min(transaction_datetime))) /
                  86400 /
                  count(transaction_datetime)) AS Customer_Frequency
          FROM all_table
          GROUP BY customer_id
          ORDER BY Customer_Frequency),
     column_4_5 AS
         (SELECT c_4.Customer_id,
                 c_4.Customer_Frequency,
                 (CASE
                      WHEN tcc.all_count * 0.1 >= row_number() over () THEN 'Often'
                      WHEN tcc.all_count * 0.35 >= row_number() over () AND tcc.all_count * 0.1 < row_number() over ()
                          THEN 'Occasionally'
                      ELSE 'Rarely' END) AS Customer_Frequency_Segment
          FROM column_4 AS c_4,
               temp_count_customers AS tcc),
     column_6 AS
         (SELECT at.customer_id AS Customer_id,
                 extract(epoch from
                         ((SELECT da.last_date_analysis FROM date_analysis AS da) - max(at.transaction_datetime)) /
                         86400) AS Customer_Inactive_Period
          FROM all_table AS at
          group by at.customer_id),
     column_6_7_8 AS
         (SELECT c_6.Customer_id,
                 c_6.Customer_Inactive_Period,
                 c_6.Customer_Inactive_Period / c_5.Customer_Frequency AS Customer_Churn_Rate,
                 (CASE
                      WHEN c_6.Customer_Inactive_Period / c_5.Customer_Frequency < 2 THEN 'Low'
                      WHEN c_6.Customer_Inactive_Period / c_5.Customer_Frequency < 5 THEN 'Medium'
                      ELSE 'High'
                     END)                                              AS Customer_Churn_Segment
          FROM column_4_5 AS c_5
                   LEFT JOIN column_6 AS c_6 ON c_5.Customer_id = c_6.Customer_id),
     temp_ranks_table AS
         (SELECT *
          FROM ranks_table),
     column_9 AS
         (SELECT c_1_2_3.Customer_id,
                 trt.rank
          FROM column_1_2_3 AS c_1_2_3
                   LEFT JOIN column_4_5 AS c_5 ON c_1_2_3.Customer_id = c_5.Customer_id
                   LEFT JOIN column_6_7_8 AS c_6_7_8 ON c_1_2_3.Customer_id = c_6_7_8.customer_id
                   LEFT JOIN temp_ranks_table AS trt
                             ON c_1_2_3.Customer_Average_Check_Segment = trt.Customer_Average_Check_Segment
                                 AND c_5.Customer_Frequency_Segment = trt.Customer_Frequency_Segment
                                 AND c_6_7_8.Customer_Churn_Segment = trt.Customer_Churn_Segment),
     count_store AS
         (SELECT at.customer_id,
                 at.transaction_store_id,
                 count(at.transaction_store_id) AS qwerty
          FROM all_table AS at
          GROUP BY at.customer_id,
                   at.transaction_store_id),
     temp_temp AS
         (SELECT cs.customer_id,
                 max(qwerty) AS qazwsx
          FROM count_store AS cs
          GROUP BY cs.customer_id),
     tttt AS
         (SELECT cs.customer_id,
                 cs.transaction_store_id,
                 max(at.transaction_datetime) AS max_datetime
          FROM count_store AS cs
                   LEFT JOIN all_table AS at
                             ON cs.customer_id = at.customer_id AND cs.transaction_store_id = at.transaction_store_id
          GROUP BY cs.customer_id,
                   cs.transaction_store_id),
     temp_temp_temp AS
         (SELECT cs.customer_id,
                 cs.transaction_store_id,
                 tttt.max_datetime,
                 row_number() over (partition by cs.customer_id order by cs.customer_id, tttt.max_datetime DESC ) AS rn
          FROM count_store AS cs
                   LEFT JOIN temp_temp AS tt ON cs.customer_id = tt.customer_id
                   LEFT JOIN tttt ON cs.customer_id = tttt.customer_id AND
                                     cs.transaction_store_id = tttt.transaction_store_id
          WHERE cs.qwerty = tt.qazwsx),
     column_10 AS
         (SELECT *
          FROM temp_temp_temp
          WHERE rn = 1)


SELECT DISTINCT c_1_2_3.Customer_id,
                c_1_2_3.Customer_Average_Check,
                c_1_2_3.Customer_Average_Check_Segment,
                c_4_5.Customer_Frequency,
                c_4_5.Customer_Frequency_Segment,
                c_6_7_8.Customer_Inactive_Period,
                c_6_7_8.Customer_Churn_Rate,
                c_6_7_8.Customer_Churn_Segment,
                c_9.rank                  AS Customer_Segment,
                c_10.transaction_store_id AS Customer_Primary_Store
FROM column_1_2_3 AS c_1_2_3
         LEFT JOIN column_4_5 AS c_4_5 ON c_1_2_3.Customer_id = c_4_5.Customer_id
         LEFT JOIN column_6_7_8 AS c_6_7_8 ON c_1_2_3.Customer_id = c_6_7_8.customer_id
         LEFT JOIN column_9 AS c_9 ON c_1_2_3.Customer_id = c_9.Customer_id
         LEFT JOIN column_10 AS c_10 ON c_1_2_3.Customer_id = c_10.customer_id
ORDER BY c_1_2_3.Customer_id
;

-- endregion ПОКУПАТЕЛИ

-- region ИСТОРИЯ ПОКУПОК

CREATE OR REPLACE VIEW purchase_history AS
WITH date_analysis AS
         (SELECT analysis_formation AS last_date_analysis
          FROM date_of_analysis_formation
          ORDER BY last_date_analysis DESC
          LIMIT 1),
     temp_1_2 AS
         (SELECT DISTINCT pd.customer_id,
                          tr.transaction_id
          FROM personal_data AS pd
                   LEFT JOIN cards AS c ON pd.customer_id = c.customer_id
                   LEFT JOIN transactions AS tr ON c.customer_card_id = tr.customer_card_id
          WHERE tr.transaction_id IS NOT NULL),
     temp_1_2_3 AS
         (SELECT t_1_2.customer_id,
                 t_1_2.transaction_id,
                 tr.transaction_datetime,
                 tr.transaction_store_id
          FROM temp_1_2 AS t_1_2
                   LEFT JOIN transactions AS tr ON t_1_2.transaction_id = tr.transaction_id
          WHERE tr.transaction_datetime <= (SELECT last_date_analysis FROM date_analysis)),
     temp_all_tables AS
         (SELECT t_1_2_3.customer_id,
                 t_1_2_3.transaction_id,
                 t_1_2_3.transaction_datetime,
                 sku.group_id,
                 ch.sku_amount * s.sku_purchase_price AS sku_purchase_price_all_amount,
                 ch.sku_summ,
                 ch.sku_summ_paid
          FROM temp_1_2_3 AS t_1_2_3
                   LEFT JOIN checks AS ch ON t_1_2_3.transaction_id = ch.transaction_id
                   LEFT JOIN sku ON ch.sku_id = sku.sku_id
                   LEFT JOIN stores AS s
                             ON t_1_2_3.transaction_store_id = s.transaction_store_id AND ch.sku_id = s.sku_id)

SELECT DISTINCT t_SKU.customer_id,
                t_SKU.transaction_id,
                t_SKU.transaction_datetime,
                t_SKU.group_id,
                sum(t_SKU.sku_purchase_price_all_amount) AS Group_Cost,
                sum(t_SKU.sku_summ)                      AS Group_Summ,
                sum(t_SKU.sku_summ_paid)                 AS Group_Summ_Paid
FROM temp_all_tables AS t_SKU
GROUP BY t_SKU.customer_id,
         t_SKU.transaction_id,
         t_SKU.transaction_datetime,
         t_SKU.group_id
ORDER BY t_SKU.customer_id,
         t_SKU.transaction_id,
         t_SKU.group_id
;

-- endregion ИСТОРИЯ ПОКУПОК

-- region ПЕРИОДЫ

CREATE OR REPLACE VIEW periods AS
WITH column_1_2_3_4_5 AS
         (SELECT customer_id,
                 group_id,
                 min(transaction_datetime)   AS First_Group_Purchase_Date,
                 max(transaction_datetime)   AS Last_Group_Purchase_Date,
                 count(transaction_datetime) AS Group_Purchase
          FROM purchase_history
          GROUP BY customer_id,
                   group_id),
     column_1_2_3_4_5_6 AS
         (SELECT customer_id,
                 group_id,
                 First_Group_Purchase_Date,
                 Last_Group_Purchase_Date,
                 Group_Purchase,
                 (((extract(epoch from
                            (Last_Group_Purchase_Date - First_Group_Purchase_Date))) /
                   86400) + 1) / Group_Purchase AS Group_Frequency
          FROM column_1_2_3_4_5),
     discount_share AS
         (SELECT pd.customer_id,
                 sku.group_id,
                 ch.sku_discount / ch.sku_summ AS discount_share
          FROM transactions AS tr
                   LEFT JOIN cards AS c ON tr.customer_card_id = c.customer_card_id
                   LEFT JOIN personal_data AS pd ON c.customer_id = pd.customer_id
                   LEFT JOIN checks AS ch ON tr.transaction_id = ch.transaction_id
                   LEFT JOIN sku ON ch.sku_id = sku.sku_id
          WHERE ch.sku_discount != 0
          GROUP BY pd.customer_id,
                   sku.group_id,
                   ch.sku_discount / ch.sku_summ),
     column_7 AS
         (SELECT customer_id,
                 group_id,
                 min(discount_share) AS Group_Min_Discount
          FROM discount_share
          GROUP BY customer_id,
                   group_id)

SELECT c_1_2_3_4_5_6.customer_id,
       c_1_2_3_4_5_6.group_id,
       c_1_2_3_4_5_6.First_Group_Purchase_Date,
       c_1_2_3_4_5_6.Last_Group_Purchase_Date,
       c_1_2_3_4_5_6.Group_Purchase,
       c_1_2_3_4_5_6.Group_Frequency,
       CASE WHEN c_7.Group_Min_Discount IS NULL THEN 0 ELSE c_7.Group_Min_Discount END AS Group_Min_Discount
FROM column_1_2_3_4_5_6 AS c_1_2_3_4_5_6
         LEFT JOIN column_7 AS c_7
                   ON c_1_2_3_4_5_6.customer_id = c_7.customer_id AND c_1_2_3_4_5_6.group_id = c_7.group_id
ORDER BY c_1_2_3_4_5_6.customer_id,
         c_1_2_3_4_5_6.group_id;

-- endregion ПЕРИОДЫ

-- region ГРУППЫ

SET margin.type = 0;
-- дефолт
-- SET margin.type = 1;     -- анализ по дате
-- SET margin.type = 2;     -- анализ по количеству транзакций
SET margin.value = 2;
-- количество дней либо транзакций в зависимости от выбраного типа

CREATE OR REPLACE VIEW "groups" AS
WITH date_analysis AS
         (SELECT analysis_formation AS last_date_analysis
          FROM date_of_analysis_formation
          ORDER BY last_date_analysis DESC
          LIMIT 1),
     all_table AS
         (SELECT pd.customer_id,
                 tr.transaction_id,
                 sku.group_id,
                 tr.transaction_datetime,
                 ch.sku_summ,
                 ch.sku_summ_paid,
                 ch.sku_discount
          FROM personal_data AS pd
                   LEFT JOIN cards AS c ON pd.customer_id = c.customer_id
                   LEFT JOIN (SELECT transaction_id,
                                     customer_card_id,
                                     transaction_datetime
                              FROM transactions) AS tr ON c.customer_card_id = tr.customer_card_id
                   LEFT JOIN checks AS ch ON tr.transaction_id = ch.transaction_id
                   LEFT JOIN sku ON ch.sku_id = sku.sku_id
          WHERE tr.transaction_datetime <= (SELECT last_date_analysis FROM date_analysis)),

     column_1_2 AS
         (SELECT DISTINCT customer_id,
                          group_id
          FROM all_table),

     temp_all_transaction AS
         (SELECT ph1.customer_id,
                 ph1.group_id,
                 count(DISTINCT ph2.transaction_id) AS temp_all_transaction
          FROM purchase_history AS ph1
                   LEFT JOIN periods AS p ON ph1.customer_id = p.customer_id AND ph1.group_id = p.group_id
                   LEFT JOIN purchase_history AS ph2 ON ph1.customer_id = ph2.customer_id AND
                                                        ph2.transaction_datetime >= p.first_group_purchase_date AND
                                                        ph2.transaction_datetime <= p.last_group_purchase_date
          GROUP BY ph1.customer_id,
                   ph1.group_id),
     column_3 AS
         (SELECT tat.customer_id,
                 tat.group_id,
                 p.Group_Purchase::numeric / tat.temp_all_transaction::numeric AS Group_Affinity_Index
          FROM temp_all_transaction AS tat
                   LEFT JOIN periods AS p ON tat.customer_id = p.customer_id AND tat.group_id = p.group_id),

     prescription_of_acquisition AS
         (SELECT customer_id,
                 group_id,
                 (extract(epoch from (SELECT last_date_analysis FROM date_analysis)) -
                  extract(epoch from (max(transaction_datetime)))) / 86400 AS dif
          FROM purchase_history
          GROUP BY customer_id,
                   group_id),
     column_4 AS
         (SELECT poa.customer_id, poa.group_id, poa.dif / p.Group_Frequency AS Group_Churn_Rate
          FROM prescription_of_acquisition AS poa
                   LEFT JOIN periods AS p ON poa.customer_id = p.customer_id AND poa.group_id = p.group_id),

     enumerate AS
         (SELECT row_number() over (ORDER BY customer_id, group_id, transaction_datetime) AS id,
                 customer_id,
                 group_id,
                 transaction_datetime
          FROM purchase_history),
     diff_date AS
         (SELECT en1.customer_id,
                 en1.group_id,
                 CASE
                     WHEN en1.customer_id = en2.customer_id AND en1.group_id = en2.group_id THEN
                         (extract(epoch from (en1.transaction_datetime)) -
                          extract(epoch from (en2.transaction_datetime))) / 86400
                     ELSE 0 END AS interval_transaction
          FROM enumerate AS en1
                   LEFT JOIN enumerate AS en2 ON en1.id = en2.id + 1),
     add_parioods AS
         (SELECT dd.customer_id,
                 dd.group_id,
                 dd.interval_transaction,
                 p.Group_Frequency
          FROM diff_date AS dd
                   LEFT JOIN periods AS p ON dd.customer_id = p.customer_id AND dd.group_id = p.group_id),
     group_stability AS
         (SELECT customer_id,
                 group_id,
                 interval_transaction,
                 CASE
                     WHEN interval_transaction = 0 THEN null
                     ELSE abs((interval_transaction - Group_Frequency) / Group_Frequency) END AS relative_deviation
          FROM add_parioods),
     column_5 AS
         (SELECT customer_id,
                 group_id,
                 CASE
                     WHEN avg(relative_deviation) IS NULL THEN 1
                     ELSE avg(relative_deviation) END AS Group_Stability_Index
          FROM group_stability
          GROUP BY customer_id,
                   group_id),

     default_margin AS
         (SELECT row_number()
                 over (partition by customer_id, group_id order by customer_id, group_id, transaction_datetime DESC) AS row_count_transaction,
                 (extract(epoch from (SELECT last_date_analysis FROM date_analysis)) -
                  extract(epoch from (transaction_datetime))) /
                 86400                                                                                               AS row_date,
                 customer_id,
                 group_id,
                 transaction_datetime,
                 Group_Summ_Paid - Group_Cost                                                                        AS Group_Margin
          FROM purchase_history
          WHERE transaction_datetime <= (SELECT last_date_analysis FROM date_analysis)),
     column_6 AS
         (SELECT customer_id,
                 group_id,
                 sum(Group_Margin) AS Group_Margin
          FROM default_margin
          WHERE CASE
                    WHEN cast(current_setting('margin.type') as int) = 1
                        THEN row_date <= cast(current_setting('margin.value') as int)
                    WHEN cast(current_setting('margin.type') as int) = 2
                        THEN row_count_transaction <= cast(current_setting('margin.value') as int)
                    ELSE true
                    END
          GROUP BY customer_id,
                   group_id),

     all_transactions_with_discount AS
         (SELECT customer_id,
                 group_id,
                 transaction_id
          FROM all_table
          WHERE sku_discount > 0
          GROUP BY customer_id,
                   group_id,
                   transaction_id),
     column_7 AS
         (SELECT atwd.customer_id,
                 atwd.group_id,
                 count(atwd.transaction_id)::numeric / p.Group_Purchase::numeric AS Group_Discount_Share
          FROM all_transactions_with_discount AS atwd
                   LEFT JOIN periods AS p ON atwd.customer_id = p.customer_id AND atwd.group_id = p.group_id
          GROUP BY atwd.customer_id,
                   atwd.group_id,
                   p.Group_Purchase),
     column_7_8 AS
         (SELECT p.customer_id,
                 p.group_id,
                 CASE
                     WHEN c_7.Group_Discount_Share IS NULL THEN 0
                     ELSE c_7.Group_Discount_Share END AS Group_Discount_Share,
                 p.Group_Min_Discount                  AS Group_Minimum_Discount
          FROM periods AS p
                   LEFT JOIN column_7 AS c_7 ON p.customer_id = c_7.customer_id AND p.group_id = c_7.group_id),
     column_9 AS
         (SELECT c_7_8.customer_id,
                 c_7_8.group_id,
                 sum(ph.Group_Summ_Paid) / sum(ph.Group_Summ) AS Group_Average_Discount
          FROM column_7_8 AS c_7_8
                   LEFT JOIN purchase_history AS ph
                             ON c_7_8.customer_id = ph.customer_id AND c_7_8.group_id = ph.group_id
          WHERE ph.Group_Summ_Paid != ph.Group_Summ
          GROUP BY c_7_8.customer_id,
                   c_7_8.group_id)

SELECT c_1_2.customer_id,
       c_1_2.group_id,
       c_3.Group_Affinity_Index,
       c_4.Group_Churn_Rate,
       c_5.Group_Stability_Index,
       c_6.Group_Margin,
       c_7_8.Group_Discount_Share,
       c_7_8.Group_Minimum_Discount,
       CASE
           WHEN c_9.Group_Average_Discount IS NULL THEN 0
           ELSE c_9.Group_Average_Discount END AS Group_Average_Discount

FROM column_1_2 AS c_1_2
         LEFT JOIN column_3 AS c_3 ON c_1_2.customer_id = c_3.customer_id AND c_1_2.group_id = c_3.group_id
         LEFT JOIN column_4 AS c_4 ON c_1_2.customer_id = c_4.customer_id AND c_1_2.group_id = c_4.group_id
         LEFT JOIN column_5 AS c_5 ON c_1_2.customer_id = c_5.customer_id AND c_1_2.group_id = c_5.group_id
         LEFT JOIN column_6 AS c_6 ON c_1_2.customer_id = c_6.customer_id AND c_1_2.group_id = c_6.group_id
         LEFT JOIN column_7_8 AS c_7_8 ON c_1_2.customer_id = c_7_8.customer_id AND c_1_2.group_id = c_7_8.group_id
         LEFT JOIN column_9 AS c_9 ON c_1_2.customer_id = c_9.customer_id AND c_1_2.group_id = c_9.group_id
;

-- endregion ГРУППЫ
