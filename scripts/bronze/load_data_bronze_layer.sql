/*===============================================
Create and Execute stored procedure for loading data 
from sources(ERP and CRM) to the bronze layer
=================================================
Script purpose : 
	-This stored procedure(bronze.load_bronze) loads data from csv files into bronze layer.
	-This procedure turncates the bronze tables : make them empty. before inserting.
	-This procedure insert data to tables using Bulk insert.
	-This procedure give the duration (second) for each table insert and give also the duration(second) for all the batch .
Parameters : None. 
			this stored procedure doesn't use any parameters. 
Returned values : None
			this stored procedure doesn't return any values. 
For call used :
			EXEC bronze.load_bronze;
WARNING:
	-Attention: running this script will make the tables empty, and then inserting from sources.
*/
USE DW_Sales;
GO
EXEC bronze.load_bronze
GO
-- Refreshing the bronze layer tables
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME ,@start_time_ofbatch DATETIME,@end_time_ofbatch DATETIME;
	BEGIN TRY 
		SET @start_time_ofbatch=GETDATE();
		PRINT '**************************************';
		PRINT 'Loading the bronze layer';
		PRINT '**************************************';
		PRINT '--------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '--------------------------';

		SET @start_time = GETDATE();
		--Make the table empty before inserting 
		PRINT'>>Turncating Table :bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;
		--insert all data from csv file to table in one time
		PRINT'>>Inserting data into :bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\kaout\Desktop\PROJECT\Datasets\source_crm\cust_info.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			CODEPAGE = '65001', -- UTF-8
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT'Duration of insert : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'s'; 
		--QUALITY CHECK: CHECK THAT DATA HAS NOT SHIFTED 
		--AND IS IN THE CORRECT COLUMNS 
		--SELECT * FROM bronze.crm_cust_info;
		--SELECT COUNT(*) FROM bronze.crm_cust_info;
		PRINT'--------------------------------------------------'

		SET @start_time = GETDATE();
		--Make the table empty before inserting 
		PRINT'>>Turncating Table :bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;
		--insert all data from csv file to table in one time
		PRINT'>>Inserting data into :bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\kaout\Desktop\PROJECT\Datasets\source_crm\prd_info.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			CODEPAGE = '65001', -- UTF-8
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT'Duration of insert : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'s'; 
		--QUALITY CHECK: CHECK THAT DATA HAS NOT SHIFTED 
		--AND IS IN THE CORRECT COLUMNS 
		--SELECT * FROM bronze.crm_prd_info;
		--SELECT COUNT(*) FROM bronze.crm_prd_info;
		PRINT'--------------------------------------------------'

		SET @start_time = GETDATE();
		--Make the table empty before inserting
		PRINT'>>Turncating Table :bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
		--insert all data from csv file to table in one time
		PRINT'>>Inserting data into :bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\kaout\Desktop\PROJECT\Datasets\source_crm\sales_details.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			CODEPAGE = '65001', -- UTF-8
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT'Duration of insert : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'s';
		--QUALITY CHECK: CHECK THAT DATA HAS NOT SHIFTED 
		--AND IS IN THE CORRECT COLUMNS 
		--SELECT * FROM bronze.crm_sales_details;
		--SELECT COUNT(*) FROM bronze.crm_sales_details;

		PRINT '--------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '--------------------------';

		SET @start_time = GETDATE();
		--Make the table empty before inserting
		PRINT'>>Turncating Table :bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;
		--insert all data from csv file to table in one time
		PRINT'>>Inserting data into :bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\kaout\Desktop\PROJECT\Datasets\source_erp\cust_az12.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			CODEPAGE = '65001', -- UTF-8
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT'Duration of insert : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'s';
		--QUALITY CHECK: CHECK THAT DATA HAS NOT SHIFTED 
		--AND IS IN THE CORRECT COLUMNS 
		--SELECT * FROM bronze.erp_cust_az12;
		--SELECT COUNT(*) FROM bronze.erp_cust_az12;
		PRINT'--------------------------------------------------'

		SET @start_time = GETDATE();
		--Make the table empty before inserting 
		PRINT'>>Turncating Table :bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;
		--insert all data from csv file to table in one time
		PRINT'>>Inserting data into :bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\kaout\Desktop\PROJECT\Datasets\source_erp\loc_a101.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			CODEPAGE = '65001', -- UTF-8
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT'Duration of insert : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'s';
		--QUALITY CHECK: CHECK THAT DATA HAS NOT SHIFTED 
		--AND IS IN THE CORRECT COLUMNS 
		--SELECT * FROM bronze.erp_loc_a101;
		--SELECT COUNT(*) FROM bronze.erp_loc_a101;
		PRINT'--------------------------------------------------'

		SET @start_time = GETDATE();
		--Make the table empty before inserting 
		PRINT'>>Turncating Table :bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		--insert all data from csv file to table in one time
		PRINT'>>Inserting data into :bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\kaout\Desktop\PROJECT\Datasets\source_erp\px_cat_g1v2.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			CODEPAGE = '65001', -- UTF-8
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT'Duration of insert : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'s';
		--QUALITY CHECK: CHECK THAT DATA HAS NOT SHIFTED 
		--AND IS IN THE CORRECT COLUMNS 
		--SELECT * FROM bronze.erp_px_cat_g1v2;
		--SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2;

		PRINT'--------------------------------------------------'
		SET @end_time_ofbatch=GETDATE();
		PRINT'Duration for all bronze batch is '+CAST(DATEDIFF(second,@start_time_ofbatch,@end_time_ofbatch) AS VARCHAR)+'s';
	END TRY
	BEGIN CATCH
		PRINT '**************************************';
		PRINT 'ERROR DURING LOADING BRONZE LAYER';
		PRINT 'ERROR MESSSAGE'+ERROR_MESSAGE();
		PRINT 'ERROR NUMBER'+ CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR STATE'+ERROR_STATE();
		PRINT '**************************************';
	END CATCH
END
