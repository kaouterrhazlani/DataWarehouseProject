USE DW_Sales
GO
SELECT * FROM gold.dim_customers
SELECT * FROM gold.dim_products
SELECT * FROM gold.fact_sales
--check if there are no match bteween dim_costumers/dim_products and fact_sales
SELECT * 
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
ON s.customer_key = c.customer_key
WHERE c.customer_key IS NULL 

SELECT 
*
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON s.product_key = p.product_key
WHERE p.product_key IS NULL