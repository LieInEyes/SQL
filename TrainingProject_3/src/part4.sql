CREATE OR REPLACE FUNCTION fnc_personal_offers_focused_growth_average_check(method int,
                                                                        start_period date,
                                                                        stop_period date,
                                                                        count_transactions int,
                                                                        coefficient_average_check_increase numeric,
                                                                        maximum_churn_index numeric,
                                                                        maximum_share_transactions_with_discount numeric,
                                                                        allowable_share_margin numeric)
    RETURNS table
            (
                customer_id            int,
                Required_Check_Measure numeric(15, 2),
                group_name             varchar,
                Offer_Discount_Depth   numeric
            )
AS
$$
BEGIN
    SET margin.type = 0;
    SET margin.value = 2;

    RETURN QUERY
        WITH date_analysis AS
                 (SELECT analysis_formation AS last_date_analysis
                  FROM date_of_analysis_formation
                  ORDER BY last_date_analysis DESC
                  LIMIT 1),
             all_table AS
                 (SELECT row_number() over (PARTITION BY pd.customer_id ORDER BY tr.transaction_id DESC) AS rn,
                         pd.customer_id,
                         tr.transaction_summ,
                         tr.transaction_datetime
                  FROM personal_data AS pd
                           LEFT JOIN cards AS c ON pd.customer_id = c.customer_id
                           LEFT JOIN transactions AS tr ON c.customer_card_id = tr.customer_card_id
                  WHERE tr.transaction_datetime <= (SELECT last_date_analysis FROM date_analysis)),
             all_table_with_method AS
                 (SELECT *
                  FROM all_table
                  WHERE CASE
                            WHEN method = 1
                                THEN transaction_datetime BETWEEN start_period AND stop_period -- method + start_period + stop_period
                            WHEN method = 2 THEN rn <= count_transactions -- method + count_transactions
                            ELSE false END),
             column_1_2 AS
                 (SELECT atwm.customer_id,
                         round((CASE
                                    WHEN avg(atwm.transaction_summ) IS NULL THEN 0
                                    ELSE avg(atwm.transaction_summ) END) * coefficient_average_check_increase,
                               2) AS Required_Check_Measure -- coefficient_average_check_increase
                  FROM all_table_with_method AS atwm
                  GROUP BY atwm.customer_id),
             column_3_4 AS
                 (SELECT row_number() over (PARTITION BY g.customer_id ORDER BY g.group_affinity_index DESC) AS rn,
                         g.customer_id,
                         gs.group_name,
                         round((g.group_minimum_discount * 100 + 2.5) * 0.2, 0) * 5                          as Offer_Discount_Depth
                  FROM groups AS g
                           JOIN purchase_history AS ph ON g.customer_id = ph.customer_id AND g.group_id = ph.group_id
                           JOIN groups_sku AS gs ON g.group_id = gs.group_id
                  WHERE g.group_churn_rate <= maximum_churn_index
                    AND g.group_discount_share * 100 <= maximum_share_transactions_with_discount
                  GROUP BY g.customer_id, gs.group_name, g.group_affinity_index, g.group_minimum_discount
                  HAVING avg((ph.group_summ - ph.group_cost) / ph.group_summ) * allowable_share_margin >=
                         round((g.group_minimum_discount * 100 + 2.5) * 0.2, 0) * 5)

        SELECT c_1_2.customer_id,
               c_1_2.Required_Check_Measure,
               c_3_4.group_name,
               c_3_4.Offer_Discount_Depth
        FROM column_1_2 AS c_1_2
                 JOIN column_3_4 AS c_3_4 ON c_1_2.customer_id = c_3_4.customer_id
        WHERE c_3_4.Offer_Discount_Depth != 0
          AND c_3_4.rn = 1;
END ;
$$ LANGUAGE plpgsql;

SELECT *
FROM fnc_personal_offers_focused_growth_average_check(2,
                                                  '10-10-1010',
                                                  '10-10-2023',
                                                  100,
                                                  1.15,
                                                  3,
                                                  70,
                                                  30);
