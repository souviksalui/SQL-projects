-- 1. total amount spent by each customer at the restaurant

select s.cust_id, sum(m.price) as total_amount
from sales as s
inner join
menu as m on s.menu_id = m.menu_id
group by s.cust_id

-- set @v = '$';

select s.cust_id, mm.cust_name, concat('$',sum(m.price)) as total_amount
from sales as s
inner join
menu as m on s.menu_id = m.menu_id
inner join
members as mm on s.cust_id = mm.cust_id
group by s.cust_id , mm.cust_name

-- 2. how many days customer visited the restaurant

select cust_id, COUNT(DISTINCT order_date) as visited_days
from sales group by cust_id;

-- 3. first item purchased by the customer

 -- select *, row_number() over(partition by s.cust_id order by s.order_date) as rnk
 -- from sales s
 -- inner join menu m on s.menu_id = m.menu_id

WITH purchase_by_cust AS (
  SELECT 
    s.cust_id,
    m.menu_name,
    m.price,
    s.order_date,
    ROW_NUMBER() OVER (PARTITION BY s.cust_id ORDER BY s.order_date) AS rnk
  FROM sales s
  INNER JOIN menu m ON s.menu_id = m.menu_id
)
SELECT cust_id, menu_name , price
FROM purchase_by_cust 
WHERE rnk = 1;

-- which item is most popular for each customer 

WITH popular_item_by_cust AS (
  SELECT 
    s.cust_id,
    m.menu_name,
    count(*) as no_of_times_ordered,
    dense_rank() OVER (PARTITION BY s.cust_id ORDER BY count(*) desc) AS rnk
  FROM sales s
  INNER JOIN menu m ON s.menu_id = m.menu_id
  group by s.cust_id, m.menu_name
)
SELECT cust_id, menu_name , no_of_times_ordered
FROM popular_item_by_cust 
WHERE rnk = 1;

-- most purchased item on the menu and how many times it was purchased by customers

with popular_menuitem as 
(
select m.menu_name, count(*) as purchase_count, DENSE_RANK() over (order by count(*) desc) as rnk
from sales s inner join menu m on s.menu_id = m.menu_id
group by m.menu_name
)
select menu_name, purchase_count from  popular_menuitem where rnk = 1;

-- which item was purchased first by the customer after they became member

with cte as 
(
 select s.cust_id,m.cust_name,mm.menu_name, DENSE_RANK() over (partition by s.cust_id order by s.order_date) as rnk 
 from sales s
 inner join members m on s.cust_id = m.cust_id
 inner join menu mm on s.menu_id = mm.menu_id
 where s.order_date >= m.join_date
)
select cust_name,menu_name from cte where rnk =1;

-- select * from members;

-- select * from sales where cust_id = 'C001' order by order_date;

-- update sales set order_date = '2023-01-09' where order_date = '2023-01-11' and menu_id = 1 ; 

-- what is the total items and amount spent for each member before and after they became member

with beforemem as
(
select s.cust_id, count(*) as total_items, sum(mm.price) as amount from sales s
inner join members m on s.cust_id = m.cust_id
inner join menu mm on s.menu_id = mm.menu_id
where s.order_date < m.join_date or m.join_date is null
group by s.cust_id
),
aftermem as
(
select s.cust_id, count(*) as total_items, sum(mm.price) as amount from sales s
inner join members m on s.cust_id = m.cust_id
inner join menu mm on s.menu_id = mm.menu_id
where s.order_date >= m.join_date
group by s.cust_id
)

SELECT 
    case
    when b.cust_id is not null then b.cust_id
    else a.cust_id
    end as cust_id,
    b.total_items AS total_items_before,
    b.amount AS amount_before,
    a.total_items AS total_items_after,
    a.amount AS amount_after
    from beforemem b full outer join aftermem a on b.cust_id = a.cust_id;


--Q. region wise sales
--Q. region wise highest item purchased with count

use restaurant;

with regionwise as
(
 select m.region ,x.menu_name,s.menu_id, count(s.menu_id) as puchase_count,
 DENSE_RANK() over (partition by m.region order by count(s.menu_id) desc) as rnk
 from members m inner join sales s on m.cust_id = s.cust_id
 inner join menu x on s.menu_id = x.menu_id
 group by  m.region ,x.menu_name,s.menu_id
)
select * from regionwise where rnk =1;

-- select * from regionwise where menu_id = 7;

-- select menu_id, count(menu_id) from sales where menu_id = 7 group by menu_id;

--Q. region wise top customer

with regionwisecust as
(
 select m.region ,m.cust_name, sum(x.price) as purchase_amt, count(s.cust_id) as puchase_count,
 DENSE_RANK() over (partition by m.region order by sum(x.price) desc) as rnk
 from members m inner join sales s on m.cust_id = s.cust_id
 inner join menu x on s.menu_id = x.menu_id
 group by  m.region ,m.cust_name
)
select * from regionwisecust where rnk =1;

-- region wise veg/ non veg consumption

-- revenue veg/ non veg consumption wise

-- lets say each dollar spent have 10 points and if Steak or Pizza 15 points for each dollar
-- how many points each customer have (before membership)

select * from menu;

with cte as
(
 select s.cust_id,m.cust_name, s.order_date, m.join_date, DATEDIFF(DAY,s.order_date, m.join_date) as date_diff, mm.menu_name, mm.price
 from sales s inner join members m on s.cust_id = m.cust_id
 inner join menu mm on s.menu_id = mm.menu_id
 where s.order_date < m.join_date
),
-- select * from cte where cust_name = 'Ben Lee';
ctebefore as(
 select cust_id,cust_name, sum(price) as total_amt_spent,
 sum (case when menu_name in ('Steak','Pizza') then price *15
      else price *10
      end) as points
 from cte group by cust_id,cust_name
)
select * from ctebefore;



