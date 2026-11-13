/*
----------------------------
      Quality Checks
----------------------------
1)Purpose: 
-> This script performs various cheks for data consistency, accuracy and standardization across the silver schemas. 
-> checks include: 
    -> NULLs or duplicates
    -> Unwanted spaces
    -> Data Standardization and consistency
    -> invalid date ranges and orders
2)Usage: 
-> Run these checks after loading silver layer. 
-> Investigate and resolve any descripencies found during the checks. 
*/
/*
-------------------------------------
Checking silver.crm_cust_info
-------------------------------------
*/
--Checking: cst_id for NULLs or Duplicatates for the PK
SELECT 
cst_id, 
COUNT(*) 
FROM silver.crm_cust_info 
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL
  
--Checking: cst_firstname & cst_lastname for unwanted spaces
--Expectation: No Results
SELECT 
cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)


--Checking: cst_gendr 
-- Data Normalizing
SELECT 
CASE 
	WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	ELSE 'N/A'
END cst_gndr
FROM silver.crm_cust_info

/*
-------------------------------------
Checking silver.crm_prd_info
-------------------------------------
*/
--Checking: prd_id (PK)
--Nulls and Duplicates
SELECT 
prd_id,
COUNT(*) AS FLAGGED
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING prd_id IS NULL OR COUNT(*) > 1


--Checking: prd_key
--Data Clean-up: Initial 5 characters are unique to erp_px_cat_g1v2
--Derived Columns
SELECT
TOP 100 *,
REPLACE(SUBSTRING(prd_key,1,5), '-','_') AS cat_id
FROM silver.crm_prd_info

  
--Checking: prd_key
--Split prd_key after the first 5 characters.
--The 2nd half of the split key is matching with sls_prd_key
SELECT 
SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key
FROM silver.crm_prd_info

--Check: prd_name
--Check if there are any spaces 
SELECT
prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

--Checking: prd_cost
--Check for NULL or Negative Values
SELECT *, 
ISNULL(prd_cost, 0) as prd_cost
FROM silver.crm_prd_info
where prd_cost IS NULL OR prd_cost < 0

--Check: prd_line
--Check Possible values
SELECT DISTINCT prd_line
FROM silver.crm_prd_info

/*
-------------------------------------
Checking silver.crm_sales_details
-------------------------------------
*/
  
--Checking: sls_old_num
--Check for NULLS and Spaces
SELECT 
TRIM(sls_ord_num)
FROM silver.crm_sales_details
WHERE TRIM(sls_ord_num) !=  sls_ord_num OR sls_ord_num IS NULL  

--Checking: sls_prd_key (this is the key shared with crm_prd_info)
SELECT 
sls_prd_key
FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info) 


--Checking: sls_cust_id
--To check if the key values match crm_cust_info, crm_sales_details 
SELECT 
sls_cust_id
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info)


--Checking: sls_order_dt
--Check for 0s, Negative dates
SELECT 
sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt <= 0 OR LEN(sls_order_dt) < 8

--Checking: sls_ship_date, sls_due_date
--Date irregularities: Overlapping of dates, missing start date, unrealistic dates
SELECT 
NULLIF (sls_ship_dt, 0) AS sls_ship_dt 
FROM silver.crm_sales_details
WHERE sls_ship_dt <= 0 
	  OR LEN(sls_ship_dt) != 8 
	  OR sls_ship_dt > 20500101 
	  OR sls_ship_dt < 19000101

--Checking: sls_sales, Quantity , price
--NOTE: Sales = quantity * price
--Check negative numbers, NULLS, 0s
SELECT 
	sls_sales,
	sls_quantity,
	sls_price
FROM silver.crm_sales_details
WHERE sls_sales != (sls_quantity * sls_price) 
	  OR sls_sales IS NULL 
	  OR sls_quantity IS NULL 
	  OR sls_price IS NULL 
	  OR sls_sales < 0
	  OR sls_quantity < 0
	  OR sls_price <0
ORDER BY sls_sales, sls_quantity, sls_price

/*
-------------------------------------
Checking silver.erp_cust_az12
-------------------------------------
*/
--Checking: bdate
--Check for really old or young customer age.
SELECT 
bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()
ORDER BY bdate ASC

--Checking: Gen
--Missing values or abbreviations
SELECT
cid,
gen
FROM silver.erp_cust_az12
WHERE gen NOT IN ('Male', 'Female')

/*
-------------------------------------
Checking silver.erp_loc_a101
-------------------------------------
*/

--Checking:cid
--cid will connect with crm_cust_info [cst_key]
--Remove the dash 
--Check with silver.crm_cust_info cst_key
SELECT 
cid
FROM silver.erp_loc_a101
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info)

--Checking: cntry
--Get all possible values 
SELECT DISTINCT cntry FROM silver.erp_loc_a101

/*
-------------------------------------
Checking silver.erp_px_cat_g1v2
-------------------------------------
*/
--Check:id  erp_px_cat_g1v2
SELECT 
id
FROM silver.erp_px_cat_g1v2
WHERE id NOT IN (SELECT cat_id from silver.crm_prd_info)

--Check:cat, subcategory, maintenence for unwanted spaces 
SELECT * 
FROM silver.erp_px_cat_g1v2
WHERE TRIM(cat) != cat OR TRIM(subcat) != subcat OR TRIM(maintenence) != maintenence 


--Check: Distinct values for cat, subcat and maintenence
SELECT DISTINCT maintenence FROM silver.erp_px_cat_g1v2


