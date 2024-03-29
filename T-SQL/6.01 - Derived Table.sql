﻿
USE Test_DB;
GO

/*
JOIN
.شرکت‌هایی که بیش از 10 سفارش داشته‌اند
*/
SELECT
	C.CompanyName,
	COUNT(O.OrderID) AS Num
FROM dbo.Customers AS C
JOIN dbo.Orders AS O
	ON C.CustomerID = O.CustomerID
GROUP BY C.CompanyName
	HAVING COUNT(O.OrderID) > 10;
GO

/*
WHERE در بخش Subquery نوشتن کوئری بالا با استفاده از

کوئری بیرونی SELECT به‌دلیل این‌که در بخش
قرار است از هر دو جدول فیلدی خوانده شود
.کوئری بیرونی نوشت WHERE را در بخش Subquery پس نمی‌توان
توجه داشته باش که می‌خواهیم این کوئری صرفا
.نوشته شود Subquery با یک
*/

/*
SELECT در بخش Subquery استفاده از

:در این‌جا می‌توان با 2 استراتژی به‌ استقبال مساله رفت

1) Subquery ارسال بخشی از رکوردها به
2) Subquery ارسال تمامی رکوردها به
*/

/*
استراتژی 1

Outer Query: Orders
Subquery: Customers

.شرکت‌هایی که بیش از 10 سفارش داشته‌اند
*/
SELECT
	(SELECT C.CompanyName FROM dbo.Customers AS C
		WHERE C.CustomerID = O.CustomerID) AS CompanyName,
	COUNT(O.OrderID) AS Num
FROM dbo.Orders AS O
GROUP BY O.CustomerID
	HAVING COUNT(O.OrderID) > 10;
GO


/*
استراتژی 2

Outer Query: Customers
Subquery: Orders

.شرکت‌هایی که بیش از 10 سفارش داشته‌اند
*/
SELECT
	C.CompanyName,
	(SELECT COUNT(O.OrderID) FROM dbo.Orders AS O
		WHERE C.CustomerID = O.CustomerID
		HAVING COUNT(O.OrderID) > 10) AS Num
FROM dbo.Customers AS C;
GO

-- از استراتژی 2 WHERE در بخش Subquery عدم استفاده از نتایج
SELECT
	C.CompanyName,
	(SELECT COUNT(O.OrderID) FROM dbo.Orders AS O
		WHERE C.CustomerID = O.CustomerID) AS Num
FROM dbo.Customers AS C
	WHERE (SELECT COUNT(O.OrderID) FROM dbo.Orders AS O
			WHERE O.CustomerID = C.CustomerID) > 10;
GO
--------------------------------------------------------------------

/*
Derived Table
*/

-- Derived Table رفع مشکل استراتژی 2 با استفاده از 
SELECT * FROM
(SELECT
	C.CompanyName,
	(SELECT COUNT(O.OrderID) FROM dbo.Orders AS O
		WHERE C.CustomerID = O.CustomerID
		HAVING COUNT(O.OrderID) > 10) AS Num
FROM dbo.Customers AS C) AS Tmp
	WHERE Tmp.Num IS NOT NULL;
GO

-- Derived Table رفع مشکل استراتژی 2 با استفاده از 
SELECT * FROM
(SELECT
	C.CompanyName,
	(SELECT COUNT(O.OrderID) FROM dbo.Orders AS O
		WHERE C.CustomerID = O.CustomerID
		HAVING COUNT(O.OrderID) > 10) AS Num
FROM dbo.Customers AS C) AS Tmp
	WHERE Tmp.Num > 10;
GO
--------------------------------------------------------------------

/*
Table Expression بررسی الزامات سه‌گانه در تمامی انواع
*/

/*
1) ORDER BY
Derrive Table در ORDER BY عدم استفاده از
*/

SELECT * FROM 
	(SELECT
		CustOmerID, CompanyName
	 FROM dbo.Customers
		WHERE State = N'تهران'
	 ORDER BY CustomerID) AS Tmp;  -- .زیرا ماهیت نتایج در مدل رابطه‌ای، عدم تضمین مرتب سازی است
GO

/*
2) Assign Name
.می‌بایست دارای نام باشند Derived Table تمامی فیلدهای
*/

SELECT * FROM
	(SELECT
		CustomerID, CompanyName + N'- تهران' --AS CompName
	 FROM dbo.Customers
		WHERE State = N'تهران') AS Tmp;
GO

/*
3) Unique Column Name
.می‌بایست دارای نام منحصر به‌فرد باشند Derived Table تمامی فیلدهای
*/

SELECT * FROM
	(SELECT
		C.CustomerID, O.CustomerID --AS O_CustomerID
	 FROM dbo.Orders AS O
	 JOIN dbo.Customers AS C
		ON C.CustomerID = O.CustomerID) AS Tmp;
GO
--------------------------------------------------------------------

/*
کوئری‌ای بنویسید که مشخص کند کدام مشتری 
در هر فاکتور بیش از 5 مورد کالا سفارش داده است؟
*/

