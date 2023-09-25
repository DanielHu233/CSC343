-- Q2. Refunds!

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2 (
    airline CHAR(2),
    name VARCHAR(50),
    year CHAR(4),
    seat_class seat_class,
    refund REAL
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS international_flights CASCADE;
DROP VIEW IF EXISTS domestic_flights CASCADE;
DROP VIEW IF EXISTS refund_35 CASCADE;
DROP VIEW IF EXISTS refund_50 CASCADE;
DROP VIEW IF EXISTS refund_35_year CASCADE;
DROP VIEW IF EXISTS refund_50_year CASCADE;
DROP VIEW IF EXISTS refund_35_year_class_price CASCADE;
DROP VIEW IF EXISTS refund_50_year_class_price CASCADE;
DROP VIEW IF EXISTS refund_35_50_year_class_price CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW international_flights AS
SELECT id, s_dep, s_arv
FROM Flight, Airport A1, Airport A2 
WHERE Flight.outbound = A1.code AND Flight.inbound = A2.code AND A1.country <> A2.country;

CREATE VIEW domestic_flights AS
(SELECT id, s_dep, s_arv
FROM Flight)
       EXCEPT
(SELECT *
FROM international_flights);

CREATE VIEW refund_35 AS
(SELECT international_flights.id
FROM international_flights 
	JOIN Departure ON international_flights.id = Departure.flight_id 
	JOIN Arrival ON international_flights.id = Arrival.flight_id
WHERE Departure.datetime >= international_flights.s_dep + '8:00:00' 
	AND Departure.datetime < international_flights.s_dep + '12:00:00'
	AND (Arrival.datetime - international_flights.s_arv)*2 >= (Departure.datetime - international_flights.s_dep))
                       UNION
(SELECT domestic_flights.id
FROM domestic_flights 
	JOIN Departure ON domestic_flights.id = Departure.flight_id 
	JOIN Arrival ON domestic_flights.id = Arrival.flight_id
WHERE Departure.datetime >= domestic_flights.s_dep + '5:00:00'
	AND Departure.datetime < domestic_flights.s_dep + '10:00:00'
	AND (Arrival.datetime - domestic_flights.s_arv)*2 >= (Departure.datetime - domestic_flights.s_dep));

CREATE VIEW refund_50 AS
(SELECT international_flights.id
FROM international_flights 
	JOIN Departure ON international_flights.id = Departure.flight_id 
	JOIN Arrival ON international_flights.id = Arrival.flight_id
WHERE Departure.datetime >= international_flights.s_dep + '12:00:00'
	AND (Arrival.datetime - international_flights.s_arv)*2 >= (Departure.datetime - international_flights.s_dep))
                       UNION
(SELECT domestic_flights.id
FROM domestic_flights 
	JOIN Departure ON domestic_flights.id = Departure.flight_id 
	JOIN Arrival ON domestic_flights.id = Arrival.flight_id
WHERE Departure.datetime >= domestic_flights.s_dep + '10:00:00' 
	AND (Arrival.datetime - domestic_flights.s_arv)*2 >= (Departure.datetime - domestic_flights.s_dep));

CREATE VIEW refund_35_year AS
SELECT id, EXTRACT(YEAR FROM datetime) AS year
FROM refund_35 JOIN Arrival ON id = flight_id;

CREATE VIEW refund_50_year AS
SELECT id, EXTRACT(YEAR FROM datetime) AS year
FROM refund_50 JOIN Arrival ON id = flight_id;

CREATE VIEW refund_35_year_class_price AS
SELECT refund_35_year.id, refund_35_year.year, Booking.seat_class, Booking.price*0.35 as Refund
FROM refund_35_year JOIN Booking ON refund_35_year.id = Booking.flight_id;

CREATE VIEW refund_50_year_class_price AS
SELECT refund_50_year.id, refund_50_year.year, Booking.seat_class, Booking.price*0.5 as Refund
FROM refund_50_year JOIN Booking ON refund_50_year.id = Booking.flight_id;

CREATE VIEW refund_35_50_year_class_price AS
(SELECT *
FROM refund_35_year_class_price)
          UNION
(SELECT *
FROM refund_50_year_class_price);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2
SELECT airline, name, year, seat_class, sum(Refund)
FROM refund_35_50_year_class_price 
	JOIN Flight ON refund_35_50_year_class_price.id=Flight.id
	JOIN Airline ON Flight.airline=Airline.code
GROUP BY airline, name, year, seat_class;
