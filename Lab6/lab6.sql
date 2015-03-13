-- 1)

SELECT c.name, c.city
FROM customers AS c
INNER JOIN (
	SELECT city, count(pid) as pkinds
	FROM products
	GROUP BY city
	ORDER BY pkinds DESC
	LIMIT 2) AS p ON c.city = p.city;
	
-- 2)

SELECT name
FROM products
WHERE priceUSD < (
	SELECT avg(priceusd) 
	FROM products)
ORDER BY name ASC;

-- 3)

SELECT c.name, o.pid, o.dollars
FROM orders AS o
INNER JOIN customers AS c on o.cid = c.cid
ORDER BY o.dollars DESC;

-- 4)
SELECT c.name, COALESCE(o.totalordered, 0.00)
FROM customers AS c
LEFT JOIN (
	SELECT sum(dollars) AS totalordered, cid
	FROM orders
	GROUP BY cid) AS o ON c.cid = o.cid
ORDER BY c.name DESC;

-- 5)

SELECT c.name AS customername, p.name AS productname, a.name AS agentname
FROM customers AS c
INNER JOIN orders AS o ON c.cid = o.cid
	INNER JOIN agents AS a ON o.aid = a.aid
	INNER JOIN products AS p ON o.pid = p.pid
WHERE a.city = 'Tokyo';

-- 6)

SELECT *
FROM orders AS o
INNER JOIN customers AS c ON o.cid = c.cid
	INNER JOIN products as p ON o.pid = p.pid
WHERE o.dollars != ((p.priceusd * o.qty) * ((100 - c.discount) / 100))

-- 7)

/*
The difference between a left join and right join is that in a left join, data in the left table (or first table)
that does not have a match in the right table will still appear in the results. In a right join, the opposite is true
such that data in the right table that does not have a match will still appear in the results. In the solution to number 4
Weyland-Yutani is not in the right table because he never ordered any products, thus the left join still includes him in the result
without a match. However, if a right join were to have been used here, Weyland-Yutani would have not been in the results
because the right join only keeps data in the right table that does not have a match.
*/