-- JOIN
SELECT
	DISTINCT O.CustomerID,
	COUNT(O.OrderID)
FROM dbo.Orders AS O
JOIN dbo.OrderDetails AS OD
	ON O.OrderID = OD.OrderID
GROUP BY O.CustomerID, O.OrderID
	HAVING COUNT(O.OrderID) > 5;
GO

/*
Subquery استراتژی ارسال بخشی از رکوردها به

Outer Query: OrderDetails
Subquery: Orders
*/
SELECT
	DISTINCT COUNT(OD.OrderID) AS Num,
	(SELECT O.CustomerID FROM dbo.Orders AS O
		WHERE O.OrderID = OD.OrderID) AS CustomerID
FROM dbo.OrderDetails AS OD
GROUP BY OD.OrderID
	HAVING COUNT(OD.OrderID) > 5;
GO


/*
Subquery استراتژی ارسال تمامی رکوردها به

Outer Query: Orders
Subquery: OrderDetails
*/
SELECT
	O.CustomerID,
	(SELECT COUNT(OD.OrderID) FROM dbo.OrderDetails AS OD
		WHERE O.OrderID = OD.OrderID
		HAVING COUNT(OrderID) > 5) AS Num
FROM dbo.Orders AS O
GROUP BY O.CustomerID, O.OrderID;
GO

-- Derived Table (روش عادی)
SELECT Tmp.CustomerID, Tmp.Num FROM
(
SELECT
	O.CustomerID,
	(SELECT COUNT(OD.OrderID) FROM dbo.OrderDetails AS OD
		WHERE O.OrderID = OD.OrderID
		HAVING COUNT(OrderID) > 5) AS Num
FROM dbo.Orders AS O
GROUP BY O.CustomerID, O.OrderID
) AS Tmp
WHERE Tmp.Num IS NOT NULL
GROUP BY Tmp.CustomerID, Tmp.Num;
GO

-- Derived Table (روش هوشمندانه)
SELECT Tmp.CustomerID, Tmp.Num FROM
(
SELECT
	O.CustomerID,
	(SELECT COUNT(OD.OrderID) FROM dbo.OrderDetails AS OD
		WHERE O.OrderID = OD.OrderID) AS Num
FROM dbo.Orders AS O
GROUP BY O.CustomerID, O.OrderID
) AS Tmp
WHERE Tmp.Num > 5
GROUP BY Tmp.CustomerID, Tmp.Num;
GO

-- AdventureWorks2017 تاثیر کوئری‌هایی مشابه با کوئری‌های بالا در دیتابیس بزرگتری با عنوان
USE AdventureWorks2017;
GO

SELECT * FROM SALES.SalesOrderDetail; -- 121317 Records
SELECT * FROM SALES.SalesOrderHeader; -- 31465 Records
GO

-- Derived Table (روش عادی)
SELECT DISTINCT * FROM
(
	SELECT
	SOH.CustomerID,
	(SELECT COUNT(SOD.SalesOrderID) FROM Sales.SalesOrderDetail AS SOD
		WHERE SOH.SalesOrderID = SOD.SalesOrderID
		HAVING COUNT(SOD.SalesOrderID) > 5) AS Num
FROM Sales.SalesOrderHeader AS SOH) AS Tmp
	WHERE TMP.Num IS NOT NULL;
GO

-- Derived Table (روش هوشمندانه)
SELECT DISTINCT * FROM
(
	SELECT
	SOH.CustomerID,
	(SELECT COUNT(SOD.SalesOrderID) FROM Sales.SalesOrderDetail AS SOD
		WHERE SOH.SalesOrderID = SOD.SalesOrderID) AS Num
FROM Sales.SalesOrderHeader AS SOH) AS Tmp
	WHERE TMP.Num > 5;
GO

--------------------------------------------------------------------

/*
نکات تکمیلی
*/

-- تعداد مشتریان به‌تفکیک هر سال
SELECT
	YEAR(O.OrderDate) AS OrderYear,
	COUNT(DISTINCT O.CustomerID) AS Num
FROM dbo.Orders AS O -- .در کوئری‌های پیچیده نگهداری از نسخه‌های مختلف از اسامی مستعار، موجب عدم خوانایی و حتی گاهی خطا می‌شود
GROUP BY YEAR(OrderDate);
GO

-- Derived Table کوئری بالا با استفاده از
SELECT
	Tmp.OrderYear,
	COUNT(DISTINCT Tmp.CustomerID) AS Num
FROM
	(SELECT
		YEAR(OrderDate) AS OrderYear,
		CustomerID 
	 FROM dbo.Orders) AS Tmp
GROUP BY Tmp.OrderYear; 
GO

-- تو در تو Derived Table
SELECT
	DT2.OrderYear,
	DT2.Cust_Num
FROM (SELECT
		DT1.OrderYear,
		COUNT(DISTINCT DT1.CustomerID) AS Cust_Num
	  FROM (SELECT
				YEAR(OrderDate) AS OrderYear,
				CustomerID
			FROM dbo.Orders) AS DT1
			GROUP BY OrderYear) AS DT2;
GO