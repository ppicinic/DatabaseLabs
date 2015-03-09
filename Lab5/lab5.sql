-- 1)

SELECT a.city
FROM orders AS o
INNER JOIN agents AS a ON o.aid = a.aid
WHERE cid = 'c006';

-- 2)

SELECT o2.pid
FROM customers AS c
INNER JOIN orders AS o1 ON c.cid = o1.cid 
	INNER JOIN orders AS o2 ON o1.aid = o2.aid
WHERE c.city = 'Kyoto';

-- 3)

SELECT name
FROM customers
WHERE cid NOT IN
	(SELECT cid
	FROM orders);

-- 4)

SELECT c.name
FROM orders AS o
RIGHT JOIN customers AS c ON c.cid = o.cid
WHERE o.ordno IS NULL;

-- 5)

SELECT c.name, a.name
FROM customers AS c
INNER JOIN orders AS o ON c.cid = o.cid
	INNER JOIN agents AS a ON o.aid = a.aid
WHERE c.city = a.city

-- 6)

SELECT c.name, a.name
FROM customers AS c
INNER JOIN agents AS a ON c.city = a.city

-- 7)

SELECT p.city, c.name
FROM customers as c
INNER JOIN (SELECT city, count(pid) as pkinds
FROM products
GROUP BY city
ORDER BY pkinds ASC
LIMIT 1) AS p ON c.city = p.city


