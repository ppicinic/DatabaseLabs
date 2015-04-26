-- Phillip Picinic Database Design Project SQL

-- drop tables


Drop TABLE IF EXISTS equipItems;
DROP TABLE IF EXISTS classSkills;
DROP TABLE IF EXISTS raceSkills;
DROP TABLE IF EXISTS characterSkills;
DROP TABLE IF EXISTS inventoryContains;

DROP TABLE IF EXISTS inventories;
DROP TABLE IF EXISTS items;

DROP TABLE IF EXISTS characters;

DROP TABLE IF EXISTS players;
DROP TABLE IF EXISTS classes;
DROP TABLE IF EXISTS skills;
DROP TABLE IF EXISTS races;
DROP TABLE IF EXISTS levels;

-- create table

-- Players Table

CREATE TABLE players(
	playerId SERIAL NOT NULL,
	email VARCHAR(70) NOT NULL UNIQUE,
	password VARCHAR(24) NOT NULL, -- password in plain text for this PoC
	username VARCHAR(18) NOT NULL UNIQUE,
	PRIMARY KEY (playerId)
);

CREATE TABLE classes(
	classId SERIAL NOT NULL,
	name VARCHAR(16) NOT NULL UNIQUE,
	description TEXT NOT NULL,
	classLevel INTEGER,
	PRIMARY KEY (classId)
);

CREATE TABLE skills(
	skillId SERIAL NOT NULL,
	name VARCHAR(16) NOT NULL,
	description TEXT NOT NULL,
	maxLevel INTEGER NOT NULL,
	PRIMARY KEY (skillId)
);

CREATE TABLE classSkills(
	skillId INTEGER NOT NULL REFERENCES skills(skillId),
	classId INTEGER NOT NULL REFERENCES classes(classId),
	PRIMARY KEY (skillId, classId)
);

CREATE TABLE races(
	raceId SERIAL NOT NULL,
	name VARCHAR(16),
	description TEXT,
	PRIMARY KEY(raceId)
);

CREATE TABLE raceSkills(
	skillId INTEGER NOT NULL REFERENCES skills(skillId),
	raceId INTEGER NOT NULL REFERENCES races(raceId),
	PRIMARY KEY (skillId, raceId)
);

CREATE TABLE levels(
	level SERIAL NOT NULL,
	totalExpNeeded INTEGER NOT NULL,
	PRIMARY KEY(level)
);

CREATE TABLE characters(
	characterId SERIAL NOT NULL,
	playerId INTEGER NOT NULL REFERENCES players(playerId),
	raceId INTEGER NOT NULL REFERENCES races(raceId) check(raceId != 1),
	classId INTEGER NOT NULL REFERENCES classes(classId),
	level INTEGER NOT NULL REFERENCES levels(level),
	characterName VARCHAR(12) NOT NULL UNIQUE,
	experience INTEGER NOT NULL,
	maxHealth INTEGER NOT NULL,
	maxMana INTEGER NOT NULL,
	health INTEGER NOT NULL check(health >= 0),
	mana INTEGER NOT NULL check(mana >= 0),
	strength INTEGER NOT NULL,
	intelligence INTEGER NOT NULL,
	endurance INTEGER NOT NULL,
	speed INTEGER NOT NULL,
	PRIMARY KEY (characterId),

	check(health <= maxHealth),
	check(mana <= maxMana)
);

CREATE TABLE characterSkills(
	characterId INTEGER NOT NULL REFERENCES characters(characterId),
	skillId INTEGER NOT NULL REFERENCES skills(skillId),
	level INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (characterId, skillId)
);

CREATE TABLE inventories(
	characterId INTEGER NOT NULL REFERENCES characters(characterId),
	maxCapacity INTEGER DEFAULT 10,
	PRIMARY KEY (characterId)
);

