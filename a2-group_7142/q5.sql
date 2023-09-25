-- Q5. Flight Hopping

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5 (
	destination CHAR(3),
	num_flights INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS day CASCADE;
DROP VIEW IF EXISTS n CASCADE;

CREATE VIEW day AS
SELECT day::date as day FROM q5_parameters;
-- can get the given date using: (SELECT day from day)

CREATE VIEW n AS
SELECT n FROM q5_parameters;
-- can get the given number of flights using: (SELECT n from n)

-- HINT: You can answer the question by writing one recursive query below, without any more views.
-- Your query that answers the question goes below the "insert into" line:
WITH RECURSIVE hopping AS(
	(SELECT 1 as num_flights, F1.inbound as destination, F1.s_arv
FROM Flight F1
WHERE outbound = 'YYZ' 
AND EXTRACT(day FROM (SELECT day FROM day)) = EXTRACT(day FROM F1.s_dep)
AND EXTRACT(month FROM (SELECT day FROM day)) = EXTRACT(month FROM F1.s_dep)
AND EXTRACT(year FROM (SELECT day FROM day)) = EXTRACT(year FROM F1.s_dep))
UNION ALL
(SELECT num_flights + 1, F2.inbound as destination, F2.s_arv
FROM hopping JOIN Flight F2 ON hopping.destination = F2.outbound
WHERE F2.s_dep < hopping.s_arv + '24:00:00' 
AND num_flights < (SELECT n FROM n))
)

INSERT INTO q5
SELECT destination, num_flights
FROM hopping;















