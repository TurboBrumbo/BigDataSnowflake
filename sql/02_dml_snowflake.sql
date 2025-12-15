-- =========================
-- 1) Countries
-- =========================
INSERT INTO dw.dim_country(country_name)
SELECT DISTINCT country_name
FROM (
  SELECT NULLIF(TRIM(customer_country), '') AS country_name FROM stg.mock_data
  UNION
  SELECT NULLIF(TRIM(seller_country), '')   FROM stg.mock_data
  UNION
  SELECT NULLIF(TRIM(store_country), '')    FROM stg.mock_data
  UNION
  SELECT NULLIF(TRIM(supplier_country), '') FROM stg.mock_data
) t
WHERE country_name IS NOT NULL
ON CONFLICT (country_name) DO NOTHING;

-- =========================
-- 2) Cities (store + supplier)
-- =========================
INSERT INTO dw.dim_city(city_name, state_name, country_key)
SELECT DISTINCT
  NULLIF(TRIM(city_name), '') AS city_name,
  NULLIF(TRIM(state_name), '') AS state_name,
  c.country_key
FROM (
  SELECT store_city AS city_name, store_state AS state_name, store_country AS country_name
  FROM stg.mock_data
  UNION ALL
  SELECT supplier_city, NULL::text, supplier_country
  FROM stg.mock_data
) x
JOIN dw.dim_country c
  ON c.country_name = NULLIF(TRIM(x.country_name), '')
WHERE NULLIF(TRIM(city_name), '') IS NOT NULL
ON CONFLICT (city_name, state_name, country_key) DO NOTHING;

-- =========================
-- 3) Small product dictionaries
-- =========================
INSERT INTO dw.dim_product_category(category_name)
SELECT DISTINCT NULLIF(TRIM(product_category), '')
FROM stg.mock_data
WHERE NULLIF(TRIM(product_category), '') IS NOT NULL
ON CONFLICT (category_name) DO NOTHING;

INSERT INTO dw.dim_brand(brand_name)
SELECT DISTINCT NULLIF(TRIM(product_brand), '')
FROM stg.mock_data
WHERE NULLIF(TRIM(product_brand), '') IS NOT NULL
ON CONFLICT (brand_name) DO NOTHING;

INSERT INTO dw.dim_material(material_name)
SELECT DISTINCT NULLIF(TRIM(product_material), '')
FROM stg.mock_data
WHERE NULLIF(TRIM(product_material), '') IS NOT NULL
ON CONFLICT (material_name) DO NOTHING;

INSERT INTO dw.dim_color(color_name)
SELECT DISTINCT NULLIF(TRIM(product_color), '')
FROM stg.mock_data
WHERE NULLIF(TRIM(product_color), '') IS NOT NULL
ON CONFLICT (color_name) DO NOTHING;

INSERT INTO dw.dim_size(size_name)
SELECT DISTINCT NULLIF(TRIM(product_size), '')
FROM stg.mock_data
WHERE NULLIF(TRIM(product_size), '') IS NOT NULL
ON CONFLICT (size_name) DO NOTHING;

INSERT INTO dw.dim_pet_category(pet_category_name)
SELECT DISTINCT NULLIF(TRIM(pet_category), '')
FROM stg.mock_data
WHERE NULLIF(TRIM(pet_category), '') IS NOT NULL
ON CONFLICT (pet_category_name) DO NOTHING;

-- =========================
-- 4) Customer / Seller
-- =========================
INSERT INTO dw.dim_customer (
  customer_email, first_name, last_name, age, country_key, postal_code,
  pet_type, pet_name, pet_breed
)
SELECT DISTINCT
  md.customer_email,
  md.customer_first_name,
  md.customer_last_name,
  md.customer_age,
  c.country_key,
  md.customer_postal_code,
  md.customer_pet_type,
  md.customer_pet_name,
  md.customer_pet_breed
FROM stg.mock_data md
LEFT JOIN dw.dim_country c
  ON c.country_name = NULLIF(TRIM(md.customer_country), '')
WHERE md.customer_email IS NOT NULL
ON CONFLICT (customer_email) DO NOTHING;

INSERT INTO dw.dim_seller (
  seller_email, first_name, last_name, country_key, postal_code
)
SELECT DISTINCT
  md.seller_email,
  md.seller_first_name,
  md.seller_last_name,
  c.country_key,
  md.seller_postal_code
FROM stg.mock_data md
LEFT JOIN dw.dim_country c
  ON c.country_name = NULLIF(TRIM(md.seller_country), '')
WHERE md.seller_email IS NOT NULL
ON CONFLICT (seller_email) DO NOTHING;

-- =========================
-- 5) Supplier / Store (через city_key)
-- =========================
INSERT INTO dw.dim_supplier (
  supplier_email, supplier_name, contact_name, phone, address, city_key
)
SELECT DISTINCT
  md.supplier_email,
  md.supplier_name,
  md.supplier_contact,
  md.supplier_phone,
  md.supplier_address,
  ct.city_key
