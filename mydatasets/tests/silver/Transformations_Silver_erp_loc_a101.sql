-- Check data quality :
USE DW_Sales;
GO
-- check unwanted spaces
SELECT * 
FROM bronze.erp_loc_a101   -- check for silver.erp_loc_a101
WHERE CID !=UPPER(TRIM(CID))

SELECT * 
FROM bronze.erp_loc_a101   -- check for silver.erp_loc_a101
WHERE CNTRY !=UPPER(TRIM(CNTRY))

--check unmatched data between erp_loc_a101 and customer table
SELECT * 
FROM bronze.erp_loc_a101 -- check for silver.erp_loc_a101
WHERE CID NOT IN (
	SELECT cst_key FROM silver.crm_cust_info
	)
--Get the right format of CID to match it with customer table and check unmatched data
--Example CID :'AW-00011000' to 'AW00011000'
SELECT
CID,
REPLACE(CID,'-','') AS CID_correct
FROM bronze.erp_loc_a101
WHERE REPLACE(CID,'-','') NOT IN (
	SELECT cst_key FROM silver.crm_cust_info
	)	
-- check data consistency and normalization 
SELECT DISTINCT CNTRY 
FROM bronze.erp_loc_a101  -- check for silver.erp_loc_a101
-- Modify the country values to a unified format
SELECT DISTINCT
CASE 
	WHEN UPPER(TRIM(CNTRY))='DE' THEN 'GERMANY'
	WHEN UPPER(TRIM(CNTRY)) IN ('USA','US') THEN 'UNITED STATES'
	WHEN UPPER(TRIM(CNTRY))IS NULL OR UPPER(TRIM(CNTRY))='' THEN 'n\a'
	ELSE UPPER(TRIM(CNTRY))
END CNTRY
FROM bronze.erp_loc_a101  

------------------------------------------------------------------------------------------
PRINT'-------------Load into silver layer-------------'
PRINT'Turncating Table :silver.erp_loc_a101';
TRUNCATE TABLE silver.erp_loc_a101
PRINT'Inserting data into :silver.erp_loc_a101';
INSERT INTO silver.erp_loc_a101
(
CID,
CNTRY
)
SELECT 
REPLACE(CID,'-','') AS CID,
CASE 
	WHEN UPPER(TRIM(CNTRY))='DE' THEN 'GERMANY'
	WHEN UPPER(TRIM(CNTRY)) IN ('USA','US') THEN 'UNITED STATES'
	WHEN UPPER(TRIM(CNTRY))IS NULL OR UPPER(TRIM(CNTRY))='' THEN 'n\a'
	ELSE UPPER(TRIM(CNTRY))
END CNTRY
FROM bronze.erp_loc_a101
--check silver layer
SELECT * FROM silver.erp_loc_a101