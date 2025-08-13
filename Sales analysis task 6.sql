CREATE TABLE orders (
    order_id BIGINT,
    order_date DATE,
    amount NUMERIC(12,2),
    product_id VARCHAR(50)
);

-- Verify Data
SELECT * FROM orders LIMIT 10;


-- 3. Monthly sales trend (Revenue + Order Volume)
SELECT
    EXTRACT(YEAR FROM order_date) AS order_year,
    EXTRACT(MONTH FROM order_date) AS order_month,
    SUM(amount) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY order_year, order_month
ORDER BY order_year, order_month;



-- Monthly revenue & order volume with MoM growth and cumulative revenue
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month_start,
        SUM(amount) AS total_revenue,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    month_start,
    total_revenue,
    total_orders,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY month_start)) 
        / NULLIF(LAG(total_revenue) OVER (ORDER BY month_start), 0) * 100, 2
    ) AS mom_growth_percent,
    SUM(total_revenue) OVER (ORDER BY month_start) AS cumulative_revenue
FROM monthly_sales
ORDER BY month_start;

-- Best-selling product each month
WITH monthly_products AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month_start,
        product_id,
        SUM(amount) AS product_revenue,
        RANK() OVER (
            PARTITION BY DATE_TRUNC('month', order_date)
            ORDER BY SUM(amount) DESC
        ) AS rank_in_month
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date), product_id
)
SELECT
    month_start,
    product_id,
    product_revenue
FROM monthly_products
WHERE rank_in_month = 1
ORDER BY month_start;

