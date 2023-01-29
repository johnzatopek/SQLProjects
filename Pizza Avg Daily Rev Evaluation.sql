/*Join tables to view when pizzas were ordered, what types of pizza, and the cost of each pizza ordered
Need to round pizza price because decimal values go past $xx.xx */
WITH orders_by_hour AS (
SELECT o.order_id, date, DATETRUNC(hour,time) AS hour_ordered, p.pizza_id, ROUND(p.price,2) AS price_two_decimals
FROM orders AS o
LEFT JOIN order_details AS od
ON o.order_id = od.order_id
LEFT JOIN pizzas AS p
ON od.pizza_id = p.pizza_id),

--CTE returning revenue per day for every day of sales
revenue_per_day AS (
SELECT date, SUM(price_two_decimals) AS revenue_per_day
FROM orders_by_hour
GROUP BY date
)
--Table returning revenue per day, ordered by day and avg daily revenue
SELECT *, 
	ROUND(AVG(revenue_per_day) OVER (ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),2) AS avg_daily_rev
FROM revenue_per_day
ORDER BY date

--Table returning only dates with a higher than avg daily revenue
SELECT date, revenue_per_day, 
	(SELECT ROUND(AVG(revenue_per_day),2)
	FROM revenue_per_day) AS avg_daily_revenue				
FROM revenue_per_day
WHERE revenue_per_day >= (
	SELECT AVG(revenue_per_day)
	FROM revenue_per_day)
ORDER BY date;
