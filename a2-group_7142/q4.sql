-- Q4. Plane Capacity Histogram

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
	airline CHAR(2),
	tail_number CHAR(5),
	very_low INT,
	low INT,
	fair INT,
	normal INT,
	high INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS flight_took_off CASCADE;
DROP VIEW IF EXISTS num_of_bookings_with_NULL CASCADE;
DROP VIEW IF EXISTS num_of_bookings;
DROP VIEW IF EXISTS percentage_seat_sold_for_flights CASCADE;
DROP VIEW IF EXISTS count_very_low CASCADE;
DROP VIEW IF EXISTS count_low CASCADE;
DROP VIEW IF EXISTS count_fair CASCADE;
DROP VIEW IF EXISTS count_normal CASCADE;
DROP VIEW IF EXISTS count_high CASCADE;
DROP VIEW IF EXISTS every_planes CASCADE;
DROP VIEW IF EXISTS join_very_low CASCADE;
DROP VIEW IF EXISTS join_low CASCADE;
DROP VIEW IF EXISTS join_fair CASCADE;
DROP VIEW IF EXISTS join_normal CASCADE;
DROP VIEW IF EXISTS join_high CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW flight_took_off AS
SELECT flight.id, plane
FROM flight, departure
WHERE flight.id=departure.flight_id;

CREATE VIEW num_of_bookings_with_NULL AS
SELECT flight_took_off.id, count(Booking.id) AS sold_num
FROM flight_took_off LEFT JOIN Booking ON flight_took_off.id=Booking.flight_id
GROUP BY flight_took_off.id;

CREATE VIEW num_of_bookings(id, sold_num) AS
SELECT num_of_bookings_with_NULL.id, coalesce(sold_num, 0)
FROM num_of_bookings_with_NULL;

CREATE VIEW percentage_seat_sold_for_flights AS
SELECT flight_took_off.id,
	sold_num*100.0/(plane.capacity_economy+plane.capacity_business+plane.capacity_first) AS sold_percentage,
	Plane.airline,  Plane.tail_number 
FROM flight_took_off, Plane, num_of_bookings
WHERE flight_took_off.plane = Plane.tail_number 
AND flight_took_off.id = num_of_bookings.id;

CREATE VIEW count_very_low AS
SELECT tail_number, count(id) AS very_low
FROM percentage_seat_sold_for_flights
WHERE sold_percentage >= '0' AND sold_percentage < '20'
GROUP BY tail_number;

CREATE VIEW count_low AS
SELECT tail_number, count(id) AS low
FROM percentage_seat_sold_for_flights
WHERE sold_percentage >= '20' AND sold_percentage < '40'
GROUP BY tail_number;

CREATE VIEW count_fair AS
SELECT tail_number, count(id) AS fair
FROM percentage_seat_sold_for_flights
WHERE sold_percentage >= '40' AND sold_percentage < '60'
GROUP BY tail_number;

CREATE VIEW count_normal AS
SELECT tail_number, count(id) AS normal
FROM percentage_seat_sold_for_flights
WHERE sold_percentage >= '60' AND sold_percentage < '80'
GROUP BY tail_number;

CREATE VIEW count_high AS
SELECT tail_number, count(id) AS high
FROM percentage_seat_sold_for_flights
WHERE sold_percentage >= '80'
GROUP BY tail_number;

CREATE VIEW every_planes AS
SELECT tail_number, airline
FROM Plane;

CREATE VIEW join_very_low AS
SELECT airline, every_planes.tail_number, very_low
FROM every_planes Natural LEFT JOIN count_very_low;

CREATE VIEW join_low AS
SELECT airline, join_very_low.tail_number, very_low, low
FROM join_very_low Natural LEFT JOIN count_low;

CREATE VIEW join_fair AS
SELECT airline, join_low.tail_number, very_low, low, fair
FROM join_low Natural LEFT JOIN count_fair;

CREATE VIEW join_normal AS
SELECT airline, join_fair.tail_number, very_low, low, fair, normal
FROM join_fair Natural LEFT JOIN count_normal;

CREATE VIEW join_high AS
SELECT airline, join_normal.tail_number, very_low, low, fair, normal, high
FROM join_normal Natural LEFT JOIN count_high;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4
Select airline, tail_number, coalesce(very_low, 0), coalesce(low, 0), coalesce(fair, 0),
	coalesce(normal, 0), coalesce(high,0)
From join_high;
