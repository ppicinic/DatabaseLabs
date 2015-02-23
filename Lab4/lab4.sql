-- 1)
SELECT city

FROM agents
WHERE aid IN (
SELECT aid
FROM orders
WHERE cid = 'c006');

-- 2)

SELECT DISTINCT pid
FROM orders
WHERE cid =(
	SELECT cid
	FROM customers
	WHERE city = 'Kyoto')
ORDER BY pid DESC;

-- 3)

SELECT DISTINCT cid, name
FROM customers
WHERE cid NOT IN (
		SELECT cid
		FROM orders
		WHERE aid = 'a03');

-- 4)

SELECT DISTINCT cid
FROM customers
WHERE cid NOT IN (
		SELECT cid
		FROM orders
		WHERE pid != 'p01' 
			AND pid != 'p07');

-- 5)
SELECT DISTINCT pid
FROM products
WHERE pid NOT IN ( 
	SELECT DISTINCT pid
	FROM orders
	WHERE cid NOT IN (
			SELECT cid
			FROM orders
			WHERE aid = 'a05'));

-- 6)
SELECT name, discount, city
FROM customers
WHERE cid IN (
		SELECT DISTINCT cid
		FROM orders
		WHERE aid IN (
				SELECT aid
				FROM agents
				WHERE city = 'Dallas'
					OR city = 'New York'));

-- 7)
SELECT *
FROM customers
WHERE discount IN (
			SELECT discount
			FROM customers
			WHERE city = 'Dallas'
				OR city = 'London');