FROM stg.mock_data md
LEFT JOIN dw.dim_country co
  ON co.country_name = NULLIF(TRIM(md.supplier_country), '')
LEFT JOIN dw.dim_city ct
  ON ct.city_name  = NULLIF(TRIM(md.supplier_city), '')
 AND ct.state_name IS NULL
 AND ct.country_key = co.country_key
WHERE md.supplier_email IS NOT NULL
ON CONFLICT (supplier_email) DO NOTHING;

INSERT INTO dw.dim_store (
  store_email, store_name, location, phone, city_key
)
SELECT DISTINCT
  md.store_email,
  md.store_name,
  md.store_location,
  md.store_phone,
  ct.city_key
FROM stg.mock_data md
LEFT JOIN dw.dim_country co
  ON co.country_name = NULLIF(TRIM(md.store_country), '')
LEFT JOIN dw.dim_city ct
  ON ct.city_name  = NULLIF(TRIM(md.store_city), '')
 AND ct.state_name = NULLIF(TRIM(md.store_state), '')
 AND ct.country_key = co.country_key
WHERE md.store_email IS NOT NULL
ON CONFLICT (store_email) DO NOTHING;

-- =========================
-- 6) Product (ссылки на справочники + supplier_key)
-- =========================
INSERT INTO dw.dim_product (
  product_name,
  product_category_key,
  brand_key,
  material_key,
  color_key,
  size_key,
  pet_category_key,
  product_price,
  product_weight,
  product_description,
  product_rating,
  product_reviews,
  product_release_date,
  product_expiry_date,
  supplier_key
)
SELECT DISTINCT
  md.product_name,
  pc.product_category_key,
  b.brand_key,
  m.material_key,
  cl.color_key,
  sz.size_key,
  pet.pet_category_key,
  md.product_price,
  md.product_weight,
  md.product_description,
  md.product_rating,
  md.product_reviews,
  CASE WHEN NULLIF(TRIM(md.product_release_date), '') IS NULL THEN NULL
       ELSE to_date(md.product_release_date, 'MM/DD/YYYY') END,
  CASE WHEN NULLIF(TRIM(md.product_expiry_date), '') IS NULL THEN NULL
       ELSE to_date(md.product_expiry_date, 'MM/DD/YYYY') END,
  s.supplier_key
FROM stg.mock_data md
LEFT JOIN dw.dim_product_category pc ON pc.category_name = NULLIF(TRIM(md.product_category), '')
LEFT JOIN dw.dim_brand b            ON b.brand_name     = NULLIF(TRIM(md.product_brand), '')
LEFT JOIN dw.dim_material m         ON m.material_name  = NULLIF(TRIM(md.product_material), '')
LEFT JOIN dw.dim_color cl           ON cl.color_name    = NULLIF(TRIM(md.product_color), '')
LEFT JOIN dw.dim_size sz            ON sz.size_name     = NULLIF(TRIM(md.product_size), '')
LEFT JOIN dw.dim_pet_category pet   ON pet.pet_category_name = NULLIF(TRIM(md.pet_category), '')
LEFT JOIN dw.dim_supplier s         ON s.supplier_email = md.supplier_email;

-- =========================
-- 7) Date dimension (из sale_date)
-- =========================
INSERT INTO dw.dim_date(date_key, full_date, year, quarter, month, day, dow)
SELECT DISTINCT
  (extract(year  from d)::int * 10000 + extract(month from d)::int * 100 + extract(day from d)::int) as date_key,
  d as full_date,
  extract(year from d)::int,
  extract(quarter from d)::int,
  extract(month from d)::int,
  extract(day from d)::int,
  extract(dow from d)::int
FROM (
  SELECT to_date(sale_date, 'MM/DD/YYYY') AS d
  FROM stg.mock_data
  WHERE NULLIF(TRIM(sale_date), '') IS NOT NULL
) x
ON CONFLICT (date_key) DO NOTHING;

-- =========================
-- 8) Fact table
-- =========================
INSERT INTO dw.fact_sales(
  date_key, customer_key, seller_key, store_key, product_key,
  sale_quantity, sale_total_price,
  sale_customer_id, sale_seller_id, sale_product_id
)
SELECT
  dd.date_key,
  dc.customer_key,
  ds.seller_key,
  st.store_key,
  dp.product_key,

  md.sale_quantity,
  md.sale_total_price,
  md.sale_customer_id,
  md.sale_seller_id,
  md.sale_product_id
FROM stg.mock_data md
JOIN dw.dim_date dd
  ON dd.full_date = to_date(md.sale_date, 'MM/DD/YYYY')
JOIN dw.dim_customer dc
  ON dc.customer_email = md.customer_email
JOIN dw.dim_seller ds
  ON ds.seller_email = md.seller_email
JOIN dw.dim_store st
  ON st.store_email = md.store_email
JOIN dw.dim_product dp
  ON dp.product_name = md.product_name
 AND dp.product_price = md.product_price
 AND (dp.supplier_key IS NOT DISTINCT FROM (SELECT supplier_key FROM dw.dim_supplier WHERE supplier_email = md.supplier_email LIMIT 1));
