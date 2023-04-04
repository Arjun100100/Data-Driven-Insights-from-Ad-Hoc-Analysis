use projects;

select * from website_orders
limit 2;

ALTER TABLE website_orders ADD COLUMN order_datetime DATETIME;
UPDATE website_orders SET order_datetime = STR_TO_DATE(order_date, '%d-%m-%Y %H:%i');
ALTER TABLE website_orders DROP COLUMN order_date;

ALTER TABLE website_orders ADD COLUMN ship_datetime DATETIME;
UPDATE website_orders SET ship_datetime = STR_TO_DATE(ship_date, '%d-%m-%Y %H:%i');

ALTER TABLE website_orders ADD COLUMN Year Year;
UPDATE website_orders SET Year = Year(order_datetime);


ALTER TABLE website_orders DROP COLUMN ship_date;

/* Adhoc 1. What is the average time it takes to ship an order based on the different ship modes available?*/

select ship_mode,
round(avg(datediff(ship_datetime,order_datetime)),2) as Avg_ship_days
from website_orders
group by 1;

/* We have some difference in same day ship also, which is a sign that shipping was inefficient for some orders, lets find  more about these orders*/

select country,
segment,
count(*)
from website_orders
where datediff(ship_datetime,order_datetime)>0 and
ship_mode='same day'
group by 1,2
order by 1;

/* Adhoc 2. Are there any product sub-categories that are more likely to have discounted sales?*/
/* High discount sales can be identified by high average discount*/

SELECT Sub_Category, round(AVG(Discount),2) as Avg_Discount, round(AVG(Sales),2) as Avg_Sales
FROM website_orders
GROUP BY Sub_Category
ORDER BY Avg_Discount DESC;

/* Adhoc 3. Which customer segments are the most profitable and which ones are the least profitable?*/

/*We have the shipping cost and sales to calculate, discount will not deducted from sales as sales the result of price - discount, 
so the basic profit will be sales-shipping cost */


SELECT 
  w.Segment, 
  ROUND(SUM(CASE WHEN odr.Order_ID IS NULL THEN w.Sales ELSE 0 END) - SUM(w.Shipping_Cost), 0) AS Profit
FROM 
  website_orders AS w
LEFT JOIN 
  order_returned AS odr ON w.Order_ID = odr.Order_ID
GROUP BY 
  w.Segment
ORDER BY 
  Profit DESC;


/* Adhoc 4. Are there any customer name that are more likely to place high-sales orders than others?*/

select customer_name,
count(order_id) as num_orders,
round(avg(sales),0) as avg_sales_incurred
from website_orders
group by 1
order by 3 desc
limit 10;

/* Adhoc 5. Which countries have the highest customer retention rates percentage based on repeat orders?*/

with tt as (select country,
customer_id,
count(distinct order_id) as num_orders
from website_orders
group by 1,2)

select country,
round(100.0*count(distinct case when num_orders>2 then customer_id end)/count(distinct customer_id),2) as 'retention_rate%'
from tt
group by 1
order by 2 desc
limit 5;


/* Adhoc 6. Are there any correlations between the order priority and the shipping mode used? */

select Order_Priority, 
ship_mode,
count(order_id)
from website_orders
group by 1,2;

SELECT Order_Priority,
count(case when ship_mode='Standard Class' then  order_id else null end) as Standard_Class,
count(case when ship_mode='Second Class' then  order_id else null end) as Second_Class,
count(case when ship_mode='First Class' then  order_id else null end) as First_Class,
count(case when ship_mode='Same Day' then  order_id else null end) as Same_Day
from website_orders
group by 1;

/* Adhoc 7. Which sub-categories have the highest number of returns? */

select a.sub_category,
count(*) as num_returns
from website_orders as a
join order_returned as b
on a.order_id=b.order_id
group by 1
order by 2 desc;

/* Adhoc 8. Which customer segment is most likely to return items, and which ones are least likely?*/

select a.segment,
count(*) as num_returns
from website_orders as a
join order_returned as b
on a.order_id=b.order_id
group by 1
order by 2 desc;

select segment, 
num_returns
from (select a.segment,
count(*) as num_returns
from website_orders as a
join order_returned as b
on a.order_id=b.order_id
group by 1
order by 2 desc
limit 1) as most_likely
union all
select segment, 
num_returns
from (select a.segment,
count(*) as num_returns
from website_orders as a
join order_returned as b
on a.order_id=b.order_id
group by 1
order by 2 asc
limit 1) as least_likely;

/* Adhoc 9. What is the sales trend for each product category over time?*/

select year,
category,
round(sum(sales),0) as Total_sales
from website_orders as w
left join order_returned as odr
ON w.order_id = odr.order_id
WHERE odr.order_id IS NULL
group by 2,1;


/* Adhoc 10. How has the  sales and profit in each  market changed over the years?*/

select year(order_datetime) as Years,
market,
ROUND(SUM(CASE WHEN odr.Order_ID IS NULL THEN w.Sales ELSE 0 END)) as total_sales,
ROUND(SUM(CASE WHEN odr.Order_ID IS NULL THEN w.Sales ELSE 0 END) - SUM(w.Shipping_Cost), 0) AS Profit
FROM 
  website_orders AS w
LEFT JOIN 
  order_returned AS odr ON w.Order_ID = odr.Order_ID
group by 1,2
order by 1;


