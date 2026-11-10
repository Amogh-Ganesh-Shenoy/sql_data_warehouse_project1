/*
==========================================
Stored Procedure: Loading the Bronze Layer
==========================================
Purpose: 
1) This is a stored procedure that loads data from the source .csv files into the 'bronze' schema.
2) It performs: 
              a) Truncates the bronze tables before loading data.
              b) Uses 'Bulk Insert' to load data into 'bronze' layer tables. 

Parameters: 
1) None.
2) This store procedure does not accept any parameters and does not return any values. 

Usage:
EXECUTE bronze.load_bronze;

----------------------------------------------------------------------------------------
*/
CREATE OR ALTER PROCEDURE bronze.load_bronze as
BEGIN

	DECLARE @start_time AS DATETIME, 
			@end_time AS DATETIME,
			@batch_start_time AS DATETIME,
			@batch_end_time AS DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		

		PRINT '==================================';
		PRINT '      Bulk Inserting Operation    ';
		PRINT '==================================';

		PRINT '-----------------------------------';
		PRINT '       Loading CRM Tables          ';
		PRINT '-----------------------------------';

		SET @start_time = GETDATE();
		PRINT '-->Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;
		PRINT '-->Inserting Data into: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'Load Duration:bronze.crm_cust_info ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(50)) + 's';
		PRINT '------------------------------------';


		SET @start_time = GETDATE();
		PRINT '-->Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;
		PRINT '-->Inserting Data into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE();
		PRINT 'Load Duration:bronze.crm_prd_info ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(50)) + 's';
		PRINT '------------------------------------';

		SET @start_time = GETDATE();
		PRINT '-->Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
		PRINT '-->Inserting Data into: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE();
		PRINT 'Load Duration:bronze.crm_sales_details ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(50)) + 's';
		PRINT '------------------------------------';


		PRINT '-----------------------------------';
		PRINT '       Loading ERP Tables          ';
		PRINT '-----------------------------------';

		SET @start_time = GETDATE();
		PRINT '-->Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;
		PRINT '-->Inserting Data into: bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'Load Duration:bronze.erp_cust_az12 ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(50)) + 's';
		PRINT '------------------------------------';


		SET @start_time = GETDATE();
		PRINT '-->Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;
		PRINT '-->Inserting Data into: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'Load Duration:bronze.erp_loc_a101 ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(50)) + 's';
		PRINT '------------------------------------';


		SET @start_time = GETDATE();
		PRINT '-->Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		PRINT '-->Inserting Data into: bronze.erp_px_cat_g1v2'
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'Load Duration:bronze.erp_px_cat_g1v2 ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(50)) + 's';
		PRINT '------------------------------------';

		SET @batch_end_time = GETDATE();
		PRINT 'Load Duration:Bronze Layer ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(50)) + 's';
		PRINT '------------------------------------';

	END TRY
	
	BEGIN CATCH
		PRINT '=============================';
		PRINT 'Error Occured During Loading';
		PRINT '=============================';
		PRINT 'Error Message' + CAST(ERROR_MESSAGE() AS NVARCHAR(50));
		PRINT 'Error Number' + CAST(ERROR_NUMBER() AS NVARCHAR(50));
	END CATCH
END;
