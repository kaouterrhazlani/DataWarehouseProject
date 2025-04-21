-- Check data quality :
USE DW_Sales;
GO
-- check unwanted spaces
SELECT * 
FROM bronze.erp_cust_az12   -- check for silver.erp_cust_az12
WHERE CID !=UPPER(TRIM(CID))
--check unmatched data between erp_cust_az12 and customer table
SELECT * 
FROM bronze.erp_cust_az12   -- check for silver.erp_cust_az12
WHERE CID NOT IN (
	SELECT cst_key FROM silver.crm_cust_info
	)
-- Get the right format of CID to match it with customer table
SELECT 
CASE 
	WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID,4,LEN(CID))
	ELSE CID
END CID,
BDATE,
GEN
FROM bronze.erp_cust_az12 
-- check data consistency and normalization : GEN values : FEMALE / MALE / n\a
SELECT DISTINCT GEN
FROM bronze.erp_cust_az12 -- check for silver.erp_cust_az12
--replace values with user friendly values and check if all match costumer table
SELECT * 
FROM
	(SELECT 
	CASE 
		WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID,4,LEN(CID))
		ELSE CID
	END CID,
	BDATE,
	CASE 
		WHEN UPPER(TRIM(GEN)) IN ('F','FEMALE') THEN 'FEMALE'
		WHEN UPPER(TRIM(GEN)) IN ('M','MALE') THEN 'MALE'
		ELSE 'n\a'
	END GEN
	FROM bronze.erp_cust_az12)t
	WHERE CID NOT IN (
	SELECT cst_key FROM silver.crm_cust_info
	)
--check dates
SELECT BDATE 
FROM bronze.erp_cust_az12  -- check for silver.erp_cust_az12
WHERE BDATE > GETDATE()
-- correct data 
SELECT 
CASE
	WHEN BDATE > GETDATE() THEN NULL
	ELSE BDATE
END BDATE 
FROM bronze.erp_cust_az12
ORDER BY BDATE   -- we have also date like '1916-02-10' correct or not depend to business rules
------------------------------------------------------------------------------------------
PRINT'-------------Load into silver layer-------------'
PRINT'Turncating Table :silver.erp_cust_az12';
TRUNCATE TABLE silver.erp_cust_az12
PRINT'Inserting data into :silver.erp_cust_az12';
INSERT INTO silver.erp_cust_az12
(
CID,
BDATE,
GEN
)
SELECT 
CASE 
	WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID,4,LEN(CID))
	ELSE CID
END CID,
CASE
	WHEN BDATE > GETDATE() THEN NULL
	ELSE BDATE
END BDATE,
CASE 
	WHEN UPPER(TRIM(GEN)) IN ('F','FEMALE') THEN 'FEMALE'
	WHEN UPPER(TRIM(GEN)) IN ('M','MALE') THEN 'MALE'
	ELSE 'n\a'
END GEN
FROM bronze.erp_cust_az12

-- check silver layer
SELECT * FROM silver.erp_cust_az12