CREATE TABLE items(
	itemId SERIAL NOT NULL,
	name VARCHAR(16) NOT NULL UNIQUE,
	description TEXT NOT NULL,
	PRIMARY KEY (itemId)
);

CREATE OR REPLACE FUNCTION isBeyondMax(id integer) RETURNS boolean AS $beyond$
DECLARE
	amt integer;
	maxCap integer;
BEGIN
	amt = (SELECT count(characterId) FROM inventoryContains WHERE characterId = id);
	maxCap = (SELECT maxCapacity FROM inventories WHERE characterId = id);
	IF amt >= maxCap THEN
		RETURN FALSE;
	ELSE
		RETURN TRUE;
	END IF;
	RETURN TRUE;
END
$beyond$ LANGUAGE plpgsql;
	
CREATE TABLE inventoryContains(
	characterId INTEGER NOT NULL REFERENCES characters(characterId),
	itemId INTEGER NOT NULL REFERENCES items(itemId),
	amount INTEGER NOT NULL DEFAULT 1,
	PRIMARY KEY (characterId, itemId),

	check(isBeyondMax(characterId))
);

CREATE TYPE EQUIPTYPE as ENUM('hat', 'shirt', 'pants', 'shoes', 'gloves', 'weapon');

CREATE TABLE equipItems(
	itemId INTEGER NOT NULL REFERENCES items(itemId),
	type EQUIPTYPE,
	attack INTEGER NOT NULL DEFAULT 0 check(attack >= 0),
	defense INTEGER NOT NULL DEFAULT 0 check(defense >= 0),
	PRIMARY KEY(itemId)
);

CREATE OR REPLACE FUNCTION isProperType(id integer, matchType EQUIPTYPE) RETURNS boolean AS $properType$
DECLARE
	actualType EQUIPTYPE;
BEGIN
	IF id IS NULL THEN
		RETURN TRUE;
	END IF;
	actualType = (SELECT type FROM equipItems WHERE itemId = id);
	IF actualType = matchType THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
	RETURN TRUE;
END
$properType$ LANGUAGE plpgsql;

CREATE TABLE equipments(
	characterId INTEGER NOT NULL REFERENCES characters(characterId),
	hatId INTEGER REFERENCES equipItems(itemId),
	shirtId INTEGER REFERENCES equipItems(itemId),
	pantsId INTEGER REFERENCES equipItems(itemId),
	shoesId INTEGER REFERENCES equipItems(itemId),
	glovesId INTEGER REFERENCES equipItems(itemId),
	weaponId INTEGER REFERENCES equipItems(itemId),
	PRIMARY KEY (characterId),
	check(isProperType(hatId, 'hat')),
	check(isProperType(shirtId, 'shirt')),
	check(isProperType(pantsId, 'pants')),
	check(isProperType(shoesId, 'shoes')),
	check(isProperType(glovesId, 'gloves')),
	check(isProperType(weaponId, 'weapon'))
);

-- triggers

CREATE OR REPLACE FUNCTION characterFill() RETURNS trigger AS $characterFill$
	DECLARE
		r integer;
		c integer;
	BEGIN
		FOR r IN SELECT skillId FROM raceSkills WHERE raceId = NEW.raceId
		LOOP
			INSERT INTO characterSkills (characterId, skillId) VALUES (NEW.characterId, r);
		END LOOP;
		FOR c IN SELECT skillId FROM classSkills WHERE classId = NEW.classId
		LOOP
			INSERT INTO characterSkills (characterId, skillId) VALUES (NEW.characterId, c);
		END LOOP;
		INSERT INTO inventories (characterId) VALUES (NEW.characterId);
		INSERT INTO equipments (characterId) VALUES (NEW.characterId);
		RETURN NULL;
	END;
