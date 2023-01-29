/*Join tables to view when pizzas were ordered, types of pizza, and the cost of each pizza ordered
Need to round pizza price because decimal values go past $xx.xx */
WITH orders_by_hour AS (
SELECT o.order_id, date, DATETRUNC(hour,time) AS hour_ordered, p.pizza_id, ROUND(p.price,2) AS price_two_decimals
FROM orders AS o
LEFT JOIN order_details AS od
ON o.order_id = od.order_id
LEFT JOIN pizzas AS p
ON od.pizza_id = p.pizza_id),

--CTE returning revenue per hour
total_rev_each_hour AS (
SELECT date, hour_ordered, SUM(price_two_decimals) AS rev_on_day_in_hour, 
	COUNT(DISTINCT order_id) AS num_of_orders
FROM orders_by_hour
GROUP BY date, hour_ordered
)

/*Query outputs the avg hourly revenue throughout the year. 
I suspect purchases made in hours 9 and 10 were purchases made for pickup later in the day.
To save on operating costs, the store may want consider closing at 23:00. */
SELECT hour_ordered, ROUND(AVG(rev_on_day_in_hour),2) AS avg_hourly_rev, SUM(num_of_orders) AS total_orders_in_hour
FROM total_rev_each_hour
GROUP BY hour_ordered
ORDER BY hour_ordered

/*Query displays the orders that took place in hours with less than 25 purchases over the year
The only date with a 9am sale was 2015-11-24.  I suspect this was a large purchae made for pickup later in the day, 
especially considering this was 2 days before Thanksgiving.*/
SELECT date, hour_ordered, SUM(price_two_decimals) AS purchase_cost,
	SUM(SUM(price_two_decimals)) OVER (PARTITION BY hour_ordered) AS total_hour_revenue_for_year
FROM orders_by_hour
WHERE hour_ordered IN (
	SELECT hour_ordered
	FROM orders_by_hour
	GROUP BY hour_ordered
	HAVING COUNT(DISTINCT order_id)<25)
GROUP BY date, hour_ordered
ORDER BY date, hour_ordered;