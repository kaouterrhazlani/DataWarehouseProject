-- Check data quality :
USE DW_Sales;
GO
SELECT *  FROM bronze.crm_prd_info 
--check primary key quality: check nulls and duplicates values
SELECT prd_id , count(*)
FROM bronze.crm_prd_info -- check for silver.crm_prd_info
GROUP BY prd_id
HAVING count(*) > 1 AND prd_id IS NULL
--CHECK unwanted spaces :
SELECT prd_nm
FROM
bronze.crm_prd_info    -- check for silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)  --there is no unwanted spaces
--CHECK NEGATIVE AND NULLS NUMBERS in cost
SELECT prd_cost
FROM
bronze.crm_prd_info    -- check for silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL
--replace nulll by 0 ISNULL(prd_cost,0) for bronze layer
SELECT ISNULL(prd_cost,0) --replace null by 0
FROM
bronze.crm_prd_info       -- check for silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL
-- --check data standarization and consistency : prd_line  M R S T NULL
SELECT DISTINCT prd_line
FROM
bronze.crm_prd_info    -- check for silver.crm_prd_info
-- Replace values M,R,S,T and NULL by Mountain,Road,o.ther Sales , Touring and n\a
SELECT 
	CASE UPPER(TRIM(prd_line))
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'other Salses'
				WHEN 'T' THEN 'Touring'
				ELSE 'n\a'
			END prd_line
FROM
bronze.crm_prd_info;
--	GET category id from prd_key then filter 
-- Filter out unmatched data / categories in prd table that are not available in cat table 
SELECT *, 
REPLACE(SUBSTRING(UPPER(TRIM(prd_key)),1,5),'-','_') AS cat_id
FROM 
bronze.crm_prd_info   
WHERE REPLACE(SUBSTRING(UPPER(TRIM(prd_key)),1,5),'-','_')  
NOT IN (
SELECT DISTINCT ID FROM bronze.erp_px_cat_g1v2
)
-- Filter out unmatched data /  products that have not any order in sales table
SELECT 
	prd_id,
	REPLACE (SUBSTRING(UPPER(TRIM(prd_key)),1,5),'-','_') AS prd_cat_id,
	SUBSTRING(UPPER(TRIM(prd_key)),7,LEN(TRIM(prd_key)))AS prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
FROM
bronze.crm_prd_info
WHERE SUBSTRING(UPPER(TRIM(prd_key)),7,LEN(TRIM(prd_key))) NOT IN ( -- replace with IN to have products that have orders in sales table
	SELECT
	DISTINCT UPPER(TRIM(sls_prd_key))
	FROM
	bronze.crm_sales_details)
--check dates : end date must not be earlier than the start date
SELECT *
FROM
silver.crm_prd_info  -- check for silver.crm_prd_info
WHERE prd_end_dt > prd_start_dt
ORDER BY prd_id
GO
-- Treat date issues : 
-- 1- end date is earlier than the start date 
-- 2- overlapping time ranges
-- 3- The most recent version of the product
-- Apply all previous transformations
-- Insert into silver table

PRINT '-------------Load into silver layer-------------';
PRINT 'Truncating Table : silver.crm_prd_info';
TRUNCATE TABLE silver.crm_prd_info;
GO
PRINT 'Inserting only last updated product into : silver.crm_prd_info';
WITH CTE_bronze_crm_prd_info_datecorrected AS (
    SELECT 
        prd_id,
        REPLACE(SUBSTRING(UPPER(TRIM(prd_key)), 1, 5), '-', '_') AS cat_id,
        SUBSTRING(UPPER(TRIM(prd_key)), 7, LEN(TRIM(prd_key))) AS prd_key,
        TRIM(prd_nm) AS prd_nm,
        ISNULL(prd_cost, 0) AS prd_cost,
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'other Salses'
            WHEN 'T' THEN 'Touring'
            ELSE 'n\a'
        END AS prd_line,
        CASE  -- end date is earlier than the start date 
            WHEN prd_end_dt < prd_start_dt THEN prd_end_dt
            ELSE prd_start_dt
        END AS prd_start_dt,
        CASE -- overlapping time ranges
            WHEN LEAD(prd_end_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) IS NOT NULL AND prd_end_dt IS NOT NULL
                THEN DATEADD(DAY, -1, LEAD(prd_end_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt))
            WHEN LEAD(prd_end_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) IS NULL AND prd_end_dt IS NOT NULL
                THEN prd_start_dt
            ELSE NULL
        END AS prd_end_dt
    FROM bronze.crm_prd_info
),
CTE_bronze_crm_prd_info_lastproduct AS (
    SELECT
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        CAST(prd_start_dt AS DATE) AS prd_start_dt,
        CAST(prd_end_dt AS DATE) AS prd_end_dt,
        CASE --prd_last_update_dt:update date of most recent version of the product
            WHEN prd_start_dt IS NOT NULL AND prd_end_dt IS NULL 
                THEN CAST(prd_start_dt AS DATE)
            WHEN prd_start_dt IS NOT NULL AND prd_end_dt IS NOT NULL
                THEN CAST(prd_end_dt AS DATE)
        END AS prd_last_update_dt, 
		ROW_NUMBER() OVER(   --prd_last_update_dt_pos:position of update date of most recent version of the product
		PARTITION BY prd_key 
		ORDER BY 
		CASE 
            WHEN prd_start_dt IS NOT NULL AND prd_end_dt IS NULL 
                THEN CAST(prd_start_dt AS DATE)
            WHEN prd_start_dt IS NOT NULL AND prd_end_dt IS NOT NULL
                THEN CAST(prd_end_dt AS DATE)
        END DESC) prd_last_update_dt_pos
    FROM CTE_bronze_crm_prd_info_datecorrected
)

INSERT INTO silver.crm_prd_info (
    prd_id,
    prd_cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt,
    prd_last_update_dt
)
SELECT 
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt,
    prd_last_update_dt
FROM CTE_bronze_crm_prd_info_lastproduct
WHERE prd_last_update_dt_pos = 1 --to get the most recent date 
GO
--check silver layer
SELECT * FROM silver.crm_prd_info;
