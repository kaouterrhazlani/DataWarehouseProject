USE DW_Sales
GO
-------------------------------------------------------------
--*******************customer dim*******************
-------------------------------------------------------------
--Join tables containing informations about customers
SELECT 
	c1.cst_id,
	c1.cst_key,
	c1.cst_firstname,
	c1.cst_lastname,
	c1.cst_marital_status,
	c1.cst_gndr,
	c1.cst_create_date,
	c2.BDATE,
	c2.GEN,
	c3.CNTRY
	FROM silver.crm_cust_info c1
	LEFT JOIN silver.erp_cust_az12 c2
	ON c1.cst_key = c2.CID
	LEFT JOIN silver.erp_loc_a101 c3
	ON c1.cst_key = c3.CID
GO
--Check duplicates
SELECT cst_id,COUNT(*) AS number 
FROM(
	SELECT 
	c1.cst_id,
	c1.cst_key,
	c1.cst_firstname,
	c1.cst_lastname,
	c1.cst_marital_status,
	c1.cst_gndr,
	c1.cst_create_date,
	c2.BDATE,
	c2.GEN,
	c3.CNTRY
	FROM silver.crm_cust_info c1
	LEFT JOIN silver.erp_cust_az12 c2
	ON c1.cst_key = c2.CID
	LEFT JOIN silver.erp_loc_a101 c3
	ON c1.cst_key = c3.CID
	)t
GROUP BY cst_id
HAVING COUNT(*)>1
GO
-- Replace gender in crm customer table if it is NULL with gender in erp customer table.
SELECT 
	c1.cst_id,
	c1.cst_key,
	c1.cst_firstname,
	c1.cst_lastname,
	c1.cst_marital_status,
	CASE
		WHEN (c1.cst_gndr IS NULL OR c1.cst_gndr ='n/a') 
		AND (c2.GEN IS NOT NULL AND c2.GEN != 'n/a')
		THEN c2.GEN
		ELSE COALESCE(c1.cst_gndr,'n\a')
	END gender,
	c1.cst_create_date,
	c2.BDATE,
	c3.CNTRY
	FROM silver.crm_cust_info c1
	LEFT JOIN silver.erp_cust_az12 c2
	ON c1.cst_key = c2.CID
	LEFT JOIN silver.erp_loc_a101 c3
	ON c1.cst_key = c3.CID
GO
--Replace columns name by friendly names :
--AND Sort columns into logical order :
SELECT 
	c1.cst_id customer_id,
	c1.cst_key customer_number,
	c1.cst_firstname first_name,
	c1.cst_lastname last_name,
	c3.CNTRY country,
	c1.cst_marital_status marital_status,
	CASE
		WHEN (c1.cst_gndr IS NULL OR c1.cst_gndr ='n/a') 
		AND (c2.GEN IS NOT NULL AND c2.GEN != 'n/a')
		THEN c2.GEN
		ELSE COALESCE(c1.cst_gndr,'n\a')
	END gender,
	c2.BDATE bithdate,
	c1.cst_create_date create_date
	FROM silver.crm_cust_info c1
	LEFT JOIN silver.erp_cust_az12 c2
	ON c1.cst_key = c2.CID
	LEFT JOIN silver.erp_loc_a101 c3
	ON c1.cst_key = c3.CID
GO
-- add surrogate key to connect data in our model
SELECT 
	ROW_NUMBER() OVER( ORDER BY c1.cst_id) customer_key, 
	c1.cst_id customer_id,
	c1.cst_key customer_number,
	c1.cst_firstname first_name,
	c1.cst_lastname last_name,
	c3.CNTRY country,
	c1.cst_marital_status marital_status,
	CASE
		WHEN (c1.cst_gndr IS NULL OR c1.cst_gndr ='n/a') 
		AND (c2.GEN IS NOT NULL AND c2.GEN != 'n/a')
		THEN c2.GEN
		ELSE COALESCE(c1.cst_gndr,'n\a')
	END gender,
	c2.BDATE bithdate,
	c1.cst_create_date create_date
	FROM silver.crm_cust_info c1
	LEFT JOIN silver.erp_cust_az12 c2
	ON c1.cst_key = c2.CID
	LEFT JOIN silver.erp_loc_a101 c3
	ON c1.cst_key = c3.CID
GO
-------------------------------------------------------------
--*******************product dim*******************
-------------------------------------------------------------
--join tables containing informations about products
SELECT 
p1.prd_id,
p1.prd_cat_id,
p1.prd_key,
p1.prd_nm,
p1.prd_cost,
p1.prd_line,
p1.prd_last_update_dt,
p2.CAT,
p2.SUBCAT,
p2.MAINTENANCE
FROM silver.crm_prd_info p1
LEFT JOIN silver.erp_px_cat_g1v2 p2
ON p1.prd_cat_id = p2.ID
GO
--Check duplicates
SELECT prd_key ,COUNT(*) number
FROM
(
	SELECT 
	p1.prd_id,
	p1.prd_cat_id,
	p1.prd_key,
	p1.prd_nm,
	p1.prd_cost,
	p1.prd_line,
	p1.prd_last_update_dt,
	p2.CAT,
	p2.SUBCAT,
	p2.MAINTENANCE
	FROM silver.crm_prd_info p1
	LEFT JOIN silver.erp_px_cat_g1v2 p2
	ON p1.prd_cat_id = p2.ID 
)t
GROUP BY prd_key
HAVING COUNT(*) >1
GO
--Replace columns name by friendly names :
--AND Sort columns into logical order :
SELECT 
	p1.prd_id product_id,
	p1.prd_key product_key,
	p1.prd_nm product_name,
	p1.prd_cat_id category_id,
	p2.CAT category,
	p2.SUBCAT subcategory,
	p2.MAINTENANCE maintenance,
	p1.prd_cost product_cost,
	p1.prd_line product_line,
	p1.prd_last_update_dt product_last_update_date
FROM silver.crm_prd_info p1
LEFT JOIN silver.erp_px_cat_g1v2 p2
ON p1.prd_cat_id = p2.ID
GO
-- add surrogate key to connect data in our model
SELECT 
	ROW_NUMBER() OVER ( ORDER BY p1.prd_start_dt, p1.prd_key) product_key,
	p1.prd_id product_id,
	p1.prd_key product_number,
	p1.prd_nm product_name,
	p1.prd_cat_id category_id,
	p2.CAT category,
	p2.SUBCAT subcategory,
	p2.MAINTENANCE maintenance,
	p1.prd_cost product_cost,
	p1.prd_line product_line,
	p1.prd_last_update_dt product_last_update_date
FROM silver.crm_prd_info p1
LEFT JOIN silver.erp_px_cat_g1v2 p2
ON p1.prd_cat_id = p2.ID
WHERE p1.prd_end_dt IS NULL 
GO

-------------------------------------------------------------
--******************sales fact*******************
-------------------------------------------------------------
--join sales table with customer and product gold views to get surrogate keys
--with serrogate keys we can access to all informations
--replace columns name by friendly names :
SELECT
s.sls_ord_num order_number,
p.product_key,
c.customer_key,
s.sls_order_dt order_date,
s.sls_ship_dt shipping_date,
s.sls_due_dt due_date,
s.sls_sales sales_amount,
s.sls_quantity quantity,
s.sls_price price
FROM silver.crm_sales_details s
LEFT JOIN gold.dim_customers c
ON s.sls_cust_id =c.customer_id
LEFT JOIN gold.dim_products p
ON s.sls_prd_key = p.product_number
GO

