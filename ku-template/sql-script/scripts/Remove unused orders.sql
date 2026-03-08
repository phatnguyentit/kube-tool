-- Remove unused orders from the order database
-- This script identifies and deletes orders that meet unused criteria

DELETE FROM Orders
WHERE OrderID NOT IN (
    SELECT DISTINCT OrderID 
    FROM OrderItems
)
AND OrderDate < DATEADD(YEAR, -1, GETDATE())
AND OrderStatus = 'Cancelled';

-- Remove orphaned order items
DELETE FROM OrderItems
WHERE OrderID NOT IN (
    SELECT OrderID 
    FROM Orders
);

-- Remove unused tenant orders (no items, not modified in 2 years)
DELETE FROM Orders
WHERE OrderID NOT IN (
    SELECT DISTINCT OrderID 
    FROM OrderItems
)
AND DATEDIFF(DAY, LastModifiedDate, GETDATE()) > 730;