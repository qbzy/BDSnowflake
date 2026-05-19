SELECT 'staging.mock_data' AS table_name, COUNT(*) AS row_count
FROM staging.mock_data
UNION ALL
SELECT 'dwh.fact_sales', COUNT(*) FROM dwh.fact_sales
UNION ALL
SELECT 'dwh.dim_customer', COUNT(*) FROM dwh.dim_customer
UNION ALL
SELECT 'dwh.dim_seller', COUNT(*) FROM dwh.dim_seller
UNION ALL
SELECT 'dwh.dim_product', COUNT(*) FROM dwh.dim_product
UNION ALL
SELECT 'dwh.dim_store', COUNT(*) FROM dwh.dim_store
UNION ALL
SELECT 'dwh.dim_supplier', COUNT(*) FROM dwh.dim_supplier;

SELECT
    (SELECT COUNT(*) FROM staging.mock_data) AS staging_rows,
    (SELECT COUNT(*) FROM dwh.fact_sales) AS fact_rows,
    (SELECT COUNT(*) FROM staging.mock_data) - (SELECT COUNT(*) FROM dwh.fact_sales) AS missing_fact_rows;

SELECT
    pc.product_category_name,
    SUM(f.sale_quantity) AS sold_items,
    ROUND(SUM(f.sale_total_price), 2) AS revenue
FROM dwh.fact_sales f
JOIN dwh.dim_product p ON p.product_id = f.product_id
LEFT JOIN dwh.dim_product_category pc ON pc.product_category_id = p.product_category_id
GROUP BY pc.product_category_name
ORDER BY revenue DESC;

SELECT
    co.country_name AS store_country,
    COUNT(*) AS sales_count,
    ROUND(SUM(f.sale_total_price), 2) AS revenue
FROM dwh.fact_sales f
JOIN dwh.dim_store s ON s.store_id = f.store_id
LEFT JOIN dwh.dim_country co ON co.country_id = s.country_id
GROUP BY co.country_name
ORDER BY revenue DESC
LIMIT 10;
