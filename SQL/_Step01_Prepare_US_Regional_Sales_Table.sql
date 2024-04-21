/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [OrderNumber]
      ,[Sales_Channel]
      ,[WarehouseCode]
      ,[ProcuredDate]
      ,[OrderDate]
      ,[ShipDate]
      ,[DeliveryDate]
      ,[CurrencyCode]
      ,[SalesTeamID]
      ,[CustomerID]
      ,[StoreID]
      ,[ProductID]
      ,[Order_Quantity]
      ,[Discount_Applied]
      ,[Unit_Price]
      ,[Unit_Cost]
  FROM [MYANALYST].[dbo].US_REGIONAL_SALES_DATE
  ---------------------------------------------------------

 DROP TABLE IF EXISTS #COMPLETED_SALES_DATA;
 SELECT 
	 A.[OrderNumber]					AS ORDER_NUMBER
	,A.[Sales_Channel]					AS SALES_CHANNEL
	,A.[WarehouseCode]					AS WAREHOUSE_CODE
	,A.[ProcuredDate]					AS PROCURED_DATE
	,A.[OrderDate]						AS ORDER_DATE
	,A.[ShipDate]						AS SHIP_DATE
	,A.[DeliveryDate]					AS DELIVERY_DATE
	,A.[CurrencyCode]					AS CURRENCY_CODE
	--------------------------------------------------
	,A.[SalesTeamID]					AS SALES_TEAM_ID
	,B.Sales_Team						AS SALES_TEAM
	,B.Region							AS SALES_REGION
	--------------------------------------------------
	,A.[CustomerID]						AS CUSTOMER_ID
	,C.CUSTOMER_NAME					AS CUSTOMER_NAME
	--------------------------------------------------	
	,A.[StoreID]						AS STORE_ID
	,D.AreaCode							AS AREA_CODE
	,D.City_Name						AS CITY_NAME
	,D.County							AS COUNTRY
	,D.State							AS STATE
	,D.StateCode						AS STATECODE
	,D.Type								AS TYPE
	,D.Household_Income					AS AREA_HOUSEHOLD_INCOME
	,D.Median_Income					AS MEDIAN_INCOME
	,D.Population						AS POPULATION
	,D.Latitude							AS LATITUDE
	,D.Longitude						AS LONGTITUDE
	,D.Land_Area						AS LAND_AREA
	,D.Water_Area						AS WATER_AREA
	,D.Time_Zone						AS TIME_ZONE
	---------------------------------------------------
	,A.[ProductID]						AS PRODUCT_ID
	,E.Product_Name						AS PRODUCT_NAME
	,A.[Order_Quantity]					AS ORDER_QUANTITY
	,A.[Discount_Applied]				AS DISCOUNT_APPIED_RATIO
	,A.[Unit_Price]						AS UNIT_PRICE
	,A.[Unit_Cost]						AS UNIT_COST
	----------------------------------------------------
 INTO #COMPLETED_SALES_DATA
 FROM [MYANALYST].[dbo].[US_REGIONAL_SALES_DATE]		AS A
 LEFT JOIN [MYANALYST].[dbo].[SALES_TEAM_TABLE]			AS B
 ON A.SalesTeamID = B.SalesTeamID
 LEFT JOIN [MYANALYST].[dbo].[CUSTOMER_RFM_SCORE]		AS C
 ON A.CustomerID = C.CUSTOMER_ID
 LEFT JOIN [MYANALYST].[dbo].[STORE_LOCATIONS_TABLE]	AS D 
 ON A.StoreID = D.StoreID
 LEFT JOIN [MYANALYST].[dbo].[PRODUCT_TABLE]			AS E
 ON A.ProductID = E.ProductID

 DROP TABLE IF EXISTS  [MYANALYST].[dbo].[COMPLETED_SALES_DATA];
 SELECT * 
 INTO [MYANALYST].[dbo].[COMPLETED_SALES_DATA]
 FROM #COMPLETED_SALES_DATA



 SELECT YEAR(ORDER_DATE)
		,MONTH(ORDER_DATE)
		,PRODUCT_NAME
		,SUM(ORDER_QUANTITY) AS TOTAL_ORDER__QUANTITY
 FROM #COMPLETED_SALES_DATA
 GROUP BY YEAR(ORDER_DATE),MONTH(ORDER_DATE),	PRODUCT_NAME
 ORDER BY YEAR(ORDER_DATE),MONTH(ORDER_DATE),	TOTAL_ORDER__QUANTITY DESC

 SELECT ORDER_DATE,ORDER_NUMBER,ORDER_QUANTITY,SALES_TEAM, COUNT(1) FROM #COMPLETED_SALES_DATA
 GROUP BY ORDER_DATE,ORDER_NUMBER,ORDER_QUANTITY,SALES_TEAM
 HAVING COUNT(1) > 1