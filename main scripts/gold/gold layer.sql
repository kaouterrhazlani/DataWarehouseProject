/*============================================================
Create Views for Gold Layer
==============================================================
Script purpose : 
    - This script creates three views in the 'DW_Sales' database
      to model the dimensional schema (star schema).
    - It organizes cleaned and enriched data from the Silver layer 
      into a dimensional model for analysis and reporting.

Views:
    - gold.dim_customers  : Customer dimension
    - gold.dim_products   : Product dimension
    - gold.fact_sales     : Sales fact table

Details:
    - The customer dimension includes informations about customers
      and joins data from CRM and ERP sources.
    - The product dimension includes informations about actual products and joins data from CRM and ERP sources.
    - The sales fact joins with customer and product dimensions
      using business keys to provide meaningful insights.

WARNING:
    - Make sure all Silver layer views/tables exist and contain 
      correct data before running this script.
    - Any downstream BI tools or reports may depend on these views.
=============================================================*/
USE DW_Sales
GO
--Create view of customer dimension
CREATE OR ALTER VIEW gold.dim_customers 
AS
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
--Create view of product dimension
CREATE OR ALTER VIEW gold.dim_products
AS 
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
GO
--Create view of sales fact
CREATE OR ALTER VIEW gold.fact_sales 
AS
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
 