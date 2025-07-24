CREATE DATABASE restaurant;
GO        -- Ends the batch

USE restaurant;
GO        -- Starts a new batch using the new database

CREATE TABLE sales (
    cust_id NVARCHAR(5),
    order_date DATE,
    product_id INT
);
GO

ALTER TABLE sales DROP COLUMN product_id;
GO

ALTER TABLE sales ADD menu_id INT;
GO

select * from sales;
GO

CREATE TABLE members (
  cust_id NVARCHAR(5),
  cust_name nvarchar(20),
  join_date timestamp,
  region NVARCHAR(5),
  email nvarchar(20)
)
GO

ALTER TABLE members DROP COLUMN join_date;
GO

ALTER TABLE members ADD join_date DATETIME;
GO

select * from members;
GO

CREATE TABLE menu (
    menu_id int,
    menu_name nvarchar(20),
    price decimal(5)
  )
GO

select * from menu;
GO


ALTER TABLE menu ADD menu_type nvarchar(10) CHECK (menu_type IN ('VEG', 'NON-VEG'));


UPDATE menu
SET menu_type = CASE 
    WHEN menu_id IN (1,8,11,12,13) THEN 'NON-VEG'
    ELSE 'VEG'
END;
