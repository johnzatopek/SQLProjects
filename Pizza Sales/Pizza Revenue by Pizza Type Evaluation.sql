/*Join tables to view when pizzas were ordered, what types of pizza, and the cost of each pizza ordered
Need to round pizza price because decimal values go past $xx.xx */

WITH joined_pizza_table AS (
SELECT o.order_id, date, DATETRUNC(hour,time) AS hour_ordered, p.pizza_id, pt.pizza_type_id, ROUND(p.price,2) AS price_two_decimals, pt.category
FROM orders AS o
LEFT JOIN order_details AS od
ON o.order_id = od.order_id
LEFT JOIN pizzas AS p
ON od.pizza_id = p.pizza_id
LEFT JOIN pizza_types AS pt
ON p.pizza_type_id = pt.pizza_type_id)

/*Query to discover the best selling pizzas.
We discover the most popular pizzas are: thai_ckn, bbq_ckn, and cali_ckn. The least popular are most vegetarian options.
*/
SELECT pizza_type_id, ROUND(SUM(price_two_decimals),2) AS pizza_type_rev
FROM joined_pizza_table
GROUP BY pizza_type_id
ORDER BY pizza_type_rev DESC

/*Query to discover the best selling categories of pizza, number of pizzas in each category, and average revenue per pizza.
From this query, we can gather that while ckn may have the 3 most popular individual pizzas, classic pizzas are the best seller overall
We can again confirm that veggie pizzas are the least popular
Chicken has the highest revenue per pizza since there are only 6 chicken pizzas*/
SELECT category, ROUND(SUM(price_two_decimals),2) AS category_rev, COUNT(DISTINCT pizza_type_id) AS num_in_category,
ROUND(SUM(price_two_decimals)/COUNT(DISTINCT pizza_type_id),2) AS average_rev_per_pizza
FROM joined_pizza_table
GROUP BY category
ORDER BY category_rev DESC

-- From this data, I suggest conducting seasonal promotions with new types of chicken pizza to help drive profits.