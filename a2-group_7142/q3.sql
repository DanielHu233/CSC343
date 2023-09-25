-- Q3. North and South Connections

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    outbound VARCHAR(30),
    inbound VARCHAR(30),
    direct INT,
    one_con INT,
    two_con INT,
    earliest timestamp
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS USA_city CASCADE;
DROP VIEW IF EXISTS CAN_city CASCADE;
DROP VIEW IF EXISTS CAN_USA_city_pairs CASCADE;
DROP VIEW IF EXISTS flights_220430 CASCADE;
DROP VIEW IF EXISTS CAN_USA_dep_or_arv_220430 CASCADE;
DROP VIEW IF EXISTS direct CASCADE;
DROP VIEW IF EXISTS one_con CASCADE;
DROP VIEW IF EXISTS two_con CASCADE;
DROP VIEW IF EXISTS all_routes_earliest CASCADE;
DROP VIEW IF EXISTS all_comb_earliest CASCADE;
DROP VIEW IF EXISTS convert_to_city CASCADE;
DROP VIEW IF EXISTS include_all_pairs CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW USA_city AS
SELECT DISTINCT city
FROM airport
WHERE country = 'USA';

CREATE VIEW CAN_city AS
SELECT DISTINCT city
FROM airport
WHERE country = 'Canada';

CREATE VIEW CAN_USA_city_pairs(out_city, in_city) AS
(SELECT CAN_city.city, USA_city.city
FROM USA_city, CAN_city )
	UNION
(SELECT USA_city.city, CAN_city.city
FROM USA_city, CAN_city);

CREATE VIEW flights_220430 AS
SELECT Flight.id, outbound, inbound, s_dep, s_arv, A1.country AS out_country, A2.country AS in_country
FROM Flight, Airport A1, Airport A2 
WHERE EXTRACT(day FROM s_dep) = 30 
	AND EXTRACT(month FROM s_dep) = 04 
	AND EXTRACT(year FROM s_dep) = 2022 
	AND EXTRACT(day FROM s_arv) = 30 
	AND EXTRACT(month FROM s_arv) = 04 
	AND EXTRACT(year FROM s_arv) = 2022
	AND Flight.outbound = A1.code
	AND Flight.inbound = A2.code;

CREATE VIEW CAN_USA_dep_or_arv_220430 AS
SELECT flights_220430.id, outbound, inbound, s_dep, s_arv,
	P1.country as out_country, P2.country as in_country
FROM flights_220430, Airport P1, Airport P2
WHERE flights_220430.outbound =  P1.code 
	AND flights_220430.inbound =  P2.code
	AND ((P1.country = 'USA' OR P1.country = 'Canada')
		OR (P2.country = 'USA' OR P2.country = 'Canada'));

CREATE VIEW direct(outbound, inbound, direct, min_time) AS
SELECT outbound, inbound, count(id) AS direct, min(s_arv) as min_time
FROM CAN_USA_dep_or_arv_220430
WHERE (out_country = 'Canada' AND in_country = 'USA')
	OR (out_country = 'USA' AND in_country = 'Canada')
GROUP BY outbound, inbound;

CREATE VIEW one_con(outbound, inbound, one_con, min_time) AS
SELECT info1.outbound, info2.inbound, count(*) AS one_con, min(info2.s_arv) as min_time
FROM CAN_USA_dep_or_arv_220430 info1,  CAN_USA_dep_or_arv_220430 info2
WHERE (info1.out_country = 'Canada' 
	AND info1.inbound = info2.outbound
	AND info1.s_arv + '00:30:00' <= info2.s_dep
	AND info2.in_country = 'USA')
	OR
	(info1.out_country = 'USA'
	AND info1.inbound = info2.outbound
	AND info1.s_arv + '00:30:00' <= info2.s_dep
	AND info2.in_country = 'Canada')
GROUP BY info1.outbound, info2.inbound;

CREATE VIEW two_con(outbound, inbound, two_con, min_time) AS
SELECT info1.outbound, info2.inbound, count(*) AS two_con, min(info2.s_arv) as min_time
FROM CAN_USA_dep_or_arv_220430 info1, 
	flights_220430 F1,
	CAN_USA_dep_or_arv_220430 info2
WHERE(info1.out_country = 'Canada' 
	AND info1.inbound = F1.outbound
	AND info1.s_arv + '00:30:00' <= F1.s_dep
	AND F1.inbound = info2.outbound
	AND F1.s_arv + '00:30:00' <= info2.s_dep
	AND info2.in_country = 'USA')
	OR
	(info1.out_country = 'USA' 
	AND info1.inbound = F1.outbound
	AND info1.s_arv + '00:30:00' <= F1.s_dep
	AND F1.inbound = info2.outbound
	AND F1.s_arv + '00:30:00' <= info2.s_dep
	AND info2.in_country = 'Canada')
GROUP BY info1.outbound, info2.inbound;

CREATE VIEW all_routes_earliest AS
SELECT outbound, inbound, min(min_time)
FROM((SELECT outbound, inbound, min_time
	FROM direct)
	UNION ALL
	(SELECT outbound, inbound, min_time
	FROM one_con)
	UNION ALL
	(SELECT outbound, inbound, min_time
	FROM two_con)) AS all_routes
GROUP BY outbound, inbound;


CREATE VIEW all_comb_earliest AS
SELECT direct.outbound, direct.inbound, direct.direct, 
	one_con.one_con, two_con.two_con, all_routes_earliest.min as earliest
FROM direct FULL JOIN one_con ON direct.outbound = one_con.outbound 
	AND direct.inbound = one_con.inbound
	FULL JOIN two_con ON direct.outbound = two_con.outbound 
	AND direct.inbound = two_con.inbound
	JOIN all_routes_earliest ON direct.outbound = all_routes_earliest.outbound 
	AND direct.inbound = all_routes_earliest.inbound;

CREATE VIEW convert_to_city (outbound, inbound, direct, one_con, two_con, earliest) AS
SELECT A1.city, A2.city, sum(direct), sum(one_con), sum(two_con), min(earliest)
FROM all_comb_earliest, Airport A1, Airport A2
WHERE all_comb_earliest.outbound = A1.code
	AND all_comb_earliest.inbound = A2.code
GROUP BY A1.city, A2.city;

CREATE VIEW include_all_pairs AS
SELECT out_city, in_city, direct, one_con, two_con, earliest
FROM CAN_USA_city_pairs FULL JOIN convert_to_city
	ON CAN_USA_city_pairs.out_city = convert_to_city.outbound
	AND CAN_USA_city_pairs.in_city = convert_to_city.inbound;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3
SELECT out_city AS outbound, in_city AS inbound, coalesce(direct, 0), coalesce(one_con, 0), coalesce(two_con, 0), earliest
FROM include_all_pairs;


