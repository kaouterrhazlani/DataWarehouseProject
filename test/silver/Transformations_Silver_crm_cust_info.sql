-- Check data quality :
USE DW_Sales;
GO
SELECT *  FROM bronze.crm_cust_info 
--check primary key quality: check nulls and duplicates values
SELECT 
	cst_id, 
	count(*)
FROM bronze.crm_cust_info  -- check for silver.crm_prd_info
GROUP BY cst_id
HAVING count(*) > 1 OR cst_id IS NULL;

-- Get Only unique Primary key / NULLs and Duplicates are excluded here !
SELECT 
	cst_id
	FROM (
		SELECT 
		*,
		ROW_NUMBER() OVER( PARTITION BY cst_id ORDER BY cst_create_date DESC) as nbr 
		FROM bronze.crm_cust_info 
)t WHERE nbr = 1 AND cst_id IS NOT NULL;

--CHECK unwanted spaces :
SELECT 
	cst_gndr
FROM
bronze.crm_cust_info   -- check for silver.crm_prd_info
WHERE cst_gndr != TRIM(cst_gndr);   -- cst_firstname   cst_lastname

--SELECT columns without unwanted spaces:
SELECT 
	cst_id,
	cst_key,
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname) AS cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date
FROM 
bronze.crm_cust_info;

--check data standarization and consistency:
SELECT DISTINCT cst_gndr -- cst_marital_status
FROM bronze.crm_cust_info 	-- check for silver.crm_prd_info

--Replace values M, S and NULL by MARRIED, SINGLE, and n\a
--Replace values M,F and NULL by MALE, FEMALE,	and n\a
SELECT 
	cst_id,
	cst_key,
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname) AS cst_lastname,
	CASE UPPER(TRIM(cst_marital_status))
	WHEN 'M' THEN 'MARRIED'
	WHEN 'S' THEN 'SINGLE'
	ELSE 'n/a'
	END cst_marital_status,
	CASE 
	WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'MALE'
	WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'FEMALE'
	ELSE 'n/a'
	END cst_gndr,
	cst_create_date
FROM 
bronze.crm_cust_info; 
------------------------------------------------------------------------------------------
PRINT'-------------Load into silver layer-------------'
PRINT'Turncating Table :silver.crm_cust_info';
TRUNCATE TABLE silver.crm_cust_info
PRINT'Inserting data into :silver.crm_cust_info';
INSERT INTO silver.crm_cust_info(
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date)
(
	SELECT 
		cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname) AS cst_lastname,
		CASE UPPER(TRIM(cst_marital_status))
		WHEN 'M' THEN 'MARRIED'
		WHEN 'S' THEN 'SINGLE'
		ELSE 'n/a'
		END cst_marital_status,
		CASE 
		WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'MALE'
		WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'FEMALE'
		ELSE 'n/a'
		END cst_gndr,
		cst_create_date
			FROM (
			SELECT 
			*,
			ROW_NUMBER() OVER( PARTITION BY cst_id ORDER BY cst_create_date DESC) as nbr 
			FROM bronze.crm_cust_info 
			)t WHERE nbr = 1 AND cst_id IS NOT NULL
)

-- check silver layer 
SELECT * FROM silver.crm_cust_info 

