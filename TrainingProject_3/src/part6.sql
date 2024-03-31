CREATE OR REPLACE FUNCTION fnc_personalized_offers_focused_on_cross_selling(number_groups int,
                                                                            maximum_churn_index numeric,
                                                                            maximum_consumption_stability_index numeric,
                                                                            maximum_SKU_share numeric,
                                                                            allowable_margin_share numeric)
    RETURNS table
            (
                customer_id          int,
                sku_name             varchar,
                Offer_Discount_Depth numeric
            )
AS
$$
BEGIN
    SET margin.type = 0;
    SET margin.value = 2;

    RETURN QUERY
        WITH select_group AS
                 (SELECT row_number()
                         over (partition by g.customer_id order by g.customer_id, g.group_id, g.group_affinity_index DESC) AS rn,
                         g.customer_id,
                         g.group_id
                  FROM groups AS g
                  WHERE g.group_churn_rate <= maximum_churn_index
                    AND g.group_stability_index < maximum_consumption_stability_index),
             column_1 AS
                 (SELECT sg.customer_id,
                         sg.group_id,
                         sg.rn
                  FROM select_group AS sg
                  WHERE rn < number_groups),
             temp AS
                 (SELECT c_1.customer_id,
                         c_1.group_id,
                         s.sku_id,
                         c.customer_primary_store,
                         s.sku_retail_price,
                         s.sku_purchase_price,
                         s.sku_retail_price - s.sku_purchase_price AS margin
                  FROM column_1 AS c_1
                           JOIN customers AS c ON c_1.customer_id = c.customer_id
                           JOIN stores AS s ON c.customer_primary_store = s.transaction_store_id
                  ORDER BY c_1.customer_id,
                           c_1.group_id,
                           margin DESC),
             count_sku AS
                 (SELECT ph.customer_id,
                         ph.group_id,
                         ch.sku_id,
                         count(ch.sku_id) AS count_sku
                  FROM purchase_history AS ph
                           JOIN checks AS ch ON ph.transaction_id = ch.transaction_id
                  GROUP BY ph.customer_id,
                           ph.group_id,
                           ch.sku_id
                  ORDER BY 1, 2, 3),

             shares_sku AS
                 (SELECT cs.customer_id,
                         cs.group_id,
                         cs.sku_id
                  FROM count_sku AS cs
                           JOIN periods AS p ON cs.customer_id = p.customer_id AND cs.group_id = p.group_id
                  WHERE cs.count_sku::numeric / p.group_purchase::numeric * 100 <= maximum_SKU_share),
             temp_column_1_2 AS
                 (SELECT t.*,
                         sku.sku_name,
                         row_number()
                         over (partition by t.customer_id, t.group_id order by t.customer_id, t.group_id, t.margin DESC) AS rn
                  FROM temp AS t
                           JOIN shares_sku AS ss
                                ON t.customer_id = ss.customer_id AND t.group_id = ss.group_id AND t.sku_id = ss.sku_id
                           JOIN sku ON t.sku_id = sku.sku_id),
             column_1_2 AS
                 (SELECT *
                  FROM temp_column_1_2
                  WHERE rn = 1),
             increased_minimum_discount AS
                 (SELECT c_1_2.customer_id,
                         c_1_2.group_id,
                         c_1_2.sku_name,
                         (allowable_margin_share * (c_1_2.sku_retail_price - c_1_2.sku_purchase_price)) /
                         c_1_2.sku_retail_price                                     AS qwerty,
                         round((g.group_minimum_discount * 100 + 2.5) * 0.2, 0) * 5 AS Offer_Discount_Depth
                  FROM column_1_2 AS c_1_2
                           JOIN groups AS g
                                ON c_1_2.customer_id = g.customer_id AND c_1_2.group_id = g.group_id)
        SELECT imd.customer_id,
               imd.sku_name,
               imd.Offer_Discount_Depth
        FROM increased_minimum_discount AS imd
        WHERE imd.qwerty >= imd.Offer_Discount_Depth;
END ;
$$ LANGUAGE plpgsql;

SELECT *
FROM fnc_personalized_offers_focused_on_cross_selling(5,
                                                      3,
                                                      0.5,
                                                      100,
                                                      30);
