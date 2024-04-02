CREATE TABLE order_details (
    order_details_id INT PRIMARY KEY,
    order_id INT,
    order_date DATE,
    order_time TIME,
	item_id INT
);

CREATE TABLE menu_items (
    menu_item_id INT PRIMARY KEY,
    item_name VARCHAR(500),
    category VARCHAR(500),
    price DECIMAL(10,2)
);

BULK INSERT order_details 
FROM 'D:\PlacementDost_Data-Analysis\DA  Restaurant orders\order_details.csv'
WITH (
	FORMAT = 'CSV',
    FIELDTERMINATOR = ',',
    FIRSTROW = 2,           
    ROWTERMINATOR = '\n'
);
GO

BULK INSERT menu_items
FROM 'D:\PlacementDost_Data-Analysis\DA  Restaurant orders\menu_items.csv'
WITH (
	FORMAT = 'CSV',
    FIELDTERMINATOR = ',',
    FIRSTROW = 2,           
    ROWTERMINATOR = '\n'
);
GO


SELECT * FROM order_details;

SELECT TOP 5 * FROM menu_items;

SELECT item_name AS Main_Course, price
FROM menu_items
WHERE category = 'Italian'
ORDER BY price DESC;

/*
          'AGGREGATION FUCTION'     
										*/
--- 1 Calculate the average price of menu items
SELECT AVG(price) AS Avrage_Price FROM menu_items;
--- 2 Find the total number of orders placed.
SELECT COUNT(menu_item_id) AS TOTAL_NUM FROM menu_items;

/*
				  'JOIN'     
										*/
--- 1 Retrieve the item_name, order_date, and order_time for all items in the order_details table, includingtheir respective menu item details.
SELECT item_name, order_date, order_time, menu_items.* FROM order_details
JOIN menu_items 
ON menu_items.menu_item_id = order_details.item_id;
---2 List the menu items (item_name) with a price greater than the average price of all menu items.
SELECT item_name, order_date, order_time, menu_items.* FROM order_details
JOIN menu_items 
ON menu_items.menu_item_id = order_details.item_id
WHERE price > (SELECT AVG(price) AS Avrage_Price FROM menu_items);

/*
		 "Date and Time Functions"
										*/
--- 1 Extract the month from the order_date and count the number of orders placed in each month
SELECT MONTH(order_date) AS month, COUNT(*) AS events  FROM order_details
GROUP BY MONTH(order_date)
ORDER BY 2 DESC;

/*
		 "Group By and Having"
										*/
--- 1 Show the categories with the average price greater than $15.
SELECT category, AVG(price) FROM menu_items 
GROUP BY category
HAVING AVG(price) > 15;
--- 2 Include the count of items in each category.
SELECT category, AVG(price)AS AVG_Price, COUNT(*)AS EVENTS FROM menu_items 
GROUP BY category
HAVING AVG(price) > 15;

/*
		 "Conditional Statements"
										*/
--- 1 Display the item_name and price, and indicate if the item is priced above $20 with a new column named 'Expensive'
SELECT item_name, price, CASE WHEN price > 20 THEN 'Expensive' ELSE 'Not Expensive' END AS Estimate_Price FROM menu_items

/*
	  "Data Modification - Update"
										*/
--- 1 Update the price of the menu item with item_id = 101 to $25
UPDATE menu_items
SET price = 25
WHERE menu_item_id = 101;

/*
	  "Data Modification - Insert"
										*/
--- 1 Insert a new record into the menu_items table for a dessert item.
INSERT INTO menu_items (menu_item_id,item_name, price, category)
VALUES (133,'Cookies', 10.99, 'Dessert');
---
SELECT TOP 5 * FROM menu_items
ORDER BY menu_item_id DESC;

/*
	  "Data Modification - Delete"
										*/
--- 1 Delete all records from the order_details table where the order_id is less than 100.
DELETE FROM order_details
WHERE order_id < 100;
--- 
SELECT TOP 10 * FROM order_details;

/*
	  "Window Functions - Rank"
										*/
--- 1 Rank menu items based on their prices, displaying the item_name and its rank
SELECT item_name, price, RANK() OVER (ORDER BY price) AS rank
FROM menu_items;

/*
	"Window Functions - Lag and Lead"
										*/
--- 1 Display the item_name and the price difference from the previous and next menu item
SELECT 
    item_name,
    price,
    price - LAG(price) OVER (ORDER BY price) AS price_difference_previous,
    LEAD(price) OVER (ORDER BY price) - price AS price_difference_next
FROM 
    menu_items;

/*
	"Common Table Expressions (CTE)"
										*/
--- 1 Create a CTE that lists menu items with prices above $15
WITH event AS (
    SELECT item_name, price FROM menu_items
    WHERE price > 15 )

SELECT item_name, price
FROM event;
--- 2 Use the CTE to retrieve the count of such items
WITH event AS (
    SELECT item_name, price
    FROM menu_items
    WHERE price > 15)

SELECT item_name, price, (SELECT COUNT(*) FROM event) AS count_above_15
FROM event;
---
WITH MenuItemsAbove15 AS (
    SELECT item_name, price
    FROM menu_items
    WHERE price > 15
)
SELECT 
    COUNT(*) AS count_above_15
