/*
---------------------------------
Advanced Analaytics
-------------------------------
Purpose:
To understand advanced analytics processes and quearies: 
->Change over time
->Cumilative Analysis
->Performance Analysis
->Part to Whole Analysis
->Data Segmentation
->Reporting:
  ->For Customers Table
  ->For Products Table
------------------------------------------------------------------
*/

/*
------------------------
Change-Over-Time
------------------------
-> Analysis of a measure over time.
-> Helps track trends and identify seasonality in the data. 
-> [Measure] By [Date Dimension]
->eg:  Total Sales by Year, Average cost By Month 

-> Usualy FACT table is used. 
*/

--Task: Find sales, customer and quantities changes over time

SELECT 
	DATETRUNC(MONTH, order_date) AS order_date,
	SUM(sales_amount) AS total_sales, 	
	COUNT(DISTINCT customer_key) AS customers,
	SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH, order_date) 
ORDER BY DATETRUNC(MONTH, order_date) 

/*
------------------------
Cumilative Analysis
------------------------
-> Aggregate the data progressively over time. 
-> Helps to understand wheather our business is growing or declining. 
-> [Cumilative measure] by [date dimension]

-> We use aggregate window functions 
*/

--Find running total sales 
SELECT 
	order_date,
	total_sales,
	SUM(total_sales) OVER(PARTITION BY order_date ORDER BY order_date ASC) AS running_total_sales 
FROM(
SELECT 
	DATETRUNC(YEAR,order_date) AS order_date,
	SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(YEAR,order_date)
)t

--Finding moving average of price
SELECT 
	order_date,
	total_sales,
	SUM(total_sales) OVER(ORDER BY order_date ASC) AS running_total_sales,
	AVG(avg_price) OVER(ORDER BY order_date ASC) AS moving_average_price
FROM(
SELECT 
	DATETRUNC(YEAR,order_date) AS order_date,
	SUM(sales_amount) AS total_sales,
	AVG(price) as avg_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(YEAR,order_date)
)t

/*
------------------------
Performance Analysis
------------------------
->Comparing Current value to target value
-> Helps measure success and compare performance. 
-> [Current Measure] - [Trget Measure] 
eg: Current sales - svg sales 
	Current sales - previous year sales 
	current sales - lowest sales
->Lead and lag window functions 
*/

--Task:  Analyze yearly performance of products 
--By comparing product's sales to both its avg sales performance 
-- and previous years's sales

WITH yearly_product_sales AS 
(
    SELECT 
        DATETRUNC(YEAR, f.order_date) AS order_year, 
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON p.product_key = f.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY DATETRUNC(YEAR, f.order_date), p.product_name
)
SELECT 
	order_year,
	product_name,
	current_sales,
	AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
	current_sales - AVG(current_sales) OVER(PARTITION BY product_name) AS diff_avg,
	CASE 
		WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Avg'
		WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Avg'
		ELSE 'Avg'
	END AS avg_change,
	LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year ASC) as previous_year_sales,
	current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year ASC) AS diff_per_year,
	CASE 
		WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year ASC) > 0 THEN 'Increase'
		WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year ASC) < 0 THEN 'Decrease'
		ELSE 'Same'
	END AS difference_in_sales_per_year
FROM yearly_product_sales
ORDER BY product_name, order_year


/*
-----------------------------------
Part to whole Proportional Analysis
-----------------------------------
-> Analyze how an individual part is performing as compared to the overall, 
-> allowing us to understand which category has greatest impact on the business. 
-> ([measure] /[total_measure]) * 100 by [Dimension]
-> eg: (sales/total sales) * 100 by category
->		(quantity / total quantity) *100 by country
*/

--Task: Which categories contibute most to overall sales.
WITH category_sales AS(
	SELECT 
		p.category_name,
		SUM(f.sales_amount) AS total_sales
	FROM gold.fact_sales AS f
	LEFT JOIN gold.dim_products AS p
	ON p.product_key = f.product_key
	GROUP BY p.category_name
)

SELECT 
	category_name,
	total_sales,
	SUM(total_sales) OVER() AS overall_sales,
	CONCAT(ROUND((CAST(total_sales AS FLOAT)/SUM(total_sales) OVER()) * 100,2), '%') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC


/*
------------------
Data Segmentation
------------------
-> Group the data based on a specific range. 
-> Helps understand the correaltion between 2 measures. 

-> [Measure] by [Measure]
->eg: Total Products By sales range
->	 Total customers by age.
*/

--Task: Segment products into cost ranges; count how many products fall into each segment
WITH product_segements AS(
	SELECT 
		product_key,
		product_name,
		cost,
		CASE 
			WHEN cost < 100 THEN 'Below 100'
			WHEN cost BETWEEN 100 AND 500 THEN '100-500'
			WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
			ELSE 'above 1000'
		END AS cost_range
	FROM gold.dim_products 
)

SELECT 
cost_range,
COUNT(product_key) AS total_products
FROM product_segements
GROUP BY cost_range
ORDER BY COUNT(product_key) DESC

