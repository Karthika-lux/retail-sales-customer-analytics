use capstone;

create table categories (
    category_id int primary key,
    category_name varchar(100) not null
);

create table brands (
    brand_id int primary key,
    brand_name varchar(100) not null
);

create table stores (
    store_id int primary key,
    store_name varchar(100),
    phone varchar(25),
    email varchar(100),
    street varchar(150),
    city varchar(100),
    state varchar(50),
    zip_code varchar(10)
);

create table customers (
    customer_id int primary key,
    first_name varchar(50),
    last_name varchar(50),
    phone varchar(25),
    email varchar(100),
    street varchar(150),
    city varchar(100),
    state varchar(50),
    zip_code varchar(10)
);

create table staffs (
    staff_id int primary key,
    first_name varchar(50),
    last_name varchar(50),
    email varchar(100),
    phone varchar(25),
    active tinyint,
    store_id int,
    manager_id int,
    foreign key (store_id) references stores(store_id)
);

create table products (
    product_id int primary key,
    product_name varchar(150),
    brand_id int,
    category_id int,
    model_year int,
    list_price decimal(10,2),
    foreign key (brand_id) references brands(brand_id),
    foreign key (category_id) references categories(category_id)
);

create table orders (
    order_id int primary key,
    customer_id int,
    order_status int,
    order_date date,
    required_date date,
    shipped_date date,
    store_id int,
    staff_id int,
    foreign key (customer_id) references customers(customer_id),
    foreign key (store_id) references stores(store_id),
    foreign key (staff_id) references staffs(staff_id)
);

create table order_items (
    order_id int,
    item_id int,
    product_id int,
    quantity int,
    list_price decimal(10,2),
    discount decimal(4,2),
    primary key (order_id, item_id),
    foreign key (order_id) references orders(order_id),
    foreign key (product_id) references products(product_id)
);

create table stocks (
    store_id int,
    product_id int,
    quantity int,
    primary key (store_id, product_id),
    foreign key (store_id) references stores(store_id),
    foreign key (product_id) references products(product_id)
);


create table customer_segments (
    customer_id int primary key,
    recency int,
    frequency int,
    monetary decimal(10,2),
    segment varchar(50),
    foreign key (customer_id) references customers(customer_id)
);

SHOW TABLES;
select * from capstone.orders;
select* from capstone.customers;

use capstone;
 select * from stores;
  select 
  (select count(*) from stores) as stores_count,
  (select count(*) from staffs) as staffs_count,
  (select count(*) from customers) as customers_count,
  (select count(*) from products) as products_count,
  (select count(*) from orders) as orders_count,
  (select count(*) from order_items) as order_items_count,
  (select count(*) from stocks) as stocks_count;
  
  --  Inner Join for Order Details - Join orders, order_items, and products to display detailed line items.
use capstone;
 select 
    o.order_id,o.order_date,p.product_name,od.quantity,od.list_price,od.discount
from orders o
inner join order_items od on o.order_id = od.order_id
inner join products p on od.product_id = p.product_id
limit 20;

-- Total Sales by Store - Write a query to group sales (total_price) by each store_id

select
    s.store_name,
    ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 2) AS total_sales
from orders o
inner join order_items oi on o.order_id = oi.order_id
inner join stores s on o.store_id = s.store_id
group by s.store_name
order by total_sales desc;

-- Top 5 Selling Products -  Use ORDER BY and LIMIT to get the top 5 most sold products by quantity. 

select
    p.product_name,SUM(oi.quantity) as total_quantity_sold
from order_items oi
inner join products p on oi.product_id = p.product_id
group by p.product_name
order by total_quantity_sold desc
limit 5;


-- Customer Purchase Summary - For each customer, return total orders placed, total items purchased,and total revenue. 

select 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(distinct o.order_id) as total_orders,
    SUM(oi.quantity) as total_items,
    ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 2) as total_revenue
from customers c
inner join orders o on c.customer_id = o.customer_id
inner join order_items oi on o.order_id = oi.order_id
group by c.customer_id, c.first_name, c.last_name
order by total_revenue desc
limit 10;

-- Segment Customers by Total Spend - Write a query to classify customers into spending brackets (e.g., low,medium, high). 

select
    c.customer_id,c.first_name,c.last_name,
    ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 2) as total_spend,
    case 
        when SUM(oi.quantity * oi.list_price * (1 - oi.discount)) >= 10000 then 'High'
        when SUM(oi.quantity * oi.list_price * (1 - oi.discount)) >= 3000 then 'Medium'
        else 'Low'
    end as spend_segment
from customers c
inner join orders o on c.customer_id = o.customer_id
inner join order_items oi on o.order_id = oi.order_id
group by c.customer_id, c.first_name, c.last_name
order by total_spend desc;

-- Staff Performance Analysis - Analyze total revenue generated by each staff member based on their handled orders. 
select
    st.staff_id,
    st.first_name,
    st.last_name,
    COUNT(DISTINCT o.order_id) AS total_orders_handled,
    ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 2) AS total_revenue
FROM staffs st
INNER JOIN orders o ON st.staff_id = o.staff_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY st.staff_id, st.first_name, st.last_name
ORDER BY total_revenue DESC;

-- Stock Alert Query - Write a query to list products where stock quantity < 10 in any store. 
select
    s.store_name,
    p.product_name,
    st.quantity
FROM stocks st
inner join stores s on st.store_id = s.store_id
inner join products p on st.product_id = p.product_id
where st.quantity < 10
order by st.quantity asc;


--  Create Final Segmentation Table - Create a table customer_segments that will be populated from Python ML results later. 

-- 1.  customers table
create table customers (
    customer_id int primary key,
    first_name varchar(50),
    last_name varchar(50),
    phone varchar(25),
    email varchar(100),
    street varchar(150),
    city varchar(100),
    state varchar(50),
    zip_code varchar(10)
);

-- 2. load data --
load data infile 'c:/programdata/mysql/mysql server 8.0/uploads/customers.csv'
into table customers
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows
(customer_id, first_name, last_name, @old_phone, email, street, city, state, zip_code, phone);

-- 3.  segmentation table
create table customer_segments (
    customer_id int primary key,
    recency int,
    frequency int,
    monetary decimal(10,2),
    segment varchar(50),
    foreign key (customer_id) references customers(customer_id)
);


select count(*) from customers;
show tables like 'customer_segments';
describe customer_segments;
