/*
======================
Create DB and Schemas
======================

Script: 
-Create new DB 'DataWarehouse_Project1' after cheking if it exists already. 
-If the script exists; It is dropped and re-created.
-There is a 3 schema set-up : 'bronze', 'silver', 'gold'

Please Note: 
-Running the entire script will delete the 'DataWarehouse_Project1', if it is already existing. 
-All the data in the DB will be permanently deleted.
-Ensure you have backups. 

To avoid the above proceed from 'line 30'

*/
USE master;
GO

--To Drop and Re-create the 'DataWarehouse_Project1' database
IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse_Project1')
BEGIN
  ALTER DATABASE DataWarehouse_Project1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE DataWarehouse_Project1;
END;
GO

-- Create the Database
CREATE DATABASE DataWarehouse_Project1;
GO
  
USE DataWarehouse_Project1;
GO

--Create Schema
CREATE SCHEMA bronze;
GO
  
CREATE SCHEMA silver;
GO
  
CREATE SCHEMA gold;
GO
