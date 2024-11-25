select
    sales_projects.id
    , SECOND_INFO.dev_assign_member_id
    , SECOND_INFO.JISSEKI_STATUS
    , SECOND_INFO.SUM_estimated_manhour
    , SECOND_INFO.SUM_actual_manhour
    , SECOND_INFO.RATE
    , SECOND_INFO.SENYURATE
    , HOSEI.HOSEI AS HOSEI
    , SECOND_INFO.SENYURATE * HOSEI.HOSEI AS URIAGE_SENYU_RATE
    , project_contracts.order_amount * (SECOND_INFO.SENYURATE * HOSEI.HOSEI) AS URIAGE 
FROM
    ( 
        SELECT
            SEIKYURATE.develop_id
            , SEIKYURATE.dev_assign_member_id
            , SEIKYURATE.SUM_estimated_manhour
            , SEIKYURATE.SUM_actual_manhour
            , SEIKYURATE.RATE
            , ( 
                SEIKYURATE.SUM_estimated_manhour / SUM_estimated_manhour.SUM_estimated_manhour
            ) * IFNULL(RATE, 0) AS SENYURATE
            , SEIKYURATE.JISSEKI_STATUS 
        FROM
            ( 
                SELECT
                    develop_id
                    , dev_assign_member_id
                    , CASE 
                        WHEN SUM(IFNULL(estimated_manhour, 0)) = 0 
                        AND SUM(IFNULL(actual_manhour, 0)) > 0 
                            THEN 1 
                        WHEN SUM(IFNULL(actual_manhour, 0)) = 0 
                            THEN NULL 
                        WHEN SUM(IFNULL(actual_manhour, 0)) > 0 
                            THEN SUM(IFNULL(estimated_manhour, 0)) / SUM(IFNULL(actual_manhour, 0)) 
                        ELSE NULL 
                        END AS RATE
                    , SUM(IFNULL(estimated_manhour, 0)) AS SUM_estimated_manhour
                    , SUM(IFNULL(actual_manhour, 0)) AS SUM_actual_manhour
                    , CASE 
                        WHEN SUM(IFNULL(actual_manhour, 0)) = 0 
                            THEN 1 
                        ELSE 2 
                        END AS JISSEKI_STATUS 
                FROM
                    dev_member_manhours 
                WHERE
                    develop_id = 112 
                    AND deleted_at IS NULL 
                GROUP BY
                    develop_id
                    , dev_assign_member_id
            ) AS SEIKYURATE 
            left join ( 
                SELECT
                    develop_id
                    , SUM(IFNULL(estimated_manhour, 0)) SUM_estimated_manhour 
                FROM
                    dev_member_manhours 
                WHERE
                    develop_id = 112 
                    AND deleted_at IS NULL 
                GROUP BY
                    develop_id
            ) SUM_estimated_manhour 
                on SUM_estimated_manhour.develop_id = SEIKYURATE.develop_id 
        GROUP BY
            SEIKYURATE.develop_id
            , SEIKYURATE.dev_assign_member_id
    ) AS SECOND_INFO 
    INNER JOIN develops 
        ON develops.id = SECOND_INFO.develop_id 
    INNER JOIN sales_projects 
        ON sales_projects.id = develops.sales_project_id 
    INNER JOIN project_contracts 
        ON project_contracts.sales_project_id = sales_projects.id 
    INNER JOIN ( 
        SELECT
            develop_id
            , 1 / SUM(SENYURATE) AS HOSEI 
        FROM
            ( 
                SELECT
                    SEIKYURATE.develop_id
                    , SEIKYURATE.dev_assign_member_id
                    , ( 
                        SEIKYURATE.SUM_estimated_manhour / SUM_estimated_manhour.SUM_estimated_manhour
                    ) * IFNULL(RATE, 0) AS SENYURATE
                FROM
                    ( 
                        SELECT
                            develop_id
                            , dev_assign_member_id
                            , CASE 
                                WHEN SUM(IFNULL(estimated_manhour, 0)) = 0 
                                AND SUM(IFNULL(actual_manhour, 0)) > 0 
                                    THEN 1 
                                WHEN SUM(IFNULL(actual_manhour, 0)) = 0 
                                    THEN NULL 
                                WHEN SUM(IFNULL(actual_manhour, 0)) > 0 
                                    THEN SUM(IFNULL(estimated_manhour, 0)) / SUM(IFNULL(actual_manhour, 0)) 
                                ELSE NULL 
                                END AS RATE
                            , SUM(IFNULL(estimated_manhour, 0)) SUM_estimated_manhour 
                        FROM
                            dev_member_manhours 
                        WHERE
                            develop_id = 112 
                            AND deleted_at IS NULL 
                        GROUP BY
                            develop_id
                            , dev_assign_member_id
                    ) AS SEIKYURATE 
                    left join ( 
                        SELECT
                            develop_id
                            , SUM(IFNULL(estimated_manhour, 0)) SUM_estimated_manhour 
                        FROM
                            dev_member_manhours 
                        WHERE
                            develop_id = 112 
                            AND deleted_at IS NULL 
                        GROUP BY
                            develop_id
                    ) SUM_estimated_manhour 
                        on SUM_estimated_manhour.develop_id = SEIKYURATE.develop_id 
                GROUP BY
                    SEIKYURATE.develop_id
                    , SEIKYURATE.dev_assign_member_id
            ) AS HOSEIKEISAN 
        GROUP BY
            develop_id
    ) AS HOSEI 
        ON SECOND_INFO.develop_id = HOSEI.develop_id 
where
    SECOND_INFO.develop_id = 112 
GROUP BY
    SECOND_INFO.develop_id
    , SECOND_INFO.dev_assign_member_id
    , SECOND_INFO.JISSEKI_STATUS
    , SECOND_INFO.RATE
    , SECOND_INFO.SUM_estimated_manhour
    , SECOND_INFO.SENYURATE
    , SECOND_INFO.SUM_actual_manhour
    , project_contracts.order_amount
    , HOSEI.HOSEI
    , sales_projects.id;
