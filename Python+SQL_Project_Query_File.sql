DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    order_date DATE NOT NULL,
    ship_mode VARCHAR(50),
    segment VARCHAR(50),
    country VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    region VARCHAR(50),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_id VARCHAR(50),
    quantity INTEGER,
    discount NUMERIC(5, 2),
	sale_price NUMERIC(10, 2),
    profit NUMERIC(10, 2)
);

select * from orders;

-- Find top 10 highest reveue generating products 
SELECT product_id, SUM(sale_price) AS sales
FROM orders
GROUP BY product_id
ORDER BY sales DESC
LIMIT 10;

-- Find top 5 highest selling products in each region
select distinct region from orders;

with ranked_products as
	(select region, product_id, sum(sale_price) sales,
		    row_number() over(partition by region order by sum(sale_price) desc) rn
			from orders
			group by region, product_id
	)
select region, product_id, sales 
from ranked_products 
where rn<=5;

-- Find month over month sales growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023
/*
SELECT DATE_PART('year', TO_DATE(order_date, 'YYYY-MM-DD')) AS order_year
FROM orders;

SELECT EXTRACT(YEAR FROM TO_DATE(order_date, 'YYYY-MM-DD')) AS order_year
FROM orders;
*/

SELECT Distinct DATE_PART('year', order_date) AS order_year
FROM orders;

SELECT Distinct EXTRACT(YEAR FROM order_date) AS order_year
FROM orders;

WITH monthly_sales AS (
    SELECT 
        DATE_PART('year', order_date) AS order_year, 
        DATE_PART('month', order_date) AS order_month,
        SUM(sale_price) AS sales
    FROM orders
    GROUP BY 
        DATE_PART('year', order_date), 
        DATE_PART('month', order_date)
)
SELECT 
    order_month,
    SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022,
    SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023
FROM monthly_sales
GROUP BY order_month
ORDER BY order_month;

-- For each category which month had highest sales?
select distinct category, sum(sale_price) from orders group by category;
select category from orders;

SELECT 
    category, order_year_month, sales
FROM (
    SELECT 
        category,
        TO_CHAR(order_date, 'YYYY-MM') AS order_year_month,
        SUM(sale_price) AS sales,
        MAX(SUM(sale_price)) OVER (PARTITION BY category) AS max_sales
    FROM orders
    GROUP BY category, TO_CHAR(order_date, 'YYYY-MM')
) subquery
WHERE sales = max_sales;

-- Alternate Query
WITH monthly_sales AS (
    SELECT 
        category,
        TO_CHAR(order_date, 'YYYY-MM') AS order_year_month,
        SUM(sale_price) AS sales
    FROM orders
    GROUP BY category, TO_CHAR(order_date, 'YYYY-MM')
),
ranked_sales AS (
    SELECT 
        category,
        order_year_month,
        sales,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales DESC) AS rn
    FROM monthly_sales
)
SELECT category, order_year_month, sales
FROM ranked_sales
WHERE rn = 1;

-- Find sub categories profit growth percentage-wise in 2023 compare to 2022.
with cte as (
select sub_category, extract(year from order_date) as order_year,
sum(sale_price) as sales
from orders
group by sub_category,extract(year from order_date)
--order by year(order_date),month(order_date)
	), 
	
cte2 as (
select sub_category, 
	sum(case when order_year=2022 then sales else 0 end) as sales_2022, 
	sum(case when order_year=2023 then sales else 0 end) as sales_2023
from cte 
group by sub_category
)

select sub_category, (sales_2023-sales_2022)*100/sales_2022 as growth_percentage
from  cte2
order by (sales_2023-sales_2022)*100/sales_2022 desc;

-- Find sub categories profit growth in 2023 compare to 2022.

with cte as (
select sub_category, extract(year from order_date) as order_year,
sum(sale_price) as sales
from orders
group by sub_category,extract(year from order_date)
--order by year(order_date),month(order_date)
	), 
	
cte2 as (
select sub_category, 
	sum(case when order_year=2022 then sales else 0 end) as sales_2022, 
	sum(case when order_year=2023 then sales else 0 end) as sales_2023
from cte 
group by sub_category
)

select sub_category, (sales_2023-sales_2022) as profit_growth
from  cte2
order by (sales_2023-sales_2022) desc;


-- Which sub category had highest or top 5 growth by profit in 2023 compare to 2022?
select distinct sub_category from orders;

WITH yearly_sales AS (
    SELECT 
        sub_category, 
        EXTRACT(YEAR FROM order_date) AS order_year,
        SUM(sale_price) AS total_sales
    FROM orders
    GROUP BY sub_category, EXTRACT(YEAR FROM order_date)
),
yearly_comparison AS (
    SELECT 
        sub_category,
        SUM(CASE WHEN order_year = 2022 THEN total_sales ELSE 0 END) AS sales_2022,
        SUM(CASE WHEN order_year = 2023 THEN total_sales ELSE 0 END) AS sales_2023
    FROM yearly_sales
    GROUP BY sub_category
),
sales_growth AS (
    SELECT
        sub_category,
        sales_2022,
        sales_2023,
        (sales_2023 - sales_2022) AS sales_growth
    FROM yearly_comparison
)
SELECT 
    sub_category,
    sales_2022,
    sales_2023,
    sales_growth
FROM sales_growth
ORDER BY sales_growth DESC
LIMIT 5;

-- Using window function
WITH yearly_sales AS (
    SELECT 
        sub_category, 
        EXTRACT(YEAR FROM order_date) AS order_year,
        SUM(sale_price) AS total_sales
    FROM orders
    GROUP BY sub_category, EXTRACT(YEAR FROM order_date)
),
yearly_comparison AS (
    SELECT 
        sub_category,
        SUM(CASE WHEN order_year = 2022 THEN total_sales ELSE 0 END) AS sales_2022,
        SUM(CASE WHEN order_year = 2023 THEN total_sales ELSE 0 END) AS sales_2023
    FROM yearly_sales
    GROUP BY sub_category
),
sales_growth AS (
    SELECT
        sub_category,
        sales_2022,
        sales_2023,
        (sales_2023 - sales_2022) AS sales_growth,
        ROW_NUMBER() OVER (ORDER BY (sales_2023 - sales_2022) DESC) AS rank
    FROM yearly_comparison
)
SELECT 
    sub_category,
    sales_2022,
    sales_2023,
    sales_growth
FROM sales_growth
WHERE rank = 1;