/* 
Task 2: 
-> Group Customers into 3 segments based on their spending behaviour: 
-> VIP: Customers with atleast 12 months of history and spending more than 5000.
-> Regular: Customers with atleast 12 months of history but spending 5000 or less. 
-> New: Customers with lifespan lesser than 12 months. 
-> Also find the total number of customers in each group. 
*/
WITH customer_spending AS
(
SELECT 
	c.customer_key,
	SUM(f.sales_amount) AS total_spending,
	Min(f.order_date) AS first_order_date,
	MAX(f.order_date) AS last_order_date,
	DATEDIFF(MONTH, Min(f.order_date),MAX(f.order_date)) AS life_span
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key
)
SELECT 
customer_segment,
COUNT(customer_key) AS total_customers
FROM (
	SELECT 
		customer_key,
		total_spending,
		life_span,
		CASE 
			WHEN life_span > = 12 AND total_spending > 5000 THEN 'VIP'
			WHEN life_span > = 12 AND total_spending <= 5000 THEN 'Regular'
			ELSE 'New'
		END AS customer_segment
	FROM customer_spending
	)t
GROUP BY customer_segment
ORDER BY total_customers DESC

/*
------------------
Reporting
------------------

Purpose: This report consolidates key customer metrics and behaviors

Highlight: 
1. Gathers essential feilds such as names, ages and transaction details. 
2. Segments customers into categories(VIP, Regular, New) and age groups. 
3. Aggregates customer level metrics:
	-> Total Orders
	-> Total sales
	-> Total quantity purchased
	-> Total Products
	-> Lifespan (in months)
4. Calculates valuable KPIs:
	- Recency (Months since last order)
	- Avg order value
	- Avg monthly spend

*/


--Create View of table;
CREATE VIEW gold.report_customers AS
--1)Base Query: Retrieves Core Columns from tables
WITH base_query AS
(
SELECT 
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amount,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ' , c.last_name) AS customer_name,
	DATEDIFF(Year, c.birthdate, GETDATE()) AS age
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL
)
,
--Table 2): Customer Aggregation(Intermmediate)
customer_aggregation AS
(
SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan 
FROM base_query
GROUP BY customer_key, customer_number, customer_name, age
)
--Table 3): Final Transformations for Customer Table
SELECT
	customer_key, 
	customer_number, 
	customer_name, 
	age,
	CASE 
		WHEN age < '20' THEN 'Under 20'
		WHEN age BETWEEN 20 and 29 THEN '20-29'
		WHEN age BETWEEN 30 and 39 THEN '30-39'
		WHEN age BETWEEN 40 and 49 THEN '40-49'
		ELSE 'Above 50'
	END AS age_group,
	CASE 
		WHEN lifespan > = 12 AND total_sales > 5000 THEN 'VIP'
		WHEN lifespan > = 12 AND total_sales <= 5000 THEN 'Regular'
		ELSE 'New'
	END AS customer_segment,
	total_orders,
	total_sales,
	--KPI 2
	CASE WHEN total_orders = 0 THEN 0
		 ELSE total_sales/total_orders
	END AS avg_order_value,
	total_quantity,
	total_products,
	last_order,
	--KPI 1
	DATEDIFF(MONTH, last_order, GETDATE()) AS recency,
	lifespan,
	--KPI 3
	CASE WHEN lifespan = 0 THEN total_sales
		 ELSE total_sales/lifespan 
	END AS avg_monthly_spend
FROM customer_aggregation




/*Highlights:
1. Gather Essential Fields such as product name, category, subcategory and cost
2. Segments products by revenue to identity high performers, mid range or low performers
3. Aggregate product level metrics: 
	- total orders
	- total sales
	- total quantity sold
	- total customers(unique)
	- lifespan(in months)
4. Calculate valuable KPIs: 
	- Recency (Months since last sale)
	- Avg. order revenue (AOR)
	- Avg monthly revenue
	*/
CREATE VIEW gold.report_products AS
WITH products_base
AS
(
SELECT
	p.product_key,
	f.order_date,
	f.order_number,
	f.sales_amount,
	f.quantity,
	p.product_name,
	p.category_name,
	p.sub_category,
	p.cost,
	f.customer_key
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON p.product_key = f.product_key
WHERE order_date IS NOT NULL
),
--Work on aggregations
products_aggregation AS
(
SELECT 
  product_key,
  product_name,
  category_name,
  sub_category,
  cost,
  COUNT(DISTINCT order_number) AS total_orders,
  COUNT(DISTINCT customer_key) AS total_customers,
  MIN(order_date) AS first_order,
  MAX(order_date) AS last_order,
  DATEDIFF(MONTH, MIN(order_date),MAX(order_date)) AS lifespan,
  SUM(sales_amount) AS total_sales,
  SUM(quantity) AS total_quantity,
  ROUND(AVG(CAST(sales_amount AS FLOAT)/NULLIF(quantity,0)),1) AS avg_selling_price
FROM products_base
GROUP BY product_key, product_name,category_name,sub_category, cost
)

SELECT 
  category_name,
  sub_category,
  product_name,
  cost,
  total_orders,
  total_sales,
  total_quantity,
  total_customers,
  last_order,
  DATEDIFF(MONTH, last_order, GETDATE()) AS recency,
  CASE WHEN total_sales > 50000 THEN 'High Performer'
  	 WHEN total_sales > = 10000 THEN 'Mid Performer'
  	 ELSE 'Low Performer'
  END AS product_segment,
  lifespan,
  avg_selling_price,
  CASE WHEN total_orders = 0 THEN 0
  	 ELSE total_sales/total_orders 
  END AS avg_order_revenue,
  CASE WHEN lifespan = 0 THEN 0
  	 ELSE total_sales/lifespan 
  END AS avg_monthly_revenue
FROM products_aggregation
