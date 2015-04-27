-- 1)

CREATE OR REPLACE FUNCTION PreReqsFor(courseNum integer) RETURNS setof courses AS $$
BEGIN 
	RETURN QUERY (SELECT p.prereqnum, c.name, c.credits
		FROM prerequisites AS p 
		INNER JOIN courses AS c ON p.prereqnum = c.num
		WHERE p.coursenum = PreReqsFor.courseNum);
END;
$$ LANGUAGE plpgsql

-- 2)

CREATE OR REPLACE FUNCTION IsPreReqFor(courseNum integer) RETURNS setof courses AS $$
BEGIN
	RETURN QUERY (SELECT c.num, c.name, c.credits
		FROM prerequisites AS p
		INNER JOIN courses AS c ON p.coursenum = c.num
		WHERE p.prereqnum = IsPreReqFor.coursenum);
END;
$$ LANGUAGE plpgsql

-- challenge)

CREATE OR REPLACE FUNCTION AllPreReqsFor(courseNum integer) RETURNS setof courses AS $$
DECLARE
	r courses%rowtype;
	s courses%rowtype;
BEGIN
	FOR s IN (SELECT p.prereqnum, c.name, c.credits
		FROM prerequisites AS p 
		INNER JOIN courses AS c ON p.prereqnum = c.num
		WHERE p.coursenum = AllPreReqsFor.courseNum)
	LOOP
		RETURN NEXT s;
		FOR r IN SELECT * FROM AllPreReqsFor(s.num) AS courses
		LOOP
			RETURN NEXT r;
		END LOOP;
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;