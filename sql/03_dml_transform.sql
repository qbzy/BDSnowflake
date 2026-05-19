TRUNCATE TABLE
    dwh.fact_sales,
    dwh.dim_product,
    dwh.dim_store,
    dwh.dim_supplier,
    dwh.dim_seller,
    dwh.dim_customer,
    dwh.dim_date,
    dwh.dim_product_material,
    dwh.dim_product_brand,
    dwh.dim_product_category,
    dwh.dim_pet_category,
    dwh.dim_pet_type,
    dwh.dim_country
RESTART IDENTITY CASCADE;

CREATE TEMP TABLE src AS
SELECT
    staging_id,
    id AS source_sale_id,
    sale_customer_id AS source_customer_id,
    sale_seller_id AS source_seller_id,
    sale_product_id AS source_product_id,
    NULLIF(TRIM(customer_first_name), '') AS customer_first_name,
    NULLIF(TRIM(customer_last_name), '') AS customer_last_name,
    customer_age,
    NULLIF(TRIM(customer_email), '') AS customer_email,
    NULLIF(TRIM(customer_country), '') AS customer_country,
    NULLIF(TRIM(customer_postal_code), '') AS customer_postal_code,
    NULLIF(TRIM(customer_pet_type), '') AS customer_pet_type,
    NULLIF(TRIM(customer_pet_name), '') AS customer_pet_name,
    NULLIF(TRIM(customer_pet_breed), '') AS customer_pet_breed,
    NULLIF(TRIM(seller_first_name), '') AS seller_first_name,
    NULLIF(TRIM(seller_last_name), '') AS seller_last_name,
    NULLIF(TRIM(seller_email), '') AS seller_email,
    NULLIF(TRIM(seller_country), '') AS seller_country,
    NULLIF(TRIM(seller_postal_code), '') AS seller_postal_code,
    NULLIF(TRIM(product_name), '') AS product_name,
    NULLIF(TRIM(product_category), '') AS product_category,
    product_price,
    product_quantity,
    to_date(NULLIF(TRIM(sale_date), ''), 'MM/DD/YYYY') AS sale_dt,
    sale_quantity,
    sale_total_price,
    NULLIF(TRIM(store_name), '') AS store_name,
    NULLIF(TRIM(store_location), '') AS store_location,
    NULLIF(TRIM(store_city), '') AS store_city,
    NULLIF(TRIM(store_state), '') AS store_state,
    NULLIF(TRIM(store_country), '') AS store_country,
    NULLIF(TRIM(store_phone), '') AS store_phone,
    NULLIF(TRIM(store_email), '') AS store_email,
    NULLIF(TRIM(pet_category), '') AS pet_category,
    product_weight,
    NULLIF(TRIM(product_color), '') AS product_color,
    NULLIF(TRIM(product_size), '') AS product_size,
    NULLIF(TRIM(product_brand), '') AS product_brand,
    NULLIF(TRIM(product_material), '') AS product_material,
    NULLIF(TRIM(product_description), '') AS product_description,
    product_rating,
    product_reviews,
    to_date(NULLIF(TRIM(product_release_date), ''), 'MM/DD/YYYY') AS product_release_dt,
    to_date(NULLIF(TRIM(product_expiry_date), ''), 'MM/DD/YYYY') AS product_expiry_dt,
    NULLIF(TRIM(supplier_name), '') AS supplier_name,
    NULLIF(TRIM(supplier_contact), '') AS supplier_contact,
    NULLIF(TRIM(supplier_email), '') AS supplier_email,
    NULLIF(TRIM(supplier_phone), '') AS supplier_phone,
    NULLIF(TRIM(supplier_address), '') AS supplier_address,
    NULLIF(TRIM(supplier_city), '') AS supplier_city,
    NULLIF(TRIM(supplier_country), '') AS supplier_country
FROM staging.mock_data;

INSERT INTO dwh.dim_country (country_name)
SELECT DISTINCT country_name
FROM (
    SELECT customer_country AS country_name FROM src
    UNION ALL SELECT seller_country FROM src
    UNION ALL SELECT store_country FROM src
    UNION ALL SELECT supplier_country FROM src
) c
WHERE country_name IS NOT NULL
ORDER BY country_name;

INSERT INTO dwh.dim_pet_type (pet_type_name)
SELECT DISTINCT customer_pet_type
FROM src
WHERE customer_pet_type IS NOT NULL
ORDER BY customer_pet_type;

INSERT INTO dwh.dim_pet_category (pet_category_name)
SELECT DISTINCT pet_category
FROM src
WHERE pet_category IS NOT NULL
ORDER BY pet_category;

INSERT INTO dwh.dim_product_category (product_category_name)
SELECT DISTINCT product_category
FROM src
WHERE product_category IS NOT NULL
ORDER BY product_category;

INSERT INTO dwh.dim_product_brand (product_brand_name)
SELECT DISTINCT product_brand
FROM src
WHERE product_brand IS NOT NULL
ORDER BY product_brand;

