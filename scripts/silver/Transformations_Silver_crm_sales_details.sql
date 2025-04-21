-- Check data quality :
USE DW_Sales;
GO
SELECT * FROM bronze.crm_sales_details;
-- check nulls and duplicates in sales order number
SELECT sls_ord_num, COUNT(*) as n
FROM
silver.crm_sales_details  -- check for silver.crm_sales_details
GROUP BY sls_ord_num 
HAVING COUNT(*) >1 AND sls_ord_num IS NULL;
--check unwanted spaces 
SELECT * 
FROM silver.crm_sales_details -- check for silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

SELECT * 
FROM silver.crm_sales_details -- check for silver.crm_sales_details
WHERE sls_prd_key != TRIM(sls_prd_key);

-- GET PRODUCT that doesn't exist in product table:
SELECT * 
FROM
silver.crm_sales_details -- check for silver.crm_sales_details
WHERE sls_prd_key NOT IN
	(
		SELECT
		prd_key
		FROM
		silver.crm_prd_info)
-- GET customer that doesn't exist in customer table:
SELECT * 
FROM
silver.crm_sales_details -- check for silver.crm_sales_details
WHERE sls_cust_id NOT IN
	(
		SELECT
		cst_id
		FROM
		silver.crm_cust_info)
-- Transform date from integer to date format
SELECT 
CASE
	WHEN LEN(sls_order_dt) > 8 OR LEN(sls_order_dt) < 8 THEN NULL
	ELSE CONVERT(DATE,CAST( sls_order_dt AS VARCHAR),112)
END sls_order_dt,
CASE
	WHEN LEN(sls_ship_dt) > 8 OR LEN(sls_ship_dt) < 8 THEN NULL
	ELSE CONVERT(DATE,CAST( sls_ship_dt AS VARCHAR),112)
END sls_ship_dt,
CASE
	WHEN LEN(sls_due_dt) > 8 OR LEN(sls_due_dt) < 8 THEN NULL
	ELSE CONVERT(DATE,CAST( sls_due_dt AS VARCHAR),112)
END sls_due_dt
FROM
bronze.crm_sales_details
-- Check that we have right order of dates: 
-- Order date must be before ship date and shipe date must be before due date 
SELECT *
FROM
silver.crm_sales_details -- check for silver.crm_sales_details
WHERE NOT (sls_order_dt <= sls_ship_dt AND sls_ship_dt <= sls_due_dt AND sls_order_dt <= sls_due_dt ) 
-- CHECK negatives values /NULL values /and 0 values
SELECT *
FROM silver.crm_sales_details -- check for silver.crm_sales_details
WHERE sls_sales!= sls_quantity* sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL 
OR sls_sales <=0 OR sls_quantity <=0 OR sls_price <=0  
ORDER BY sls_sales;
-- Replace them by the correct values respoecting : Sales = quantity * price
-- sales , quantity and price : not NULL
-- sales , quantity and price : > 0
SELECT * 
FROM (
	SELECT 
	sls_sales,
	sls_price,
	sls_quantity,
	CASE 
		WHEN (sls_sales IS NULL OR sls_sales <=0 OR sls_sales != abs(sls_quantity*sls_price))
		AND (sls_price IS NOT NULL AND sls_quantity IS NOT NULL AND sls_price!=0 AND sls_quantity !=0)
			THEN ABS (sls_price * sls_quantity)
		ELSE sls_sales
	END sls_sales_correct,
	CASE
		WHEN (sls_quantity IS NULL OR sls_quantity <= 0)
		AND (sls_sales IS NOT NULL AND sls_price IS NOT NULL AND sls_price!=0 AND sls_sales !=0)
			THEN ABS(sls_sales / sls_price)
		ELSE ABS(sls_quantity)
	END sls_quantity_correct,
	CASE
		WHEN (sls_price IS NULL OR  sls_price <=0) 
		AND (sls_sales IS NOT NULL AND sls_quantity IS NOT NULL AND sls_quantity!=0 AND sls_sales !=0)
			THEN ABS(sls_sales / sls_quantity)
		ELSE ABS(sls_price)
	END sls_price_correct,
	CASE 
		WHEN sls_quantity * sls_price = sls_sales 
			THEN 'OK'
		ELSE 'CORRIGÉ'
	END AS status_correction
	FROM bronze.crm_sales_details
	)t
WHERE status_correction = 'CORRIGÉ'
ORDER BY sls_sales;
------------------------------------------------------------------------------------------
PRINT'-------------Load into silver layer-------------'
PRINT'Turncating Table :silver.crm_sales_details';
TRUNCATE TABLE silver.crm_sales_details
PRINT'Inserting data into :silver.crm_sales_details';
INSERT INTO silver.crm_sales_details(
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
)
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE
	WHEN LEN(sls_order_dt) > 8 OR LEN(sls_order_dt) < 8 THEN NULL
	ELSE CONVERT(DATE,CAST( sls_order_dt AS VARCHAR),112)
END sls_order_dt,
CASE
	WHEN LEN(sls_ship_dt) > 8 OR LEN(sls_ship_dt) < 8 THEN NULL
	ELSE CONVERT(DATE,CAST( sls_ship_dt AS VARCHAR),112)
END sls_ship_dt,
CASE
	WHEN LEN(sls_due_dt) > 8 OR LEN(sls_due_dt) < 8 THEN NULL
	ELSE CONVERT(DATE,CAST( sls_due_dt AS VARCHAR),112)
END sls_due_dt,
CASE 
	WHEN (sls_sales IS NULL OR sls_sales <=0 OR sls_sales != abs(sls_quantity*sls_price))
	AND (sls_price IS NOT NULL AND sls_quantity IS NOT NULL AND sls_price!=0 AND sls_quantity !=0)
		THEN ABS (sls_price * sls_quantity)
	ELSE sls_sales
END sls_sales,
CASE
	WHEN (sls_quantity IS NULL OR sls_quantity <= 0)
	AND (sls_sales IS NOT NULL AND sls_price IS NOT NULL AND sls_price!=0 AND sls_sales !=0)
		THEN ABS(sls_sales / sls_price)
	ELSE ABS(sls_quantity)
END sls_quantity,
CASE
	WHEN (sls_price IS NULL OR  sls_price <=0) 
	AND (sls_sales IS NOT NULL AND sls_quantity IS NOT NULL AND sls_quantity!=0 AND sls_sales !=0)
		THEN ABS(sls_sales / sls_quantity)
	ELSE ABS(sls_price)
END sls_price
FROM 
bronze.crm_sales_details

--check data layer
SELECT * FROM silver.crm_sales_details