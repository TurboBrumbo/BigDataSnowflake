CREATE SCHEMA IF NOT EXISTS stg;
CREATE SCHEMA IF NOT EXISTS dw;

DROP TABLE IF EXISTS stg.mock_data;

CREATE TABLE stg.mock_data (
  id                    int,
  customer_first_name   text,
  customer_last_name    text,
  customer_age          int,
  customer_email        text,
  customer_country      text,
  customer_postal_code  text,
  customer_pet_type     text,
  customer_pet_name     text,
  customer_pet_breed    text,

  seller_first_name     text,
  seller_last_name      text,
  seller_email          text,
  seller_country        text,
  seller_postal_code    text,

  product_name          text,
  product_category      text,
  product_price         numeric(12,2),
  product_quantity      int,

  sale_date             text,
  sale_customer_id      int,
  sale_seller_id        int,
  sale_product_id       int,
  sale_quantity         int,
  sale_total_price      numeric(12,2),

  store_name            text,
  store_location        text,
  store_city            text,
  store_state           text,
  store_country         text,
  store_phone           text,
  store_email           text,

  pet_category          text,
  product_weight        numeric(12,3),
  product_color         text,
  product_size          text,
  product_brand         text,
  product_material      text,
  product_description   text,
  product_rating        numeric(3,2),
  product_reviews       int,
  product_release_date  text,
  product_expiry_date   text,

  supplier_name         text,
  supplier_contact      text,
  supplier_email        text,
  supplier_phone        text,
  supplier_address      text,
  supplier_city         text,
  supplier_country      text
);

DROP TABLE IF EXISTS dw.fact_sales;
DROP TABLE IF EXISTS dw.dim_product;
DROP TABLE IF EXISTS dw.dim_customer;
DROP TABLE IF EXISTS dw.dim_seller;
DROP TABLE IF EXISTS dw.dim_store;
DROP TABLE IF EXISTS dw.dim_supplier;
DROP TABLE IF EXISTS dw.dim_date;
DROP TABLE IF EXISTS dw.dim_city;
DROP TABLE IF EXISTS dw.dim_country;
DROP TABLE IF EXISTS dw.dim_product_category;
DROP TABLE IF EXISTS dw.dim_brand;
DROP TABLE IF EXISTS dw.dim_material;
DROP TABLE IF EXISTS dw.dim_color;
DROP TABLE IF EXISTS dw.dim_size;
DROP TABLE IF EXISTS dw.dim_pet_category;

CREATE TABLE dw.dim_country (
  country_key  bigserial PRIMARY KEY,
  country_name text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_city (
  city_key     bigserial PRIMARY KEY,
  city_name    text NOT NULL,
  state_name   text,
  country_key  bigint NOT NULL REFERENCES dw.dim_country(country_key),
  UNIQUE(city_name, state_name, country_key)
);

CREATE TABLE dw.dim_product_category (
  product_category_key bigserial PRIMARY KEY,
  category_name        text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_brand (
  brand_key  bigserial PRIMARY KEY,
  brand_name text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_material (
  material_key  bigserial PRIMARY KEY,
  material_name text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_color (
  color_key  bigserial PRIMARY KEY,
  color_name text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_size (
  size_key  bigserial PRIMARY KEY,
  size_name text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_pet_category (
  pet_category_key bigserial PRIMARY KEY,
  pet_category_name text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_customer (
  customer_key      bigserial PRIMARY KEY,
  customer_email    text NOT NULL UNIQUE,
  first_name        text,
  last_name         text,
  age               int,
  country_key       bigint REFERENCES dw.dim_country(country_key),
  postal_code       text,
  pet_type          text,
  pet_name          text,
  pet_breed         text
);

CREATE TABLE dw.dim_seller (
  seller_key      bigserial PRIMARY KEY,
  seller_email    text NOT NULL UNIQUE,
  first_name      text,
  last_name       text,
  country_key     bigint REFERENCES dw.dim_country(country_key),
  postal_code     text
);

CREATE TABLE dw.dim_supplier (
  supplier_key    bigserial PRIMARY KEY,
  supplier_email  text NOT NULL UNIQUE,
  supplier_name   text,
  contact_name    text,
  phone           text,
  address         text,
  city_key        bigint REFERENCES dw.dim_city(city_key)
);

CREATE TABLE dw.dim_store (
  store_key     bigserial PRIMARY KEY,
  store_email   text NOT NULL UNIQUE,
  store_name    text,
  location      text,
  phone         text,
  city_key      bigint REFERENCES dw.dim_city(city_key)
);

CREATE TABLE dw.dim_product (
  product_key           bigserial PRIMARY KEY,
  product_name          text,
  product_category_key  bigint REFERENCES dw.dim_product_category(product_category_key),
  brand_key             bigint REFERENCES dw.dim_brand(brand_key),
  material_key          bigint REFERENCES dw.dim_material(material_key),
  color_key             bigint REFERENCES dw.dim_color(color_key),
  size_key              bigint REFERENCES dw.dim_size(size_key),
  pet_category_key      bigint REFERENCES dw.dim_pet_category(pet_category_key),

  product_price         numeric(12,2),
  product_weight        numeric(12,3),
  product_description   text,
  product_rating        numeric(3,2),
  product_reviews       int,
  product_release_date  date,
  product_expiry_date   date,

  supplier_key          bigint REFERENCES dw.dim_supplier(supplier_key)
);

CREATE TABLE dw.dim_date (
  date_key     int PRIMARY KEY,          -- yyyymmdd
  full_date    date NOT NULL UNIQUE,
  year         int,
  quarter      int,
  month        int,
  day          int,
  dow          int
);

CREATE TABLE dw.fact_sales (
  sales_key        bigserial PRIMARY KEY,
  date_key         int NOT NULL REFERENCES dw.dim_date(date_key),
  customer_key     bigint NOT NULL REFERENCES dw.dim_customer(customer_key),
  seller_key       bigint NOT NULL REFERENCES dw.dim_seller(seller_key),
  store_key        bigint NOT NULL REFERENCES dw.dim_store(store_key),
  product_key      bigint NOT NULL REFERENCES dw.dim_product(product_key),

  sale_quantity    int,
  sale_total_price numeric(12,2),

  sale_customer_id int,
  sale_seller_id   int,
  sale_product_id  int
);
