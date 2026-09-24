/*

==========================================================================================
 Create Database and Schemas
 =========================================================================================
 scrip purpose:
	This script creates a new database named 'DataWarehouse'

	Additionally, the script create three schemas within the database: 'bronze','silber', and 'gold'.

	*/




-- Creating  Database  "DataWarehouse"
USE master;
GO
CREATE DATABASE DataWarehouse;
GO
USE DataWarehouse;
GO

-- Creating the schemas

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO