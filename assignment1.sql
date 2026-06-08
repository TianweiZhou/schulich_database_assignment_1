-- Q1
-- Write a query that reports the top 3 items with the highest total quantity sold for each year-month in the dataset.
WITH rank_table AS (
    SELECT TO_CHAR(sale_date, 'YYYY-MM') AS year_month, -- Year and month
        article AS item_name, -- Item name
        SUM(quantity) AS total_quantity_sold, -- Total quantity sold
        SUM(quantity * unit_price) AS total_revenue, -- Total revenue for each item
        COUNT (DISTINCT ticket_number) AS num_unique_tickets, -- Number of unique tickets containing the item
        DENSE_RANK() OVER (
            PARTITION BY TO_CHAR(sale_date, 'YYYY-MM')
            ORDER BY SUM(quantity) DESC) AS rank
    FROM assignment01.bakery_sales
    GROUP BY TO_CHAR(sale_date, 'YYYY-MM'), article
)
SELECT year_month,
       item_name,
       total_quantity_sold,
       total_revenue,
       num_unique_tickets
FROM rank_table
WHERE rank <= 3
ORDER BY year_month DESC,
         total_quantity_sold DESC;

-- Q2
-- Identify all sales tickets in December 2021 that include 5 or more unique articles.
SELECT ticket_number AS ticket_id, -- Ticket ID
       COUNT(DISTINCT article) AS num_unique_items -- Number of unique items (articles) in that ticket
FROM assignment01.bakery_sales
WHERE TO_CHAR(sale_date, 'YYYY-MM') = '2021-12'
GROUP BY ticket_number
HAVING COUNT(DISTINCT article) >= 5
ORDER BY num_unique_items DESC;

-- Q3
-- Determine the hour of the day when the Traditional Baguette was most frequently purchased during July (across all years).
SELECT DATE_PART('hour', sale_time) AS hour,
       SUM(quantity) AS total_quantity_sold
FROM assignment01.bakery_sales
WHERE article = 'TRADITIONAL BAGUETTE'
  AND DATE_PART('month', sale_date) = 7
GROUP BY DATE_PART('hour', sale_time)
ORDER BY total_quantity_sold DESC;

-- Q4
-- Identify the two-hour window (e.g., 14:00–16:00) in which the highest total quantity of items were sold, across all dates in the dataset.
SELECT DISTINCT sale_time AS shop_time,
                COUNT(sale_time) AS count
FROM assignment01.bakery_sales
GROUP BY sale_time
ORDER BY sale_time ASC;
-- After analyze transaction time and frequencies to estimate the bakery's shop hours (7-20)
WITH hourly_sales AS (
    SELECT (
        CASE
            WHEN DATE_PART('hour', sale_datetime) > 20 THEN 20 - 1 -- Adjusting last minute sales to previous time window
            ELSE DATE_PART('hour', sale_datetime)
        END
        ) AS sale_hour,
           SUM(quantity) AS total_quantity,
           SUM(quantity * unit_price) AS total_revenue
    FROM assignment01.bakery_sales
    GROUP BY (
        CASE
            WHEN DATE_PART('hour', sale_datetime) > 20 THEN 20 - 1
            ELSE DATE_PART('hour', sale_datetime)
        END
        )
)
SELECT t1.sale_hour AS time_window_start,
       t1.sale_hour + 2 AS time_window_end,
    SUM(t2.total_quantity) AS total_quantity_sold,
    SUM(t2.total_revenue) AS total_revenue
FROM hourly_sales t1
JOIN hourly_sales t2
    ON t2.sale_hour = t1.sale_hour
    OR t2.sale_hour = t1.sale_hour + 1
GROUP BY t1.sale_hour
ORDER BY total_quantity_sold DESC
LIMIT 1;

-- Q5
-- Write queries to assess the quality of the dataset. Consider checks for:
-- Missing values (e.g., NULLs in important columns)
SELECT COUNT(*) - COUNT(sale_date) AS null_dates,
       COUNT(*) - COUNT(sale_time) AS null_times,
       COUNT(*) - COUNT(ticket_number) AS null_tickets,
       COUNT(*) - COUNT(article) AS null_artical,
       COUNT(*) - COUNT(quantity) AS null_quantities,
       COUNT(*) - COUNT(unit_price) AS null_unit_prices,
       COUNT(*) - COUNT(sale_datetime) AS null_unit_prices
FROM assignment01.bakery_sales;

-- Duplicate records
SELECT *
FROM assignment01.bakery_sales
GROUP BY sale_date,
         sale_time,
         ticket_number,
         article,
         quantity,
         unit_price,
         sale_datetime
HAVING COUNT(*) > 1;

-- Outliers (e.g., negative quantities or unusually high values)
SELECT MAX(sale_date) AS max_sale_date,
       MIN(sale_date) AS min_sale_date,
       MAX(sale_time) AS max_sale_time,
       MIN(sale_time) AS min_sale_time,
       MAX(quantity) AS max_quantity,
       MIN(quantity) AS min_quantity,
       MAX(unit_price) AS max_unit_price,
       MIN(unit_price) AS min_unit_price,
       MAX(sale_datetime) AS max_sale_datetime,
       MIN(sale_datetime) AS min_sale_datetime
FROM assignment01.bakery_sales;
