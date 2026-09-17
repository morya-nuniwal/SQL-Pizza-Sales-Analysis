create database pizzahut;

create table orders(
order_id int not null,
order_date date not null,
order_time time not null,
primary key(order_id));



create table orders_details (
order_details_id int not null,
order_id int not null,
pizza_id text not null,
quantity int not null,
primary key(order_details_id));


-- Retrieve the total number of orders placed.

select count(order_id) as total_orders from orders;


-- Calculate the total revenue generated from pizza sales. 

select
round(sum(orders_details.quantity * pizzas.price), 2) as total_sales
from orders_details join pizzas
on pizzas.pizza_id = orders_details.pizza_id;


-- Identify the highest-priced pizza.

select pizza_types_fixed.name, pizzas.price
from pizza_types_fixed join pizzas
on pizza_types_fixed.pizza_type_id = pizzas.pizza_type_id
order by pizzas.price desc limit 1;

-- Identify the most common pizza size ordered.

SELECT 
    pizzas.size,
    COUNT(orders_details.order_details_id) AS order_count
FROM
    pizzas
        JOIN
    orders_details ON pizzas.pizza_id = orders_details.pizza_id
GROUP BY pizzas.size
ORDER BY order_count DESC;


-- List the top 5 most ordered pizza types along with their quantities.

SELECT 
    pizza_types_fixed.name,
    SUM(orders_details.quantity) AS quantity
FROM
    pizza_types_fixed
        JOIN
    pizzas ON pizza_types_fixed.pizza_type_id = pizzas.pizza_type_id
        JOIN
    orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types_fixed.name
ORDER BY quantity DESC
LIMIT 5;


-- Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT 
    pizza_types_fixed.category,
    SUM(orders_details.quantity) AS quantity
FROM
    pizza_types_fixed
        JOIN
    pizzas ON pizza_types_fixed.pizza_type_id = pizzas.pizza_type_id
        JOIN
    orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types_fixed.category
ORDER BY quantity DESC;


-- Determine the distribution of orders by hour of the day.

SELECT 
    HOUR(order_time) AS hour, COUNT(order_id) AS order_count
FROM
    orders
GROUP BY HOUR(order_time);


-- Join relevant tables to find the category-wise distribution of pizzas.

SELECT 
    category, COUNT(name)
FROM
    pizza_types_fixed
GROUP BY category;


-- Group the orders by date and calculate the average number of pizzas ordered per day.

SELECT 
    AVG(quantity)
FROM
    (SELECT 
        orders.order_date, SUM(orders_details.quantity) AS quantity
    FROM
        orders
    JOIN orders_details ON orders.order_id = orders_details.order_id
    GROUP BY orders.order_date) AS order_quantity;
    
    
    -- Determine the top 3 most ordered pizza types based on revenue.

SELECT 
    pizza_types_fixed.name,
    SUM(orders_details.quantity * pizzas.price) AS revenue
FROM
    pizza_types_fixed
        JOIN
    pizzas ON pizzas.pizza_type_id = pizza_types_fixed.pizza_type_id
        JOIN
    orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types_fixed.name
ORDER BY revenue DESC
LIMIT 3;



-- Calculate the percentage contribution of each pizza type to total revenue.
SELECT 
    pizza_types_fixed.category,
    ROUND(
        SUM(orders_details.quantity * pizzas.price) /
        (
            SELECT SUM(orders_details.quantity * pizzas.price)
            FROM orders_details
            JOIN pizzas 
                ON pizzas.pizza_id = orders_details.pizza_id
        ) * 100,
        2
    ) AS percentage_contribution
FROM orders_details
JOIN pizzas 
    ON pizzas.pizza_id = orders_details.pizza_id
JOIN pizza_types_fixed 
    ON pizza_types_fixed.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types_fixed.category
ORDER BY percentage_contribution DESC;



--  Analyze the cumulative revenue generated over time.

select order_date,
sum(revenue) over(order by order_date) as cum_revenue
from
(select orders.order_date,
sum(orders_details.quantity * pizzas.price) as revenue
from orders_details join pizzas
on orders_details.pizza_id = pizzas.pizza_id
join orders
on orders.order_id = orders_details.order_id
group by orders.order_date) as sales;



-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.

SELECT name, revenue
FROM (
    SELECT 
        category,
        name,
        revenue,
        RANK() OVER (
            PARTITION BY category 
            ORDER BY revenue DESC
        ) AS rn
    FROM (
        SELECT 
            pizza_types_fixed.category,
            pizza_types_fixed.name,
            SUM(orders_details.quantity * pizzas.price) AS revenue
        FROM pizza_types_fixed
        JOIN pizzas 
            ON pizza_types_fixed.pizza_type_id = pizzas.pizza_type_id
        JOIN orders_details
            ON orders_details.pizza_id = pizzas.pizza_id
        GROUP BY 
            pizza_types_fixed.category,
            pizza_types_fixed.name
    ) AS a
) AS b
WHERE rn <= 3;