FROM 
    MenuItemsAbove15;

/*
			"Advanced Joins"
										*/
--- 1 Retrieve the order_id, item_name, and price for all orders with their respective menu item details.
--- 2 Include rows even if there is no matching menu item
SELECT order_id, item_name, price, m.* FROM order_details o
LEFT JOIN menu_items m
ON o.item_id = m.menu_item_id;

/*
			"Unpivot Data"
										*/
--- 1 Unpivot the menu_items table to show a list of menu item properties (item_id, item_name, category,price).
SELECT 
    menu_item_id,
    property_name,
    property_value
FROM 
    (SELECT 
        menu_item_id,
        item_name,
        category,
        CAST(price AS VARCHAR(500)) AS price
     FROM 
        menu_items) AS MenuItems
UNPIVOT 
    (property_value FOR property_name IN (item_name, category, price)) AS UnpivotedMenuItems;
--- *1* 'this is an PIVOT important example'
SELECT * FROM (SELECT category, MONTH(order_date)AS SalesMonth,price FROM menu_items m
JOIN order_details o
ON m.menu_item_id = o.item_id) one
PIVOT(
	SUM(price) FOR SalesMonth IN([1],[2],[3])
) AS PivotTable
ORDER by category;

--- *2* pivot 'this one i think its usfull even more'
SELECT * FROM(
 SELECT menu_item_id, item_name, category, MONTH(order_date)AS SaleMonth, price FROM menu_items m
 JOIN order_details o
 ON m.menu_item_id = o.item_id) AS one
PIVOT (
    SUM(price) FOR SaleMonth IN ([1], [2], [3])) AS PivotTable
ORDER BY [1] DESC, [2] DESC, [3] DESC;
-- *3* 'one more'
SELECT * FROM (SELECT order_id, menu_item_id, item_name,category FROM menu_items m
JOIN order_details o
ON m.menu_item_id = o.item_id) one
PIVOT(
	COUNT(order_id) FOR category IN(Mexican,American,Asian,Italian)
) AS PivotTable;

/*
			"Dynamic SQL"
										*/
--- 1 Write a dynamic SQL query that allows users to filter menu items based on category and price range
DECLARE @CategoryFilter VARCHAR(500) = NULL; -- User input for category filter
DECLARE @MinPrice DECIMAL(10, 2) = 9; -- User input for minimum price
DECLARE @MaxPrice DECIMAL(10, 2) = 15; -- User input for maximum price

DECLARE @SQLQuery NVARCHAR(MAX);
SET @SQLQuery = 'SELECT menu_item_id, item_name, category, price FROM menu_items
WHERE 1 = 1'; -- 1=1 for easy appending of conditions
-- Add category filter if provided
IF @CategoryFilter IS NOT NULL
BEGIN
SET @SQLQuery = @SQLQuery + '
AND category = @CategoryFilter';
END

-- Add price range filter if provided
IF @MinPrice IS NOT NULL AND @MaxPrice IS NOT NULL
BEGIN
SET @SQLQuery = @SQLQuery + '
AND price BETWEEN @MinPrice AND @MaxPrice';
END

-- Execute the dynamic SQL query
EXEC sp_executesql @SQLQuery, N'@CategoryFilter NVARCHAR(MAX), @MinPrice DECIMAL(10, 2), @MaxPrice DECIMAL(10, 2)', @CategoryFilter, @MinPrice, @MaxPrice;

/*
			"Stored Procedure"
										*/
--- 1 Create a stored procedure that takes a menu category as input and returns the average price for that category.
CREATE PROCEDURE AveragePriceForCategory @Category VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AveragePrice DECIMAL(10, 2);

    SELECT @AveragePrice = AVG(price)
    FROM menu_items
    WHERE category = @Category;

    SELECT @AveragePrice AS AveragePrice;
END;

EXEC AveragePriceForCategory 'Italian';

/*
			 "Triggers"
										*/
--- 1 Design a trigger that updates a log table whenever a new order is inserted into the order_details table.
CREATE TABLE order_log (
    order_log INT IDENTITY(1,1) PRIMARY KEY,
	OrderDetailsId INT,
	OrderID INT,
    OrderDate DATETIME,
    OrderTime TIME,
    ItemID INT
);
CREATE TRIGGER InsertTriggerS
ON order_details
AFTER INSERT
AS
BEGIN

    DECLARE @OrderDetailsId INT,
            @OrderID INT,
            @OrderDate DATE,
            @OrderTime TIME,
            @ItemID INT;

    SELECT @OrderDetailsId = order_details_id,
           @OrderID = order_id,
           @OrderDate = order_date,
           @OrderTime = order_time,
           @ItemID = item_id
    FROM inserted;

    -- Insert into the log table
    INSERT INTO order_log (OrderDetailsId, OrderID, OrderDate, OrderTime, ItemID)
    VALUES (@OrderDetailsId, @OrderID, @OrderDate, @OrderTime, @ItemID);
END;

insert into order_details (order_details_id, order_id, order_date, order_time, item_id) VALUES(12235,5370,'3/31/2023','10:15:50 PM',104)

SELECT TOP 5* FROM order_details
ORDER BY order_details_id DESC;