INSERT INTO dwh.dim_product_material (product_material_name)
SELECT DISTINCT product_material
FROM src
WHERE product_material IS NOT NULL
ORDER BY product_material;

INSERT INTO dwh.dim_date (date_key, full_date, year, quarter, month, day, day_of_week)
SELECT DISTINCT
    to_char(sale_dt, 'YYYYMMDD')::INTEGER AS date_key,
    sale_dt AS full_date,
    EXTRACT(YEAR FROM sale_dt)::SMALLINT AS year,
    EXTRACT(QUARTER FROM sale_dt)::SMALLINT AS quarter,
    EXTRACT(MONTH FROM sale_dt)::SMALLINT AS month,
    EXTRACT(DAY FROM sale_dt)::SMALLINT AS day,
    EXTRACT(ISODOW FROM sale_dt)::SMALLINT AS day_of_week
FROM src
WHERE sale_dt IS NOT NULL
ORDER BY full_date;

INSERT INTO dwh.dim_customer (
    source_customer_id, first_name, last_name, age, email, country_id,
    postal_code, pet_type_id, pet_name, pet_breed
)
SELECT DISTINCT
    s.source_customer_id,
    s.customer_first_name,
    s.customer_last_name,
    s.customer_age,
    s.customer_email,
    c.country_id,
    s.customer_postal_code,
    pt.pet_type_id,
    s.customer_pet_name,
    s.customer_pet_breed
FROM src s
LEFT JOIN dwh.dim_country c ON c.country_name = s.customer_country
LEFT JOIN dwh.dim_pet_type pt ON pt.pet_type_name = s.customer_pet_type;

INSERT INTO dwh.dim_seller (
    source_seller_id, first_name, last_name, email, country_id, postal_code
)
SELECT DISTINCT
    s.source_seller_id,
    s.seller_first_name,
    s.seller_last_name,
    s.seller_email,
    c.country_id,
    s.seller_postal_code
FROM src s
LEFT JOIN dwh.dim_country c ON c.country_name = s.seller_country;

INSERT INTO dwh.dim_supplier (
    supplier_name, supplier_contact, supplier_email, supplier_phone,
    supplier_address, supplier_city, country_id
)
SELECT DISTINCT
    s.supplier_name,
    s.supplier_contact,
    s.supplier_email,
    s.supplier_phone,
    s.supplier_address,
    s.supplier_city,
    c.country_id
FROM src s
LEFT JOIN dwh.dim_country c ON c.country_name = s.supplier_country;

INSERT INTO dwh.dim_store (
    store_name, store_location, store_city, store_state, country_id,
    store_phone, store_email
)
SELECT DISTINCT
    s.store_name,
    s.store_location,
    s.store_city,
    s.store_state,
    c.country_id,
    s.store_phone,
    s.store_email
FROM src s
LEFT JOIN dwh.dim_country c ON c.country_name = s.store_country;

INSERT INTO dwh.dim_product (
    source_product_id, product_name, product_category_id, pet_category_id,
    product_brand_id, product_material_id, supplier_id, product_weight,
    product_color, product_size, product_description, product_rating,
    product_reviews, product_release_date, product_expiry_date
)
SELECT DISTINCT
    s.source_product_id,
    s.product_name,
    pc.product_category_id,
    petc.pet_category_id,
    pb.product_brand_id,
    pm.product_material_id,
    sup.supplier_id,
    s.product_weight,
    s.product_color,
    s.product_size,
    s.product_description,
    s.product_rating,
    s.product_reviews,
    s.product_release_dt,
    s.product_expiry_dt
FROM src s
LEFT JOIN dwh.dim_product_category pc
    ON pc.product_category_name = s.product_category
LEFT JOIN dwh.dim_pet_category petc
    ON petc.pet_category_name = s.pet_category
LEFT JOIN dwh.dim_product_brand pb
    ON pb.product_brand_name = s.product_brand
LEFT JOIN dwh.dim_product_material pm
    ON pm.product_material_name = s.product_material
LEFT JOIN dwh.dim_country supplier_country
    ON supplier_country.country_name = s.supplier_country
JOIN dwh.dim_supplier sup
    ON sup.supplier_name IS NOT DISTINCT FROM s.supplier_name
    AND sup.supplier_contact IS NOT DISTINCT FROM s.supplier_contact
    AND sup.supplier_email IS NOT DISTINCT FROM s.supplier_email
    AND sup.supplier_phone IS NOT DISTINCT FROM s.supplier_phone
    AND sup.supplier_address IS NOT DISTINCT FROM s.supplier_address
    AND sup.supplier_city IS NOT DISTINCT FROM s.supplier_city
    AND sup.country_id IS NOT DISTINCT FROM supplier_country.country_id;

INSERT INTO dwh.fact_sales (
    staging_id, source_sale_id, sale_date_key, customer_id, seller_id,
    product_id, store_id, product_unit_price, product_available_quantity,
    sale_quantity, sale_total_price
)
SELECT
    s.staging_id,
    s.source_sale_id,
    dd.date_key,
    dc.customer_id,
    ds.seller_id,
    dp.product_id,
    st.store_id,
    s.product_price,
    s.product_quantity,
    s.sale_quantity,
    s.sale_total_price
