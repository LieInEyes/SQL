CREATE OR REPLACE FUNCTION fnc_personal_offers_aimed_increasing_frequency_visits(start_period timestamp,
                                                                             stop_period timestamp,
                                                                             added_number_transactions int,
                                                                             maximum_churn_index numeric,
                                                                             maximum_share_transactions_with_discount numeric,
                                                                             allowable_share_margin numeric)
    RETURNS table
            (
                customer_id                 int,
                Start_Date                  timestamp,
                End_Date                    timestamp,
                Required_Transactions_Count int,
                group_name                  varchar,
                Offer_Discount_Depth        numeric
            )
AS
$$
DECLARE
    date_difference int := (extract(epoch from (stop_period)) - extract(epoch from (start_period))) / 86400;
BEGIN
    RETURN QUERY
        WITH column_1_2_3_4 AS
                 (SELECT c.customer_id,
                         start_period              AS Start_Date,
                         stop_period               AS End_Date,
                         round(date_difference / c.customer_frequency)::int +
                         added_number_transactions AS Required_Transactions_Count
                  FROM customers AS c),
             column_5_6 AS
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

        SELECT c_1_2_3_4.customer_id,
               c_1_2_3_4.Start_Date,
               c_1_2_3_4.End_Date,
               c_1_2_3_4.Required_Transactions_Count,
               c_5_6.group_name,
               c_5_6.Offer_Discount_Depth
        FROM column_1_2_3_4 AS c_1_2_3_4
                 JOIN column_5_6 AS c_5_6 ON c_1_2_3_4.customer_id = c_5_6.customer_id;
END ;
$$ LANGUAGE plpgsql;

SELECT *
FROM fnc_personal_offers_aimed_increasing_frequency_visits('2022-08-18',
                                                       '2022-08-18',
                                                       1,
                                                       3,
                                                       70,
                                                       30);