$characterFill$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION skillFill() RETURNS trigger AS $sFill$
	DECLARE
		r integer;
		c integer;
	BEGIN
		FOR r IN SELECT skillId FROM raceSkills WHERE raceId = NEW.raceId AND skillId NOT IN (SELECT skillId FROM characterSkills WHERE characterId = NEW.characterId)
		LOOP
			INSERT INTO characterSkills (characterId, skillId) VALUES (NEW.characterId, r);
		END LOOP;
		FOR c IN SELECT skillId FROM classSkills WHERE classId = NEW.classId AND skillId NOT IN (SELECT skillId FROM characterSkills WHERE characterId = NEW.characterId)
		LOOP
			INSERT INTO characterSkills (characterId, skillId) VALUES (NEW.characterId, c);
		END LOOP;
		RETURN NULL;
	END;
$sFill$ LANGUAGE plpgsql;

CREATE TRIGGER characterFill
AFTER INSERT ON characters FOR ROW EXECUTE PROCEDURE characterFill();

CREATE TRIGGER classSkillUpdate
AFTER UPDATE OF classId ON characters FOR ROW EXECUTE PROCEDURE skillFill();

CREATE TRIGGER raceSkillUpdate
AFTER UPDATE OF raceId ON characters FOR ROW EXECUTE PROCEDURE skillFill();
-- views

CREATE OR REPLACE VIEW characterItemView AS 
SELECT c.characterId, characterName, hi.name AS hat, si.name AS shirt, pi.name AS pants, shi.name AS shoes, gi.name AS gloves, wi.name AS weapon,
	(coalesce(h.attack, 0) + coalesce(w.attack, 0) + coalesce(s.attack, 0) + coalesce(p.attack,0) + coalesce(sh.attack,0) 
		+ coalesce(g.attack,0)) AS totalAttack, 
	(coalesce(h.defense, 0) + coalesce(w.defense, 0) + coalesce(s.defense, 0) + coalesce(p.defense,0) + coalesce(sh.defense,0)
		 + coalesce(g.defense,0)) AS totalDefense
FROM characters AS c 
	INNER JOIN equipments AS e ON c.characterId = e.characterId
		LEFT JOIN equipItems AS h ON e.hatId = h.itemId
			LEFT JOIN items AS hi ON h.itemId = hi.itemId
		LEFT JOIN equipItems AS w On e.weaponId = w.itemId
			LEFT JOIN items AS wi ON w.itemId = wi.itemId
		LEFT JOIN equipItems  AS s ON e.shirtId = s.itemId
			LEFT JOIN items AS si ON s.itemId = si.itemId
		LEFT JOIN equipItems AS p ON e.pantsId = p.itemId
			LEFT JOIN items AS pi ON p.itemId = pi.itemId
		LEFT JOIN equipItems AS sh ON e.shoesId = sh.itemId
			LEFT JOIN items AS shi ON sh.itemId = shi.itemId
		LEFT JOIN equipItems AS g ON e.glovesId = g.itemId
			LEFT JOIN items AS gi ON g.itemId = gi.itemId;

CREATE OR REPLACE VIEW characterSkillView AS
SELECT c.characterId, c.characterName, c.level, r.name AS race, cl.name AS class, s.name AS skill, cs.level AS skilllevel
	FROM characters AS c
	LEFT JOIN races AS r ON c.raceId = r.raceId
	LEFT JOIN classes AS cl ON c.classId = cl.classId
	LEFT JOIN characterSkills AS cs ON c.characterId = cs.characterId
	LEFT JOIN skills AS s ON cs.skillId = s.skillId;

CREATE OR REPLACE VIEW playerCharactersView AS
SELECT p.playerId, email, username, characterName, level, r.name AS race, cl.name AS class, experience, 
	maxhealth, maxmana, strength, intelligence, endurance, speed
	FROM players AS p
	LEFT JOIN characters AS c ON p.playerId = c.playerId
	LEFT JOIN classes AS cl ON c.classId = cl.classId
	LEFT JOIN races AS r ON c.raceId = r.raceId;
-- server side initialization data

