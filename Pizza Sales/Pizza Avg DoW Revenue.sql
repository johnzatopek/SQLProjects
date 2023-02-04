/*Join tables to view when pizzas were ordered, what types of pizza, and the cost of each pizza ordered
Need to round pizza price because decimal values go past $xx.xx */
WITH orders_by_hour AS (
SELECT o.order_id, od.quantity, date, DATENAME(WEEKDAY, date) AS dow, DATETRUNC(hour,time) AS hour_ordered, p.pizza_id, ROUND(p.price,2) AS price_two_decimals
FROM orders AS o
LEFT JOIN order_details AS od
ON o.order_id = od.order_id
LEFT JOIN pizzas AS p
ON od.pizza_id = p.pizza_id),

--CTE returning revenue per day for every day of sales
revenue_per_day AS (
SELECT dow, SUM(price_two_decimals*quantity) AS revenue_per_day, COUNT(DISTINCT date) AS days_open
FROM orders_by_hour
GROUP BY dow
)

/*Query displaying total revenue made on each day of the week, how many days open, and avg revenue for each day.
The most profitable day of the week is Friday, followed by Thursday and Saturday. 
The least profitable day of the week is Sunday.*/
SELECT *, ROUND(revenue_per_day/days_open, 2) AS avg_dow_rev
FROM revenue_per_day
ORDER BY avg_dow_rev DESC;