-- after membership each dollar 20 points for first 3 months, after it is same as before membership logic, calculate how many points each customer have (after membership)

with cte2 as
(
 select s.cust_id,m.cust_name, s.order_date, m.join_date, DATEDIFF(DAY, m.join_date, s.order_date) as date_diff, mm.menu_name, mm.price
 from sales s inner join members m on s.cust_id = m.cust_id
 inner join menu mm on s.menu_id = mm.menu_id
 where s.order_date >= m.join_date
),
-- select * from cte2 where  cust_name='Yara Hall';
cteafter as (
select cust_id,cust_name, sum(price) as total_amt_spent,
sum (case when date_diff <= 90 then price * 20
     else
         case when menu_name in ('Steak','Pizza') then price *15
         else price *10
         end
     end) as points
from cte2 group by cust_id,cust_name)
select * from cteafter; 


-- combined points for each customer 

with cte as
(
 select s.cust_id,m.cust_name, s.order_date, m.join_date, DATEDIFF(DAY,s.order_date, m.join_date) as date_diff, mm.menu_name, mm.price
 from sales s inner join members m on s.cust_id = m.cust_id
 inner join menu mm on s.menu_id = mm.menu_id
 where s.order_date < m.join_date
),
-- select * from cte where cust_name = 'Ben Lee';
ctebefore as(
 select cust_id,cust_name, sum(price) as total_amt_spent,
 sum (case when menu_name in ('Steak','Pizza') then price *15
      else price *10
      end) as points
 from cte group by cust_id,cust_name
),
cte2 as
(
 select s.cust_id,m.cust_name, s.order_date, m.join_date, DATEDIFF(DAY, m.join_date, s.order_date) as date_diff, mm.menu_name, mm.price
 from sales s inner join members m on s.cust_id = m.cust_id
 inner join menu mm on s.menu_id = mm.menu_id
 where s.order_date >= m.join_date
),
-- select * from cte2 where  cust_name='Yara Hall';
cteafter as (
select cust_id,cust_name, sum(price) as total_amt_spent,
sum (case when date_diff <= 90 then price * 20
     else
         case when menu_name in ('Steak','Pizza') then price *15
         else price *10
         end
     end) as points
from cte2 group by cust_id,cust_name)
select a.cust_id,a.cust_name,a.points as before_points , b.points as after_points, (a.points + b.points) as total_points
from ctebefore a inner join cteafter b on a.cust_id = b.cust_id;


-- coupons for members(after join) for combo products of menu_id like (2,6) (4,9) (5,10) ordered on same date only

with ctecoupon as
(
 select s.cust_id,m.cust_name, s.order_date, s.menu_id
 from sales s inner join members m on s.cust_id = m.cust_id
 inner join menu mm on s.menu_id = mm.menu_id
 where s.order_date >= m.join_date
)
-- select * from ctecoupon;
-- select cust_name, order_date , 
-- count(*) as order_count
-- from ctecoupon where menu_id in (2,6,4,9,5,10) group by cust_name, order_date ;

select cust_name, order_date , 
count( case when menu_id in (2,6) then 1
            when menu_id in (4,9) then 1
            when menu_id in (5,10) then 1
            else 0
            end
      ) as coupon_count
from ctecoupon group by cust_name, order_date;
       


-- join all tables
-- ranking of the tables
-- interval wise sales analytics

WITH ctecoupon AS (
    SELECT 
        s.cust_id,
        m.cust_name, 
        s.order_date, 
        s.menu_id
    FROM sales s 
    INNER JOIN members m ON s.cust_id = m.cust_id
    INNER JOIN menu mm ON s.menu_id = mm.menu_id
    WHERE s.order_date >= m.join_date
),
grouped_orders AS (
    SELECT 
        cust_name,
        order_date,
        -- Aggregate menu_ids into a string or use conditional logic
        SUM(CASE WHEN menu_id = 2 THEN 1 ELSE 0 END) AS has_2,
        SUM(CASE WHEN menu_id = 6 THEN 1 ELSE 0 END) AS has_6,
        SUM(CASE WHEN menu_id = 4 THEN 1 ELSE 0 END) AS has_4,
        SUM(CASE WHEN menu_id = 9 THEN 1 ELSE 0 END) AS has_9,
        SUM(CASE WHEN menu_id = 5 THEN 1 ELSE 0 END) AS has_5,
        SUM(CASE WHEN menu_id = 10 THEN 1 ELSE 0 END) AS has_10
    FROM ctecoupon
    WHERE menu_id IN (2, 6, 4, 9, 5, 10)
    GROUP BY cust_name, order_date
)

SELECT 
    cust_name, 
    order_date,
    CASE 
        WHEN has_2 > 0 AND has_6 > 0 THEN 'YES'
        WHEN has_4 > 0 AND has_9 > 0 THEN 'YES'
        WHEN has_5 > 0 AND has_10 > 0 THEN 'YES'
        ELSE 'NO'
    END AS coupon_eligible
FROM grouped_orders
WHERE 
    (has_2 > 0 AND has_6 > 0) OR 
    (has_4 > 0 AND has_9 > 0) OR 
    (has_5 > 0 AND has_10 > 0);