INSERT INTO classes
	(name, description)
	VALUES
	('Novice', 'a new character that currently does not have a selected class');

	
INSERT INTO classes
	(name, description, classLevel)
	VALUES
	('Warrior', 'a physical class that uses swords', 1);


INSERT INTO classes
	(name, description, classLevel)
	VALUES
	('Mage', 'a magic class that uses spells', 1);


INSERT INTO classes
	(name, description, classLevel)
	VALUES
	('Bowman', 'an agile class that uses bows an arrows', 1);


INSERT INTO classes
	(name, description, classLevel)
	VALUES
	('Priest', 'a mage class focused on healing and support', 2);


INSERT INTO classes
	(name, description, classLevel)
	VALUES
	('ArchMage', 'a more powerful mage class focused on powerful spell damaging attacks', 2);

-- races

INSERT INTO races
	(name, description)
	VALUES
	('NullRace', 'a null race entry for the system, should never be allocated to a player'); -- TODO should there be aa check constraint for this in the character table?

INSERT INTO races
	(name, description)
	VALUES
	('Pixie', 'small fairies with high magical poweress and mana');

INSERT INTO races
	(name, description)
	VALUES
	('Orc', 'Powerful physical attackers with high health');

INSERT INTO races
	(name, description)
	VALUES
	('Human', 'Basic race with high intelligence');



-- class skills
INSERT INTO skills
	(name, description, maxLevel)
	VALUES
	('Lightning Strike', 'strikes down 3 monsters with lightning', 10);

INSERT INTO skills
	(name, description, maxLevel)
	VALUES
	('Magic Shield', 'Creates a shield that absorbbs damage the player takes', 5);

INSERT INTO skills
	(name, description, maxLevel)
	VALUES
	('Heal', 'Heals 100hp to all party members nearby', 20);

INSERT INTO skills
	(name, description, maxLevel)
	VALUES
	('Assist', 'Increases the attack power of party members by a certain amount', 10);

INSERT INTO skills
	(name, description, maxLevel)
	VALUES
	('Blizzard', 'AoE attack that does ice damage to all monsters nearby.', 30);

INSERT INTO skills
	(name, description, maxLevel)
	VALUES
	('Plasma Beam', 'Hits one monster with a powerful beam and has to cooldown', 20);

INSERT INTO skills
	(name, description, maxLevel)
	VALUES
	('Snipe', 'Shoots a powerful arrow with increased chance of critical dammage', 15);

-- race skills

INSERT INTO skills
	(name, description, maxLevel)
	VALUES
	('Enrage', 'Increases attack by a certain amount for a given period', 40);

INSERT INTO skills
	(name, description, maxLevel)
	VALUES
	('Invisibility', 'Allows the user to turn invisible from the enemy for a given period of time', 20);

INSERT INTO skills
	(name, description, maxLevel)
	VALUES
	('Magic Boost', 'Increases attack from a given period of time and but increases mana usage of skills', 20);

-- class skills assc

INSERT INTO classSkills
	(skillId, classId)
	VALUES
	(1, 3);

INSERT INTO classSkills
	(skillId, classId)
	VALUES
	(2, 3);

INSERT INTO classSkills
	(skillId, classId)
	VALUES
	(1, 5);

INSERT INTO classSkills
	(skillId, classId)
	VALUES
	(2, 5);

INSERT INTO classSkills
	(skillId, classId)
	VALUES
	(1, 6);

INSERT INTO classSkills
	(skillId, classId)
	VALUES
	(2, 6);

INSERT INTO classSkills
	(skillId, classId)
	VALUES
	(3, 5);

INSERT INTO classSkills
	(skillId, classId)
	VALUES
	(4, 5);

INSERT INTO classSkills
	(skillId, classId)
	VALUES
	(5, 6);

INSERT INTO classSkills
	(skillId, classId)
	VALUES
	(6, 6);

