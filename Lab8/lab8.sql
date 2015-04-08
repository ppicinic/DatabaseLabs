-- drop tables
DROP TABLE IF EXISTS purchaseorders;
DROP TABLE IF EXISTS supplierpayments;
DROP TABLE IF EXISTS clothes;
DROP TABLE IF EXISTS purchases;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS paymenttypes;

-- create tables
CREATE TABLE clothes(
	SKU VARCHAR(10) NOT NULL,
	description VARCHAR(40) NOT NULL,
	retailPriceUSD NUMERIC NOT NULL,
	quantity INTEGER NOT NULL,
	PRIMARY KEY (SKU)
);

CREATE TABLE suppliers(
	supplierId SERIAL NOT NULL,
	name text NOT NULL,
	streetaddress text NOT NULL,
	city text NOT NULL,
	state text NOT NULL,
	postalcode text NOT NULL,
	contact text NOT NULL,
	PRIMARY KEY (supplierId)
);

CREATE TABLE paymenttypes(
	paymentId SERIAL NOT NULL,
	description text NOT NULL,
	PRIMARY KEY (paymentId)
);

CREATE TABLE supplierpayments(
	supplierId INTEGER NOT NULL references suppliers(supplierId),
	paymentId INTEGER NOT NULL references paymenttypes(paymentId)
);

CREATE TABLE purchases(
	purchaseId SERIAL NOT NULL,
	supplierId INTEGER NOT NULL references suppliers(supplierId),
	date DATE NOT NULL,
	comments TEXT,
	PRIMARY KEY (purchaseId)
);

CREATE TABLE purchaseorders(
	orderId SERIAL NOT NULL,
	purchaseId INTEGER NOT NULL references purchases(purchaseId),
	SKU VARCHAR(10) NOT NULL references clothes(SKU),
	quantity INTEGER NOT NULL,
	purchasePriceUSD NUMERIC NOT NULL,
	PRIMARY KEY (orderId)
);
-- test data

INSERT INTO clothes 
	(SKU, description, retailPriceUSD, quantity) 
	VALUES 
	('PMNL001', 'large navy pants for men', 25.25, 50);

INSERT INTO clothes 
	(SKU, description, retailPriceUSD, quantity) 
	VALUES 
	('SMWL002', 'large white shirt for men', 20.75, 100);

INSERT INTO clothes 
	(SKU, description, retailPriceUSD, quantity) 
	VALUES 
	('TMB003', 'black tie for men', 6.90, 15);

INSERT INTO clothes 
	(SKU, description, retailPriceUSD, quantity) 
	VALUES 
	('SFBS004', 'small black skirt for women', 35.00, 150);

INSERT INTO suppliers
	(name, streetaddress, city, state, postalcode, contact)
	VALUES
	('Marist Clothing', '3399 North Rd', 'Poughkeepsie', 'NY', '11362', '8455753000');

INSERT INTO suppliers
	(name, streetaddress, city, state, postalcode, contact)
	VALUES
	('SFP Clothing', '6100 Francis Lewis Blvd', 'Fresh Meadows', 'NY', '11365', '7184238810');

INSERT INTO paymenttypes
	(description) VALUES ('credit');

INSERT INTO paymenttypes
	(description) VALUES ('check');

INSERT INTO paymenttypes
	(description) VALUES ('cash');

INSERT INTO supplierpayments
	(supplierId, paymentId) VALUES (1, 1);

INSERT INTO supplierpayments
	(supplierId, paymentId) VALUES (1, 2);

INSERT INTO supplierpayments
	(supplierId, paymentId) VALUES (1, 3);

INSERT INTO supplierpayments
	(supplierId, paymentId) VALUES (2, 2);

INSERT INTO supplierpayments
	(supplierId, paymentId) VALUES (2, 3);

INSERT INTO purchases
	(supplierId, date, comments)
	VALUES
	(1, '2015-08-14', 'order for student John Doe');

INSERT INTO purchases
	(supplierId, date, comments)
	VALUES
	(2, '2015-08-12', 'no additional comments');

INSERT INTO purchaseorders
	(purchaseId, SKU, quantity, purchasePriceUSD)
	VALUES
	(1, 'PMNL001', 40, 1000.00);

INSERT INTO purchaseorders
	(purchaseId, SKU, quantity, purchasePriceUSD)
	VALUES
	(1, 'SMWL002', 50, 950.00);

INSERT INTO purchaseorders
	(purchaseId, SKU, quantity, purchasePriceUSD)
	VALUES
	(1, 'TMB003', 10, 60.42);

INSERT INTO purchaseorders
	(purchaseId, SKU, quantity, purchasePriceUSD)
	VALUES
	(2, 'PMNL001', 100, 2037.25);

INSERT INTO purchaseorders
	(purchaseId, SKU, quantity, purchasePriceUSD)
	VALUES
	(1, 'SMWL002', 125, 2603.99);

-- 5 Query

SELECT SKU, (COALESCE(quantity, 0) + COALESCE((
	select sum(quantity)
	FROM purchaseorders
	WHERE SKU = 'TMB003'), 0)) AS totalQuantity
FROM clothes
WHERE SKU = 'TMB003';

-- testing

select * from clothes;
select * from suppliers;
select * from paymenttypes;
select * from supplierpayments;
select * from purchases;
select * from purchaseorders;

select * from
suppliers AS s,
paymenttypes AS p,
supplierpayments AS j
WHERE s.supplierId = j.supplierId AND j.paymentId = p.paymentId;