/*
===============================================================================
Stored Procedure: bronze.load_bronze
===============================================================================

Purpose:
    Performs a full load of the Bronze Layer.

Process:
    1. Truncates each Bronze table.
    2. Loads fresh data from the source CSV files using BULK INSERT.
    3. Skips the CSV header row.
    4. Uses comma as the field delimiter.
    5. Records the loading duration for each table.
    6. Records the total Bronze Layer loading duration.
    7. Captures and reports errors that occur during the loading process.

Source Data:
    CRM files  -> datasets/source_crm/
    ERP files  -> datasets/source_erp/

Project Directory:
    C:\SQLProject\

===============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN

    -- Variables used to track individual table loading times
    DECLARE @start_time AS DATETIME,
            @end_time AS DATETIME;

    -- Variables used to track the total Bronze Layer loading time
    DECLARE @start_time_batch AS DATETIME = GETDATE(),
            @end_time_batch AS DATETIME;

    BEGIN TRY

        PRINT('===============================================================');
        PRINT('        STARTING BRONZE LAYER FULL LOAD');
        PRINT('===============================================================');
        PRINT('Full Load >>> BULK INSERT to load data from source to Bronze Layer');


        /*=====================================================================
          CRM CUSTOMER INFORMATION
        =====================================================================*/

        PRINT('===============================================================');
        PRINT('Loading >>> [bronze].[crm_cust_info]');
        
        SET @start_time = GETDATE();

        -- Remove existing data before performing the full load
        TRUNCATE TABLE bronze.crm_cust_info;

        -- Load customer information from the CRM source file
        BULK INSERT bronze.crm_cust_info
        FROM 'C:\SQLProject\datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT(
            'Loading duration >> : '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds'
        );


        /*=====================================================================
          CRM PRODUCT INFORMATION
        =====================================================================*/

        PRINT('===============================================================');
        PRINT('Loading >>> [bronze].[crm_prd_info]');

        SET @start_time = GETDATE();

        -- Remove existing data before performing the full load
        TRUNCATE TABLE bronze.crm_prd_info;

        -- Load product information from the CRM source file
        BULK INSERT bronze.crm_prd_info
        FROM 'C:\SQLProject\datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT(
            'Loading duration >> : '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds'
        );


        /*=====================================================================
          CRM SALES DETAILS
        =====================================================================*/

        PRINT('===============================================================');
        PRINT('Loading >>> [bronze].[crm_sales_details]');

        SET @start_time = GETDATE();

        -- Remove existing data before performing the full load
        TRUNCATE TABLE bronze.crm_sales_details;

        -- Load sales transaction data from the CRM source file
        BULK INSERT bronze.crm_sales_details
        FROM 'C:\SQLProject\datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT(
            'Loading duration >> : '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds'
        );


        /*=====================================================================
          ERP CUSTOMER INFORMATION
        =====================================================================*/

        PRINT('===============================================================');
        PRINT('Loading >>> [bronze].[erp_cust_az12]');

        SET @start_time = GETDATE();

        -- Remove existing data before performing the full load
        TRUNCATE TABLE bronze.erp_cust_az12;

        -- Load customer information from the ERP source file
        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\SQLProject\datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT(
            'Loading duration >> : '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds'
        );


        /*=====================================================================
          ERP LOCATION INFORMATION
        =====================================================================*/

        PRINT('===============================================================');
        PRINT('Loading >>> [bronze].[erp_loc_a101]');

        SET @start_time = GETDATE();

        -- Remove existing data before performing the full load
        TRUNCATE TABLE bronze.erp_loc_a101;

        -- Load location information from the ERP source file
        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\SQLProject\datasets\source_erp\LOC_A101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT(
            'Loading duration >> : '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds'
        );


        /*=====================================================================
          ERP PRODUCT CATEGORY INFORMATION
        =====================================================================*/

        PRINT('===============================================================');
        PRINT('Loading >>> [bronze].[erp_px_cat_g1v2]');

        SET @start_time = GETDATE();

        -- Remove existing data before performing the full load
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        -- Load product category information from the ERP source file
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\SQLProject\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT(
            'Loading duration >> : '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds'
        );


        /*=====================================================================
          LOAD COMPLETED
        =====================================================================*/

        PRINT('===============================================================');
        PRINT('        BRONZE LAYER LOAD COMPLETED SUCCESSFULLY');
        PRINT('===============================================================');


    END TRY

    BEGIN CATCH

        /*=====================================================================
          ERROR HANDLING
        =====================================================================*/

        PRINT('===============================================================');
        PRINT('        ERROR OCCURRED DURING BRONZE LAYER LOADING');
        PRINT('===============================================================');

        PRINT(
            'ERROR MESSAGE >> '
            + ERROR_MESSAGE()
        );

        PRINT(
            'ERROR NUMBER >> '
            + CAST(ERROR_NUMBER() AS NVARCHAR(20))
        );

        PRINT(
            'ERROR STATE >> '
            + CAST(ERROR_STATE() AS NVARCHAR(20))
        );

        PRINT('===============================================================');

        -- Pass the error back to the calling process
        THROW;

    END CATCH;


    /*=====================================================================
      TOTAL BRONZE LAYER LOADING DURATION
    =====================================================================*/

    SET @end_time_batch = GETDATE();

    PRINT('===============================================================');
    PRINT('        TOTAL BRONZE LAYER LOADING DURATION');
    PRINT('===============================================================');

    PRINT(
        'Bronze Loading duration >> : '
        + CAST(
            DATEDIFF(SECOND, @start_time_batch, @end_time_batch)
            AS NVARCHAR(20)
        )
        + ' seconds'
    );

    PRINT('===============================================================');

END;