INSERT INTO classSkills
	(skillId, classId)
	VALUES
	(7, 4);
-- race skills assc

INSERT INTO raceSkills
	(skillId, raceId)
	VALUES
	(9, 2);

INSERT INTO raceSkills
	(skillId, raceId)
	VALUES
	(10, 2);

INSERT INTO raceSkills
	(skillId, raceId)
	VALUES
	(8, 3);

-- starting levels (Auto generate future levels with stored procs via formula next level = curr level exp * 1.5)

INSERT INTO levels
	(totalExpNeeded) VALUES (200);

INSERT INTO levels
	(totalExpNeeded) VALUES (300);

INSERT INTO levels
	(totalExpNeeded) VALUES (450);

INSERT INTO levels
	(totalExpNeeded) VALUES (675);

INSERT INTO levels
	(totalExpNeeded) VALUES (1012);

INSERT INTO levels
	(totalExpNeeded) VALUES (1518);

INSERT INTO levels
	(totalExpNeeded) VALUES (2277);

-- items

INSERT INTO items
	(name, description)
	VALUES
	('Sm Health Potion', 'recovers 50 hp');

INSERT INTO items
	(name, description)
	VALUES
	('Sm Mana Potion', 'recovers 50 mana');

-- Equip Items
INSERT INTO items
	(name, description)
	VALUES
	('Small Sword', 'A basic sword with low attack power');

INSERT INTO equipItems
	(itemId, type, attack, defense)
	VALUES
	((SELECT itemId FROM items WHERE name = 'Small Sword'), 'weapon', 10, 0);

-- test data

INSERT INTO players 
	(email, password, username)
	VALUES
	('philpicinic@gmail.com', 'alpaca', 'thephil');

INSERT INTO players
	(email, password, username)
	VALUES
	('alan@labouseur.com', 'alpaca', 'theman');

INSERT INTO characters
	(playerId, raceId, classId, level, characterName, experience, maxHealth, maxMana, health, mana, strength, intelligence, endurance, speed)
	VALUES
	(1, 4, 1, 1, 'Nooblet', 0, 100, 100, 100, 100, 5, 5, 5, 20);

INSERT INTO characters
	(playerId, raceId, classId, level, characterName, experience, maxHealth, maxMana, health, mana, strength, intelligence, endurance, speed)
	VALUES
	(1, 2, 3, 1, 'PixieMage', 0, 50, 200, 50, 200, 3, 7, 2, 30);

UPDATE equipments SET weaponId = (SELECT itemId FROM items WHERE name='Small Sword') WHERE characterId = 2;

UPDATE characters SET classId = (SELECT classId FROM classes WHERE name='Priest') WHERE characterId = (SELECT characterId FROM characters WHERE characterName = 'PixieMage');

-- testing sql

select * from players;
select * from classes;
select * from characters;
select * from equipments;
select * from skills;
select * from races;
select * from levels;
select * from inventories;
select * from items;
select * from equipItems AS e INNER JOIN items AS i ON e.itemId = i.itemId;

-- get a character with all skills
select * from classes AS c
LEFT JOIN classSkills AS cs ON c.classId = cs.classId
LEFT JOIN skills AS s ON cs.skillId = s.skillId
ORDER BY c.classId;

-- get a race with all skills
select * from races AS r
LEFT JOIN raceSkills AS rs ON r.raceId = rs.raceId
LEFT JOIN skills AS s ON rs.skillId = s.skillId
ORDER BY r.raceId;

-- get a character with all skills
SELECT * FROM characters AS c 
LEFT JOIN characterSkills AS cs ON c.characterId = cs.characterId
LEFT JOIN skills AS s ON cs.skillId = s.skillId

INSERT INTO inventories (characterId) VALUES (5);

UPDATE inventories SET maxCapacity = 10;

INSERT INTO inventoryContains (characterId, itemId, amount) VALUES (5, 2, 5);
