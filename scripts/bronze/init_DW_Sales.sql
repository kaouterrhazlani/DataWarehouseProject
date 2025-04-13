/*===============================================
Create database and schemas
=================================================
Script purpose : 
	-This script check if 'DW_Sales' database exists then drop it ,after 
	it recreate 'DW_Sales' Database.
	-This script create schemas for each layer ; bronze , silver and gold.

WARNING:
	-Attention: running this script will drop the entire 'DW_Sales'
	Database if exists.
	-Make sure that you have proper backups before running this script.
*/
USE master;
GO
-- check if database exists and drop it if exists before creating 
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DW_Sales')
BEGIN
	ALTER DATABASE DW_Sales SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DW_Sales;
END
-- create database
CREATE DATABASE DW_Sales; 
GO


USE DW_Sales;
GO
--create schema for bronze layer 
CREATE SCHEMA bronze;
GO
--create schema for silver layer 
CREATE SCHEMA silver;
GO
--create schema for gold layer 
CREATE SCHEMA gold;
GO




