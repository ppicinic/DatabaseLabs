-- 1)
SELECT ordno, dollars 
FROM orders;

-- 2)
SELECT name, city 
FROM agents 
WHERE name='Smith';
 
-- 3)
SELECT pid, name, priceusd 
FROM products 
WHERE quantity>200000;

-- 4)
SELECT name, city 
FROM customers;

-- 5)
SELECT name, city 
FROM agents 
WHERE city!='New York' 
	AND city!='Tokyo';

-- 6)
SELECT * 
FROM products 
WHERE city!='Dallas' 
	AND city!='Duluth' 
	AND priceusd>=1;

-- 7)
SELECT * 
FROM orders 
WHERE mon='jan' 
	OR mon='may';

-- 8)
SELECT * 
FROM orders 
WHERE mon='feb' 
	AND dollars>500;

-- 9)
SELECT * 
FROM orders 
WHERE cid='c005';