FROM src s
LEFT JOIN dwh.dim_date dd
    ON dd.full_date = s.sale_dt
LEFT JOIN dwh.dim_country customer_country
    ON customer_country.country_name = s.customer_country
LEFT JOIN dwh.dim_pet_type pt
    ON pt.pet_type_name = s.customer_pet_type
JOIN dwh.dim_customer dc
    ON dc.source_customer_id IS NOT DISTINCT FROM s.source_customer_id
    AND dc.first_name IS NOT DISTINCT FROM s.customer_first_name
    AND dc.last_name IS NOT DISTINCT FROM s.customer_last_name
    AND dc.age IS NOT DISTINCT FROM s.customer_age
    AND dc.email IS NOT DISTINCT FROM s.customer_email
    AND dc.country_id IS NOT DISTINCT FROM customer_country.country_id
    AND dc.postal_code IS NOT DISTINCT FROM s.customer_postal_code
    AND dc.pet_type_id IS NOT DISTINCT FROM pt.pet_type_id
    AND dc.pet_name IS NOT DISTINCT FROM s.customer_pet_name
    AND dc.pet_breed IS NOT DISTINCT FROM s.customer_pet_breed
LEFT JOIN dwh.dim_country seller_country
    ON seller_country.country_name = s.seller_country
JOIN dwh.dim_seller ds
    ON ds.source_seller_id IS NOT DISTINCT FROM s.source_seller_id
    AND ds.first_name IS NOT DISTINCT FROM s.seller_first_name
    AND ds.last_name IS NOT DISTINCT FROM s.seller_last_name
    AND ds.email IS NOT DISTINCT FROM s.seller_email
    AND ds.country_id IS NOT DISTINCT FROM seller_country.country_id
    AND ds.postal_code IS NOT DISTINCT FROM s.seller_postal_code
LEFT JOIN dwh.dim_country store_country
    ON store_country.country_name = s.store_country
JOIN dwh.dim_store st
    ON st.store_name IS NOT DISTINCT FROM s.store_name
    AND st.store_location IS NOT DISTINCT FROM s.store_location
    AND st.store_city IS NOT DISTINCT FROM s.store_city
    AND st.store_state IS NOT DISTINCT FROM s.store_state
    AND st.country_id IS NOT DISTINCT FROM store_country.country_id
    AND st.store_phone IS NOT DISTINCT FROM s.store_phone
    AND st.store_email IS NOT DISTINCT FROM s.store_email
LEFT JOIN dwh.dim_product_category pc
    ON pc.product_category_name = s.product_category
LEFT JOIN dwh.dim_pet_category petc
    ON petc.pet_category_name = s.pet_category
LEFT JOIN dwh.dim_product_brand pb
    ON pb.product_brand_name = s.product_brand
LEFT JOIN dwh.dim_product_material pm
    ON pm.product_material_name = s.product_material
LEFT JOIN dwh.dim_country supplier_country
    ON supplier_country.country_name = s.supplier_country
JOIN dwh.dim_supplier sup
    ON sup.supplier_name IS NOT DISTINCT FROM s.supplier_name
    AND sup.supplier_contact IS NOT DISTINCT FROM s.supplier_contact
    AND sup.supplier_email IS NOT DISTINCT FROM s.supplier_email
    AND sup.supplier_phone IS NOT DISTINCT FROM s.supplier_phone
    AND sup.supplier_address IS NOT DISTINCT FROM s.supplier_address
    AND sup.supplier_city IS NOT DISTINCT FROM s.supplier_city
    AND sup.country_id IS NOT DISTINCT FROM supplier_country.country_id
JOIN dwh.dim_product dp
    ON dp.source_product_id IS NOT DISTINCT FROM s.source_product_id
    AND dp.product_name IS NOT DISTINCT FROM s.product_name
    AND dp.product_category_id IS NOT DISTINCT FROM pc.product_category_id
    AND dp.pet_category_id IS NOT DISTINCT FROM petc.pet_category_id
    AND dp.product_brand_id IS NOT DISTINCT FROM pb.product_brand_id
    AND dp.product_material_id IS NOT DISTINCT FROM pm.product_material_id
    AND dp.supplier_id IS NOT DISTINCT FROM sup.supplier_id
    AND dp.product_weight IS NOT DISTINCT FROM s.product_weight
    AND dp.product_color IS NOT DISTINCT FROM s.product_color
    AND dp.product_size IS NOT DISTINCT FROM s.product_size
    AND dp.product_description IS NOT DISTINCT FROM s.product_description
    AND dp.product_rating IS NOT DISTINCT FROM s.product_rating
    AND dp.product_reviews IS NOT DISTINCT FROM s.product_reviews
    AND dp.product_release_date IS NOT DISTINCT FROM s.product_release_dt
    AND dp.product_expiry_date IS NOT DISTINCT FROM s.product_expiry_dt;
