

CREATE OR ALTER PROCEDURE silver.load_silver AS

BEGIN
     DECLARE @start_time DATETIME = GETDATE(), @end_time DATETIME;
	BEGIN TRY

	PRINT('Loading clean data into silver.crm_cust_info')
	PRINT ('=============================================================')
	TRUNCATE TABLE silver.crm_cust_info
	INSERT INTO silver.crm_cust_info(
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date)

	SELECT
	cst_id,
	cst_key,
	TRIM(cst_firstname), --Removed unwanted spaces to ensure data consistency
	TRIM(cst_lastname),
	CASE UPPER(TRIM(cst_marital_status)) -- Normalize/standardize marital status values to a readable format ( user friendly description")
		WHEN 'M' THEN 'Married'
		WHEN 'S' THEN 'Single'
		ELSE 'n/a'						--- Hanlding missing data by adding a default valaue
	END AS cst_marital_status,

	CASE UPPER(TRIM(cst_gndr)) -- Normalize gender values to readable format
		WHEN 'F' THEN 'Female'
		WHEN 'M' THEN 'Male'
		ELSE 'Unkown'
	END AS cst_gndr,
	cst_create_date

	FROM (
		SELECT*,
			ROW_NUMBER ()
				OVER( PARTITION BY cst_id ORDER BY cst_create_date DESC) AS RN
		FROM bronze.crm_cust_info) AS t
	WHERE
		rn = 1 --- Removed Duplicates to ensure only one record per entity by identifying and retaining the most recent row


	PRINT ('=============================================================')	
	PRINT('Loading clean data into silver.crm_prd_info')
	PRINT ('=============================================================')
	TRUNCATE TABLE silver.crm_prd_info;
	INSERT INTO silver.crm_prd_info (
		prd_id,
		cat_id,
		prd_key,
		prd_nm, 
		prd_cost,
		prd_line, 
		prd_start_dt,
		prd_end_dt 
	)
	SELECT
		prd_id,
		REPLACE(LEFT(prd_key,5),'-','_') AS cat_id,  -- Derived new Column based on calculations or transformation of existing ones.
		SUBSTRING(prd_key,7,len(prd_key)) AS prd_key,
		prd_nm,
		COALESCE(prd_cost,0) AS prd_cost , 
		CASE UPPER(TRIM(prd_line))
			WHEN 'M' THEN 'Mountain'
			WHEN 'R' THEN 'Road'
			WHEN 'S' THEN 'Other Sales'
			WHEN 'T' THEN 'Touring'
			ELSE 'n/a'
		END AS prd_line,
		prd_start_dt,
		DATEADD(DAY,-1,LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt  -- Data Enrichment -Adding value to Data to enchance the Datatset for Analyis
	FROM bronze.crm_prd_info


	PRINT ('=============================================================')	
	PRINT('Loading clean data into silver.crm_sales_details')
	PRINT ('=============================================================')

	TRUNCATE TABLE silver.crm_sales_details;
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
			WHEN sls_order_dt =0 OR len(sls_order_dt) != 8
			THEN NULL 
			ELSE CAST( sls_order_dt AS DATE)
		END AS sls_order_dt,
		CASE
			WHEN sls_ship_dt =0 OR len(sls_ship_dt) != 8
			THEN NULL 
			ELSE CAST( sls_ship_dt AS DATE)
		END AS sls_ship_dt,
		CASE
			WHEN sls_due_dt =0 OR len(sls_due_dt) != 8
			THEN NULL 
		ELSE CAST( sls_due_dt AS DATE)
		END AS sls_due_dt,

		CASE
			WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity*ABS(sls_price)
			THEN sls_quantity*ABS(sls_price)
			ELSE sls_sales
		END AS sls_sales,
		sls_quantity,

		CASE 
			WHEN (sls_price IS NULL)  OR (sls_price <= 0)
			THEN CAST(sls_sales/sls_quantity AS decimal)
			ELSE sls_price
		END AS sls_price

	FROM bronze.crm_sales_details


	PRINT ('=============================================================')	
	PRINT('Loading clean data into silver.erp_cust_az12')
	PRINT ('=============================================================')

	TRUNCATE TABLE
		silver.erp_cust_az12;
	INSERT INTO silver.erp_cust_az12 (
		cid,
		bdate,
		gen
	)

	SELECT 
		REPLACE(cid,'NAS','') AS cid,
		CASE
			WHEN bdate > GETDATE() THEN NULL
			ELSE bdate
		END AS bdate,
	  CASE 
		WHEN TRIM(UPPER(gen)) IN ('F','FEMALE') THEN 'Female'
		WHEN TRIM(UPPER(gen)) IN ('M','MALE') THEN 'Male'
		ELSE NULL
		END AS  gen
	  FROM DataWarehouse.bronze.erp_cust_az12



	PRINT ('=============================================================')	
	PRINT('Loading clean data into silver.erp_loc_a101')
	PRINT ('=============================================================')

	TRUNCATE TABLE
		silver.erp_loc_a101;
	INSERT INTO silver.erp_loc_a101 (
		cid,
		cntry)
	SELECT
		REPLACE(cid,'-','') AS cid,  --- handled invalid values
		CASE 
			WHEN UPPER(TRIM(cntry)) IN ('DE','GERMANY') THEN 'Germany'
			WHEN UPPER(TRIM(cntry)) IN ('USA','US','UNITED STATES') THEN 'United States'
			WHEN UPPER(TRIM(cntry)) IN ('AUSTRALIA') THEN 'Australia'
			WHEN UPPER(TRIM(cntry)) IN ('UNITED KINGDOM') THEN 'United Kingdom'
			WHEN UPPER(TRIM(cntry)) IN ('CANADA') THEN 'Canada'
			WHEN UPPER(TRIM(cntry)) IN ('FRANCE') THEN 'France'
			ELSE 'n/a'
		END cntry --- Data normalization/standardization as wel as handling missing values
	FROM bronze.erp_loc_a101


	PRINT ('=============================================================')	
	PRINT('Loading clean data into silver.erp_px_cat_g1v2')
	PRINT ('=============================================================')

	TRUNCATE TABLE silver.erp_px_cat_g1v2;
	INSERT INTO silver.erp_px_cat_g1v2
	(
		cid,
		cat,
		subcat,
		maintenance
	)

	SELECT 
		cid,
		cat,
		subcat,
		maintenance
	  FROM DataWarehouse.bronze.erp_px_cat_g1v2



	 END TRY
	 BEGIN CATCH
	 	PRINT('=========================================================')
		PRINT ('ERROR OCCURED DURING LOADING silver LAYER')
		PRINT('ERROR '+ ERROR_MESSAGE())
		PRINT('ERROR '+ CAST(ERROR_NUMBER() AS NVARCHAR))
		PRINT('ERROR '+ ERROR_STATE())
		PRINT('=========================================================')
	END CATCH

	 SET @end_time = GETDATE();
	 PRINT('========================>>>> TOTAL LOADING DURATION SILVER LAYER <<<<<===============')
	 PRINT('loading duration >>> ' + CAST( DATEDIFF(SECOND,@start_time,@end_time) AS VARCHAR) + ' seconds <<<<')
END 

