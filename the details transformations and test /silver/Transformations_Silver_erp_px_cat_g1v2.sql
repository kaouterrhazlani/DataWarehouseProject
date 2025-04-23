-- Check data quality :
USE DW_Sales;
GO
-- check unwanted spaces
SELECT * 
FROM bronze.erp_px_cat_g1v2   -- check for silver.erp_px_cat_g1v2
WHERE ID !=UPPER(TRIM(ID))

SELECT * 
FROM bronze.erp_px_cat_g1v2   -- check for silver.erp_px_cat_g1v2
WHERE CAT !=UPPER(TRIM(CAT))

SELECT * 
FROM bronze.erp_px_cat_g1v2   -- check for silver.erp_px_cat_g1v2
WHERE SUBCAT !=UPPER(TRIM(SUBCAT))

SELECT * 
FROM bronze.erp_px_cat_g1v2   -- check for silver.erp_px_cat_g1v2
WHERE MAINTENANCE !=UPPER(TRIM(MAINTENANCE))

--check unmatched data between erp_loc_a101 and customer table
SELECT * 
FROM bronze.erp_px_cat_g1v2 -- check for silver.erp_px_cat_g1v2
WHERE ID NOT IN (   
	SELECT prd_cat_id FROM silver.crm_prd_info  --no product with  CO_PD category , and this is normal
	)
-- check data consistency and normalization 
SELECT DISTINCT CAT 
FROM bronze.erp_px_cat_g1v2  -- check for silver.erp_px_cat_g1v2
ORDER BY CAT

SELECT DISTINCT SUBCAT 
FROM bronze.erp_px_cat_g1v2  -- check for silver.erp_px_cat_g1v2
ORDER BY SUBCAT

SELECT DISTINCT MAINTENANCE 
FROM bronze.erp_px_cat_g1v2  -- check for silver.erp_px_cat_g1v2
ORDER BY MAINTENANCE
------------------------------------------------------------------------------------------
PRINT'-------------Load into silver layer-------------'
PRINT'Turncating Table :silver.erp_px_cat_g1v2';
TRUNCATE TABLE silver.erp_px_cat_g1v2
PRINT'Inserting data into :silver.erp_px_cat_g1v2';
INSERT INTO silver.erp_px_cat_g1v2
(
ID,
CAT,
SUBCAT,
MAINTENANCE
)
SELECT 
ID,
CAT,
SUBCAT,
MAINTENANCE
FROM bronze.erp_px_cat_g1v2
--check silver layer
SELECT * FROM silver.erp_px_cat_g1v2