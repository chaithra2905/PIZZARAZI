create database pizzarazzi
use pizzarazzi

alter table pizza_types 
alter column ingredients nvarchar(max)

EXEC sp_help pizza_types;

ALTER TABLE order_details
ALTER COLUMN [quantity] INT;

ALTER TABLE pizzas
ALTER COLUMN [price] FLOAT;

Select * from pizza_types;
Select * from order_details
Select * from orders

--Retrieve the total number of orders placed.
Select count(order_id) as total_orders from orders;

--Calculate the total revenue generated from pizza sales

Select round(sum(od.quantity*p.price),2) as total_revenue from order_details od 
join pizzas p
on od.pizza_id=p.pizza_id

--Identify the highest-priced pizza.

Select pt.name as highest_priced_pizzas, p.price from pizza_types pt
join pizzas p
on pt.pizza_type_id=p.pizza_type_id
where p.price=(Select MAX(price) from pizzas)

--Identify the most common pizza size ordered.
Select top 1 p.size, count(o.order_details_id) as order_count
from pizzas p join order_details o
on p.pizza_id=o.pizza_id
group by p.size
order by order_count desc

--List the top 5 most ordered pizza types along with their quantities.

Select top 5 pt.name, sum(od.quantity) as quantity from order_details od
join pizzas p on od.pizza_id = p.pizza_id
join pizza_types pt
on pt.pizza_type_id = p.pizza_type_id
group by pt.name
order by quantity desc


--Join the necessary tables to find the total quantity of each pizza category ordered.

Select top 5 pt.category, sum(od.quantity) as quantity from order_details od
join pizzas p on od.pizza_id = p.pizza_id
join pizza_types pt
on pt.pizza_type_id = p.pizza_type_id
group by pt.category
order by quantity desc

--Determine the distribution of orders by hour of the day.

SELECT DATEPART(HOUR, time) as hour_of_day, count(order_id) as order_count 
FROM orders
group by DATEPART(HOUR, time)
order by order_count desc

--Find the category-wise distribution of pizzas.

Select category, count(name) as category_count from pizza_types
group by category

--Group the orders by date and calculate the average number of pizzas ordered per day.

Select avg(order_quantity) as avg_no_orders_per_day
from
(
Select o.date as dates, sum(od.quantity) as order_quantity from orders o
join order_details od
on o.order_id = od.order_id
group by o.date
) as order_quantity

--Determine the top 3 most ordered pizza types based on revenue.

Select top 3 pt.name, round(sum(od.quantity*p.price),2) as total_revenue from order_details od 
join pizzas p
on od.pizza_id=p.pizza_id
join pizza_types pt
on p.pizza_type_id=pt.pizza_type_id
group by pt.name
order by total_revenue desc

--Calculate the percentage contribution of each pizza type to total revenue.

Select pt.category, round(sum(od.quantity*p.price) / total_sales.total*100,2) as percentage_of_total_sales
from 
order_details od 
join pizzas p
on od.pizza_id=p.pizza_id
join pizza_types pt
on p.pizza_type_id=pt.pizza_type_id
cross join (
Select round(sum(od.quantity * p.price),2) as total
from order_details od join pizzas p
on od.pizza_id = p.pizza_id) total_sales
group by pt.category, total_sales.total
order by percentage_of_total_sales desc

--Analyze the cumulative revenue generated over time.
Select date, sum(revenue) over (order by date) as cum_revenue
from
(Select o.date, sum(od.quantity * p.price) as revenue
from order_details od join pizzas p
on od.pizza_id=p.pizza_id
join orders o
on o.order_id = od.order_id
group by o.date) as sales 


--Determine the top 3 most ordered pizza types based on revenue for each pizza category.

Select category, name, revenue
from
(Select category, name, revenue, rank() over (partition by category order by revenue desc) as rn
from
(Select pt.name, pt.category , sum(od.quantity *p.price) as revenue from pizza_types pt
join pizzas p on 
pt.pizza_type_id = p.pizza_type_id
join order_details od
on p.pizza_id =od.pizza_id
group by pt.category, pt.name) as a) as b
where rn<=3