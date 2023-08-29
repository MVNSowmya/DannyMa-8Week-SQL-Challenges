-- Introduction
Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.
Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

-- Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.
He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.
Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!
Danny has shared with you 3 key datasets for this case study:
sales, menu, members

-- Schema SQL
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

-- Query SQL

-- 1. What is the total amount each customer spent at the restaurant?
with cte as (
select s.customer_id, s.product_id, m.price from dannys_diner.sales s inner join dannys_diner.menu m 
on s.product_id = m.product_id
)
select customer_id, sum(price) as total_amount from cte group by customer_id order by customer_id;

-- 2. How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as visited_days from dannys_diner.sales group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
with cte as (
select s.customer_id, s.product_id, m.product_name,
row_number() over (partition by s.customer_id order by order_date) as r
from dannys_diner.sales s inner join dannys_diner.menu m
on s.product_id = m.product_id
)
select customer_id, product_id, product_name from cte where r = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select s.product_id, m.product_name, count(s.product_id) as purchase_count from 
dannys_diner.sales s inner join dannys_diner.menu m on s.product_id = m.product_id 
group by s.product_id, m.product_name order by count(s.product_id) desc limit 1;

-- 5. Which item was the most popular for each customer?
with cte1 as(
select s.customer_id, s.product_id, m.product_name, count(s.product_id) as purchase_count from 
dannys_diner.sales s inner join dannys_diner.menu m on s.product_id = m.product_id 
group by s.customer_id, s.product_id, m.product_name 
), cte2 as (
select *, dense_rank() over (partition by customer_id order by 
                             purchase_count desc) as r from cte1
)
select customer_id, product_id, product_name, purchase_count from cte2 where r = 1 
order by customer_id, product_id;

-- 6. Which item was purchased first by the customer after they became a member?
with cte1 as (
select s.customer_id, s.order_date, s.product_id, m.product_name, 
mem.join_date from dannys_diner.menu m inner join dannys_diner.sales s on m.product_id = s.product_id inner join
dannys_diner.members mem on s.customer_id = mem.customer_id 
where s.order_date > mem.join_date  
), cte2 as (
select *, dense_rank() over(partition by customer_id order by 
order_date) as r from cte1
)
select customer_id, join_date, order_Date, product_id, product_name from cte2 where r = 1;

-- 7. Which item was purchased just before the customer became a member?
with cte1 as (
select s.customer_id, s.order_date, s.product_id, m.product_name, 
mem.join_date from dannys_diner.menu m inner join dannys_diner.sales s on m.product_id = s.product_id inner join
dannys_diner.members mem on s.customer_id = mem.customer_id 
where s.order_date < mem.join_date  
), cte2 as (
select *, dense_rank() over(partition by customer_id order by 
order_date desc) as r from cte1
)
select customer_id, join_date, order_Date, product_id, product_name from cte2 where r = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
with cte1 as (
select s.customer_id, s.order_date, s.product_id, m.product_name,m.price, mem.join_date 
from dannys_diner.menu m inner join dannys_diner.sales s on m.product_id = s.product_id inner join
dannys_diner.members mem on s.customer_id = mem.customer_id 
where s.order_date < mem.join_date  
)
select customer_id, count(product_id) as total_items, sum(price)
as amount_spent from cte1 group by customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with cte1 as (
select s.customer_id, s.product_id, m.product_name, sum(m.price) as total_item_price from 
dannys_diner.sales s inner join dannys_diner.menu m on
s.product_id = m.product_id 
group by s.customer_id, s.product_id, m.product_name
), cte2 as (
select *, case 
when product_name = 'sushi' then total_item_price * 10 * 2
else total_item_price * 10 end as total_item_points from cte1
)
select customer_id, sum(total_item_points) as total_points from cte2 group by customer_id;

-- 10.  In the first week after a customer joins the program (including their join date) they earn 2x points 
-- on all items, not just sushi - how many points do customer A and B have at the end of January?

select s.customer_id,
sum(IF(s.order_date between mem.join_date and DATE_ADD(mem.join_date, interval 6 day), m.price*10*2, 
IF(m.product_name = 'sushi', price*10*2, price*10))) as customer_points from
dannys_diner.menu m inner join dannys_diner.sales s on m.product_id = s.product_id inner join 
dannys_diner.members mem on mem.customer_id = s.customer_id where s.order_date >= mem.join_date 
and s.order_date <= '2021-01-31' group by s.customer_id order by s.customer_id;


-- Bonus Questions

-- Join all the things
-- Create basic data tables that Danny and his team can use to quickly derive insights without needing 
-- to join the underlying tables using SQL. Fill Member column as 'N' if the purchase was made before 
-- becoming a member and 'Y' if the after is amde after joining the membership.
select s.customer_id, s.order_date, m.product_name, m.price, 
case when s.order_date >= mem.join_date then 'Y' ELSE 'N' end as member 
from dannys_diner.members mem right join dannys_diner.sales s on mem.customer_id = s.customer_id 
inner join dannys_diner.menu m on s.product_id = m.product_id order by s.customer_id, s.order_date;

-- Rank all the things
-- Danny also requires further information about the ranking of customer products, but he purposely does not 
-- need the ranking for non-member purchases so he expects null ranking values for the records when customers 
-- are not yet part of the loyalty program.
with cte1 as (
select s.customer_id, s.order_date, m.product_name, m.price, 
case when s.order_date >= mem.join_date then 'Y' ELSE 'N' end as member 
from dannys_diner.members mem right join dannys_diner.sales s on mem.customer_id = s.customer_id 
inner join dannys_diner.menu m on s.product_id = m.product_id
)
select *, case when member = 'N' then NULL else
dense_rank() over (partition by customer_id, member order by order_date) end as ranking from cte1;
