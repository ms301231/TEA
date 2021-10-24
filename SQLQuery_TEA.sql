/* ------- Shawn Mathew -------*/
/* Total time breakdown: 
Initially spent ~ 30 minutes to understand logical structure of database
Q1: 15 minutes
Q2: 30 minutes
Q3: 30 minutes
Q4: 45 minutes
Total Time: ~ 2.5 hours
*/

use WideWorldImporters;

/* Question 1: The leadership team has asked us to graph total monthly sales over time. Write a query that returns the data we need to complete this request. */

-- we use the Sales.CustomerTransactions table to answer this question as it has both unique customer transactionID's and also has transactiondate/finalization date.
-- We use FinalizationDate because it is the finalization of a transaction and revenue only comes from complete transactions. Additionally, we use the field AmountExcludingTax
-- as revenue is non inclusive of tax. This also shows us that there is $232,583.95 that is still payable.

SELECT sum(AmountExcludingTax) as TotalRevenue, 
	   month(FinalizationDate) as Month, 
	   year(FinalizationDate) as Year
       --[CustomerTransactionID],
  
FROM [WideWorldImporters].[Sales].[CustomerTransactions] as ct
GROUP BY FinalizationDate
ORDER BY FinalizationDate;


/* Question 2: What is the fastest growing customer category in Q1 2016 (compared to same quarter sales in the previous year)? What is the growth rate? */
/* Answer : Category 3 is the fastest growing customer category, with a growth rate of 45.54%, comparing Q1 from 2015 to 2016 respectively. */
/* FY Q1 2016 = nov 2015 --> jan 2016 */
SELECT sum(ct.AmountExcludingTax) as TotalRevenue
      ,ca.[CustomerCategoryID]
	  ,'FY2016' as FY
FROM [WideWorldImporters].[Sales].[Customers_Archive] as ca
inner join [WideWorldImporters].[Sales].[CustomerTransactions] as ct
ON ca.CustomerID = ct.CustomerID
WHERE ct.FinalizationDate BETWEEN '2015-11-01' AND '2016-01-31'
GROUP BY ca.[CustomerCategoryID] --,month(ct.FinalizationDate) , year(ct.FinalizationDate)
ORDER BY sum(ct.AmountExcludingTax) desc;
/* Query Result FY 2016
TotalRevenue	CustomerCategoryID	FY
268719.30	4	FY2016
241882.50	3	FY2016
192633.65	5	FY2016
181950.95	7	FY2016
145175.20	6	FY2016
*/
-- UNION ALL
/* FY Q1 2015 = nov 2014 --> jan 2015 */
SELECT sum(ct.AmountExcludingTax) as TotalRevenue
      ,ca.[CustomerCategoryID]
	  ,'FY2015' as FY
FROM [WideWorldImporters].[Sales].[Customers_Archive] as ca
inner join [WideWorldImporters].[Sales].[CustomerTransactions] as ct
ON ca.CustomerID = ct.CustomerID
WHERE ct.FinalizationDate BETWEEN '2014-11-01' AND '2015-01-31'
GROUP BY ca.[CustomerCategoryID] --,month(ct.FinalizationDate) , year(ct.FinalizationDate)
ORDER BY sum(ct.AmountExcludingTax) desc;
/* Query Result FY 2015
TotalRevenue	CustomerCategoryID	FY
283393.25	5	FY2015
209529.20	4	FY2015
166196.00	3	FY2015
130681.70	6	FY2015
126822.15	7	FY2015

(4) 268719.30 to 209529.20 = 28.24 % Increase
(3) 241882.50 to 166196.00 = 45.54 % Increase
(5) 192633.65 to 283393.25 = 32.03 % Decrease
(7) 181950.95 to 126822.15 = 43.47 % Increase
(6) 145175.20 to 130681.70 = 11.09 % Increase
*/


/* Question 3: Write a query to return the list of suppliers that WWI has purchased from, 
along with # of invoices paid,# of invoices still outstanding, and average invoice amount.
*/

SELECT
	[SupplierID],
    COUNT(CASE WHEN st.[IsFinalized] = '1' THEN 1 END) AS InvoiceNumberFinished,
	COUNT(CASE WHEN st.[IsFinalized] != '1' THEN 1 END) AS InvoiceNumberUnfinished,
	AVG([TransactionAmount]) AS AvgInvoiceAmnt

FROM [WideWorldImporters].[Purchasing].[SupplierTransactions] as st
WHERE st.SupplierInvoiceNumber is not null -- Invoices should have invoice number
GROUP BY [SupplierID] ;


/* Question 4: Considering sales volume, which item in the warehouse has the lowest gross profit amount? 
Which item has the highest? What is the median gross profit across all items in the warehouse? */
/* Answers: 
	1) Item with lowest = StockItemID: 145
	2) Item with highest = StockItemID: 161
	3) Median Gross Profit = $136,485.00

*/

  SELECT TOP 1 [StockItemID]
      ,[Description]
      ,sum([LineProfit]) as GrossProfit
  FROM [WideWorldImporters].[Sales].[InvoiceLines]
  GROUP BY [StockItemID],[Description]
  ORDER BY sum([LineProfit]) ASC;

--StockItemID	Description	GrossProfit
--145	Halloween zombie mask (Light Brown) XL	-72372.00

  SELECT TOP 1 [StockItemID]
      ,[Description]
      ,sum([LineProfit]) as GrossProfit
  FROM [WideWorldImporters].[Sales].[InvoiceLines]
  GROUP BY [StockItemID],[Description]
  ORDER BY sum([LineProfit]) DESC;

--  StockItemID	Description	GrossProfit
--161	20 mm Double sided bubble wrap 50m	5293680.00

drop table if exists #tempTable; -- Refresh temp table

SELECT [StockItemID], [Description] ,sum([LineProfit]) as GrossProfit
into #tempTable
FROM [WideWorldImporters].[Sales].[InvoiceLines]
GROUP BY [StockItemID], [Description]
ORDER BY sum([LineProfit]) ASC

SELECT x.StockItemID, x.[Description], x.GrossProfit as MedianGrossProfit
FROM   (SELECT GrossProfit, StockItemID, [Description],
               Count(1) OVER (partition BY '')        AS TotalRows, 
               Row_number() OVER (ORDER BY GrossProfit ASC) AS RowIndex 
        FROM   #tempTable tt) x 
WHERE  x.RowIndex = Round(x.TotalRows / 2.0, 0);

--StockItemID	Description	MedianGrossProfit
--212	Large  replacement blades 18mm	136485.00
