/*===============================================
Stored Procedure: silver.load_silver
Purpose:
    - Load transformed data from the Bronze layer into the Silver layer.
    - This procedure truncates the target Silver tables before inserting new records.
    - It applies data quality transformations during the insert phase using SELECT statements.
Parameters:
    - None. This procedure does not take any input parameters.
Return values:
    - None. This procedure does not return any output.
Execution:
    EXEC silver.load_silver;
Warning:
    - Running this procedure will truncate all Silver tables involved before inserting clean and transformed data from the Bronze layer.
================================================*/

USE DW_Sales
GO
EXEC silver.load_silver
GO
CREATE OR ALTER PROCEDURE silver.load_silver AS 
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME ,@start_time_ofbatch DATETIME,@end_time_ofbatch DATETIME;
	BEGIN TRY 
		SET @start_time_ofbatch=GETDATE();
		PRINT '**************************************';
		PRINT 'Loading the silver layer';
		PRINT '**************************************';
		PRINT '--------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '--------------------------';

		PRINT'-------------Load into silver.crm_cust_info-------------'
		SET @start_time = GETDATE();
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
		SET @end_time = GETDATE();
		PRINT'Duration of loading : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'s';

		PRINT'-------------Load into silver.crm_prd_info-------------'
		SET @start_time = GETDATE();
		PRINT'Turncating Table :silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info
		PRINT'Inserting data into :silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info(
			prd_id,
			prd_cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt)

			SELECT 
			prd_id, cat_id, prd_key,prd_nm,prd_cost,prd_line,CAST(prd_start_dt AS DATE),CAST(prd_end_dt AS DATE)
			FROM (
				SELECT 
					prd_id,
					REPLACE (SUBSTRING(UPPER(TRIM(prd_key)),1,5),'-','_') AS cat_id,
					SUBSTRING(UPPER(TRIM(prd_key)),7,LEN(TRIM(prd_key)))AS prd_key,
					TRIM(prd_nm) AS prd_nm,
					ISNULL(prd_cost,0) AS prd_cost,
					CASE UPPER(TRIM(prd_line))
						WHEN 'M' THEN 'Mountain'
						WHEN 'R' THEN 'Road'
						WHEN 'S' THEN 'other Salses'
						WHEN 'T' THEN 'Touring'
						ELSE 'n\a'
					END prd_line,
					CASE 
						WHEN prd_end_dt < prd_start_dt THEN prd_end_dt
						ELSE prd_start_dt
					END prd_start_dt,
					CASE  
						WHEN LEAD(prd_end_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) IS NOT NULL AND prd_end_dt IS NOT NULL
						THEN LEAD(prd_end_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)- 1
						WHEN LEAD(prd_end_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) IS NULL AND prd_end_dt IS NOT NULL
						THEN prd_start_dt
						ELSE NULL
					END  prd_end_dt
				FROM
				bronze.crm_prd_info)t

		SET @end_time = GETDATE();
		PRINT'Duration of loading : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'s';

		PRINT'-------------Load into silver.crm_sales_details-------------'
		SET @start_time = GETDATE();
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

		SET @end_time = GETDATE();
		PRINT'Duration of loading : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'s';
		
		PRINT '--------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '--------------------------';

		PRINT'-------------Load into silver.erp_cust_az12-------------'
		SET @start_time = GETDATE();
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

		SET @end_time = GETDATE();
		PRINT'Duration of loading : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'s';

		PRINT'-------------Load into silver.erp_loc_a101-------------'
		SET @start_time = GETDATE();
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

		SET @end_time = GETDATE();
		PRINT'Duration of loading : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'s';

		PRINT'-------------Load into silver.erp_px_cat_g1v2-------------'
		SET @start_time = GETDATE();
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

		SET @end_time = GETDATE();
		PRINT'Duration of loading : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'s';


		PRINT'--------------------------------------------------'
		SET @end_time_ofbatch=GETDATE();
		PRINT'Duration for all silver batch is '+CAST(DATEDIFF(second,@start_time_ofbatch,@end_time_ofbatch) AS VARCHAR)+'s';
	END TRY
	BEGIN CATCH
	PRINT '**************************************';
	PRINT'ERROR MESSAGE :'+ERROR_MESSAGE()
	PRINT'ERROR NUMBER :'+CAST(ERROR_NUMBER() AS NVARCHAR)
	PRINT'ERROR STATE :'+ERROR_STATE()
	PRINT '**************************************';
	END CATCH
END