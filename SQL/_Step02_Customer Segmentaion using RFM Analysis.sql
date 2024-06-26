USE MYANALYST;

/*
PURPOSE : 
-	PERFORM RFM (RECENCY, FREQUENCY, MONETARY) ANALYSIS ON CUSTOMERS 
	TO SEGMENT CUSTOMERS BASED ON THIER BEHAVIOR AND VALUE TO THE BUSINESS. 

	INPUT TABLE FROM DATA_WAREHOUSE
	(1) [MYANALYST].[dbo].[CUSTOMER_TABLE]
	(2) [MYANALYST].[dbo].[US_REGIONAL_SALES_DATE]
	OUTPUT TABLE 
	(3) [MYANALYST].[DBO].[CUSTOMER_RFM_SCORE]

STEPS :
(1) EXPLORE TABLES 
(2) CREATE STAGING CUSTOMER-LEVEL TABLE [TEMPORARY TABLE]
(3) CALCULATE RFM SCORE USING CTEs
(4) SELECT STAGING CUSTOMER-LEVEL TABLE INTO [PERMANENT TABLE] 
*/


/* (1) EXPLORE TABLE */

SELECT TOP(5) * FROM [MYANALYST].[dbo].[CUSTOMER_TABLE];

SELECT
	 MAX(OrderDate)	AS MAX_ORDER_DATE
	,MIN(OrderDate)	AS MIN_ORDER_DATE
FROM [MYANALYST].[dbo].[US_REGIONAL_SALES_DATE];
--RESULT : 
--MAX_ORDER_DATE = 2020-12-30
--MIN_ORDER_DATE = 2018-05-31

/* (2) CREATE STAGING CUSTOMER-LEVEL TABLE [TEMPORARY TABLE] */
DROP TABLE IF EXISTS #STAGING_CUSTOMER_LV;
GO
SELECT 
	 CUSTOMERID				AS CUSTOMER_ID	
	,CUSTOMER_NAMES				AS CUSTOMER_NAME
	,CAST(NULL AS DATE)			AS FIRST_PURCHASE_DATE 		
	-- RECENCY VALUE	| HOW RECENTY A CUSTOMER HAS MADE A PURCHASE,	
	,CAST(NULL AS DATE)			AS MOST_RECENTLY_PURCHASE_DATE 		
	,CAST(NULL AS INT)			AS NO_OF_DAY_LAST_PURCHASE 	
	-- FEQUENCY VALUE	| HOW OFTEN A CUSTOMER MAKES A PURCHASE.
	,CAST(NULL AS INT)			AS NO_OF_TRANSACTION
	-- MONETARY VALUE	| HOW MUCH MONEY A CUSTOMER SPENDS ON PURCHASES.
	,CAST(NULL AS INT)			AS AVG_NET_REVENUE_PER_TRANSACTION
	,CAST(NULL AS INT)			AS REVENUE 
	,CAST(NULL AS INT)			AS RECENCY_SCORE
	,CAST(NULL AS INT)			AS FREQUENCY_SCORE
	,CAST(NULL AS INT)			AS MONETARY_SCORE
INTO #STAGING_CUSTOMER_LV
FROM [MYANALYST].[dbo].[CUSTOMER_TABLE];

/* (3) CALCULATE RFM SCORE USING CTEs */
---------------------------------------------------
-- SINCE IT IS OLD DATA SETS -> SO I WILL ASSUME THAT TODAY IS  '2021-01-01' (THE DAY AFTER MAX_ORDER_DATE)
DECLARE @TODAY_DATE AS DATE;
SET @TODAY_DATE = (SELECT DATEADD(DAY,1,MAX(OrderDate)) AS MAX_ORDER_DATE FROM [MYANALYST].[dbo].[US_REGIONAL_SALES_DATE]);
WITH CALCULATE_RFM_VALUE AS 
	(
		SELECT 
			CUSTOMERID														AS CUSTOMER_ID
			,MAX(ORDERDATE)														AS MOST_RECENTLY_PURCHASE_DATE
			,DATEDIFF(DAY,MAX(ORDERDATE),@TODAY_DATE)										AS NO_OF_DAY_LAST_PURCHASE
			,COUNT(DISTINCT ORDERNUMBER)												AS NO_OF_TRANSACTION
			,CAST(AVG((UNIT_PRICE*(1-DISCOUNT_APPLIED))*Order_Quantity) AS DECIMAL(16,2))						AS AVG_NET_REVENUE_PER_TRANSACTION
			,CAST(SUM(((UNIT_PRICE*(1-DISCOUNT_APPLIED))*Order_Quantity)) AS DECIMAL(16,2))						AS REVENUE
			,MIN(ORDERDATE)														AS FIRST_PURCHASE_DATE
		FROM 
			[MYANALYST].[dbo].[US_REGIONAL_SALES_DATE]
		WHERE YEAR(ORDERDATE) = 2020
		GROUP BY 
			CUSTOMERID
	),	
	CALCULATE_RFM_SCORE AS 
	(
		SELECT 
			CUSTOMER_ID
			,NO_OF_DAY_LAST_PURCHASE
			,NO_OF_TRANSACTION
			,AVG_NET_REVENUE_PER_TRANSACTION
			,NTILE(5) OVER(ORDER BY NO_OF_DAY_LAST_PURCHASE DESC)									AS RECENCY_SCORE
			,NTILE(5) OVER(ORDER BY NO_OF_TRANSACTION ASC)										AS FREQUENCY_SCORE
			,NTILE(5) OVER(ORDER BY AVG_NET_REVENUE_PER_TRANSACTION ASC)								AS MONETARY_SCORE
		FROM 
			CALCULATE_RFM_VALUE
	 )
UPDATE 
	#STAGING_CUSTOMER_LV
SET FIRST_PURCHASE_DATE				= B.FIRST_PURCHASE_DATE
	,MOST_RECENTLY_PURCHASE_DATE		= B.MOST_RECENTLY_PURCHASE_DATE
	,NO_OF_DAY_LAST_PURCHASE		= B.NO_OF_DAY_LAST_PURCHASE
	,NO_OF_TRANSACTION			= B.NO_OF_TRANSACTION
	,AVG_NET_REVENUE_PER_TRANSACTION	= B.AVG_NET_REVENUE_PER_TRANSACTION
	,REVENUE				= B.REVENUE
	,RECENCY_SCORE				= C.RECENCY_SCORE
	,FREQUENCY_SCORE			= C.FREQUENCY_SCORE
	,MONETARY_SCORE				= C.MONETARY_SCORE
FROM #STAGING_CUSTOMER_LV			AS A
INNER JOIN [CALCULATE_RFM_VALUE]		AS B
ON	A.CUSTOMER_ID = B.CUSTOMER_ID
INNER JOIN [CALCULATE_RFM_SCORE]		AS C
ON	A.CUSTOMER_ID = C.CUSTOMER_ID
;
/* (4) SELECT STAGING CUSTOMER-LEVEL TABLE INTO [PERMANENT TABLE] */ 
DROP TABLE IF EXISTS [MYANALYST].[DBO].[CUSTOMER_RFM_SCORE];
SELECT *,CONCAT_WS('-',RECENCY_SCORE,FREQUENCY_SCORE,MONETARY_SCORE) AS R_F_M_SCORE	
INTO [MYANALYST].[DBO].[CUSTOMER_RFM_SCORE]
FROM #STAGING_CUSTOMER_LV

SELECT * FROM [MYANALYST].[DBO].[CUSTOMER_RFM_SCORE]
ORDER BY RECENCY_SCORE DESC ,FREQUENCY_SCORE DESC, MONETARY_SCORE DESC 
